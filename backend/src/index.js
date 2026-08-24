/**
 * The Worker: the app's API, and the Workflow that processes a show once its
 * audio has landed.
 *
 * Everything here is adapter — turning bindings into the ports the API and the
 * pipeline are written against. The rules those two follow live in their own
 * modules, where they can be run without a Cloudflare account.
 */

import { WorkflowEntrypoint } from 'cloudflare:workers';
import { AwsClient } from 'aws4fetch';

import { route } from './api/router.js';
import { d1Store } from './api/store.js';
import { unguessableId } from './api/identity.js';
import { processShow } from './pipeline/process-show.js';

const UPLOAD_WINDOW_SECONDS = 3600;

export default {
  async fetch(request, env) {
    return route(request, {
      store: d1Store(env.DB),
      uploads: r2Uploads(env),
      workflow: {
        start: (params) => env.PROCESS_SHOW.create({ params }),
      },
      secret: env.API_TOKEN_SECRET,
      maxShowBytes: Number(env.MAX_SHOW_BYTES),
      now: () => new Date().toISOString(),
      newId: unguessableId,
    });
  },
};

export class ProcessShow extends WorkflowEntrypoint {
  async run(event, step) {
    const { showId, audioKey } = event.payload;
    try {
      return await processShow(
        { showId, audioKey },
        {
          audio: audioPort(this.env),
          ai: aiPort(this.env),
          store: artifactStore(this.env),
          config: {
            chunkSeconds: Number(this.env.TRANSCRIBE_CHUNK_SECONDS),
            overlapSeconds: Number(this.env.TRANSCRIBE_CHUNK_OVERLAP_SECONDS),
          },
          // A Workflow step is the retry and durability boundary; the pipeline
          // decides what the steps are, and this hands it the platform's.
          step: (name, work) => step.do(name, work),
        },
      );
    } catch (failure) {
      await this.env.DB.prepare(
        'UPDATE shows SET status = ?, failure = ?, updated_at = ? WHERE id = ?',
      )
        .bind('failed', String(failure?.message ?? failure), new Date().toISOString(), showId)
        .run();
      throw failure;
    }
  }
}

/**
 * Presigned PUTs, so a show's bytes never pass through a Worker, and object
 * metadata read back afterwards, because a presigned PUT cannot enforce a size.
 */
function r2Uploads(env) {
  const client = new AwsClient({
    accessKeyId: env.R2_ACCESS_KEY_ID,
    secretAccessKey: env.R2_SECRET_ACCESS_KEY,
    service: 's3',
    region: 'auto',
  });
  return {
    async presignPut({ key, contentType }) {
      const target = new URL(`${env.R2_S3_ENDPOINT}/${env.R2_BUCKET}/${key}`);
      target.searchParams.set('X-Amz-Expires', String(UPLOAD_WINDOW_SECONDS));
      const signed = await client.sign(new Request(target, { method: 'PUT' }), {
        aws: { signQuery: true },
      });
      return {
        url: signed.url,
        method: 'PUT',
        headers: { 'content-type': contentType },
        expiresInSeconds: UPLOAD_WINDOW_SECONDS,
      };
    },
    async head(key) {
      const object = await env.AUDIO.head(key);
      return object ? { size: object.size } : null;
    },
  };
}

function audioPort(env) {
  const container = (path, body) =>
    env.FFMPEG.fetch(`https://ffmpeg.invalid${path}`, { method: 'POST', body });

  return {
    // ffmpeg is what knows a show's real duration and where its silences are,
    // and Workers cannot run it — so probing and cutting are the Container's
    // only job.
    async probe(key) {
      const response = await container('/probe', JSON.stringify({ key }));
      return response.json();
    },
    async cut(key, { startSeconds, endSeconds }) {
      const response = await container(
        '/cut',
        JSON.stringify({ key, startSeconds, endSeconds }),
      );
      return response.arrayBuffer();
    },
    async samples(key) {
      const response = await container('/pcm', JSON.stringify({ key }));
      const sampleRate = Number(response.headers.get('x-sample-rate'));
      const bytes = await response.arrayBuffer();
      return { samples: new Float64Array(bytes), sampleRate };
    },
  };
}

function aiPort(env) {
  return {
    async transcribe(audio) {
      const result = await env.AI.run('@cf/openai/whisper-large-v3-turbo', {
        audio: [...new Uint8Array(audio)],
      });
      return {
        words: (result.words ?? []).map((word) => ({
          word: word.word,
          start: word.start,
          end: word.end,
        })),
      };
    },
    async similarityMinima(segments) {
      if (segments.length < 2) return [];
      const { data } = await env.AI.run('@cf/baai/bge-base-en-v1.5', {
        text: segments.map((segment) => segment.text),
      });
      const minima = [];
      for (let i = 1; i < data.length; i++) {
        // A neighbour pair that is barely about the same thing is a bit
        // boundary the room did not mark with a laugh.
        if (cosine(data[i - 1], data[i]) < 0.5) minima.push(segments[i].startSeconds);
      }
      return minima;
    },
    async nameSegments(segments) {
      const named = [];
      for (const segment of segments) {
        const { response } = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
          messages: [
            {
              role: 'system',
              content:
                'Name this stand-up bit in at most five words. Reply with the name alone.',
            },
            { role: 'user', content: segment.text.slice(0, 4000) },
          ],
        });
        named.push(response?.trim() || null);
      }
      return named;
    },
  };
}

function cosine(a, b) {
  let dot = 0;
  let left = 0;
  let right = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    left += a[i] * a[i];
    right += b[i] * b[i];
  }
  return dot / (Math.sqrt(left) * Math.sqrt(right) || 1);
}

function artifactStore(env) {
  return {
    putArtifact: (key, body) =>
      env.AUDIO.put(key, JSON.stringify(body), {
        httpMetadata: { contentType: 'application/json' },
      }),

    async saveResults(showId, { durationSeconds, segments, laughEvents }) {
      const statements = [
        env.DB.prepare(
          'UPDATE shows SET status = ?, duration_seconds = ?, updated_at = ? WHERE id = ?',
        ).bind('ready', durationSeconds, new Date().toISOString(), showId),
        env.DB.prepare('DELETE FROM segments WHERE show_id = ? AND provenance = ?').bind(
          showId,
          'detected',
        ),
        env.DB.prepare('DELETE FROM laugh_events WHERE show_id = ?').bind(showId),
      ];
      segments.forEach((segment, ordinal) => {
        statements.push(
          env.DB.prepare(
            `INSERT INTO segments (id, show_id, ordinal, start_seconds, end_seconds, title,
               transcript, provenance) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          ).bind(
            unguessableId(),
            showId,
            ordinal,
            segment.startSeconds,
            segment.endSeconds,
            segment.title,
            segment.text,
            segment.provenance,
          ),
        );
      });
      for (const event of laughEvents) {
        statements.push(
          env.DB.prepare(
            `INSERT INTO laugh_events (id, show_id, at_seconds, duration_seconds, intensity)
             VALUES (?, ?, ?, ?, ?)`,
          ).bind(unguessableId(), showId, event.at, event.duration, event.intensity),
        );
      }
      await env.DB.batch(statements);
    },
  };
}
