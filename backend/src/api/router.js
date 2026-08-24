/**
 * The app's whole surface: register a show, get somewhere to put the audio,
 * say when it landed, ask how it is going, hand out a link.
 *
 * No audio flows through here. A Worker request body caps well below an hour of
 * a show, so the bytes go straight to R2 under a presigned PUT and this Worker
 * only ever hears about them.
 */

import { deviceFromToken, mintToken, unguessableId } from './identity.js';

const CONTENT_TYPES = new Set(['audio/mp4', 'audio/aac', 'audio/mpeg', 'audio/wav']);

/**
 * @param {Request} request
 * @param {{store, uploads, workflow, secret, maxShowBytes: number, now: () => string, newId: () => string}} deps
 */
export async function route(request, deps) {
  const url = new URL(request.url);
  const path = url.pathname.replace(/\/$/, '');

  if (request.method === 'POST' && path === '/v1/devices') return registerDevice(deps);

  const device = await deviceFromToken(bearer(request), deps.secret);
  if (!device) return problem(401, 'a device token is required');

  if (request.method === 'POST' && path === '/v1/shows') {
    return createShow(request, device, deps);
  }

  const show = path.match(/^\/v1\/shows\/([^/]+)(\/[a-z]+)?$/);
  if (show) {
    const [, id, action] = show;
    const record = await deps.store.readShow(id);
    // A show belonging to another device is not "forbidden", it is not there:
    // an error that distinguishes the two would let anyone enumerate shows.
    if (!record || record.deviceId !== device) return problem(404, 'no such show');

    if (request.method === 'GET' && !action) return readShow(record, deps);
    if (request.method === 'POST' && action === '/uploaded') return completeUpload(record, deps);
    if (request.method === 'POST' && action === '/share') return share(request, record, deps);
  }

  return problem(404, 'no such endpoint');
}

async function registerDevice(deps) {
  // Open registration, deliberately: Phase B has no accounts, and the token's
  // only job is to keep one device's shows to itself. Attestation is what this
  // grows into if the endpoint is ever abused.
  const deviceId = deps.newId();
  return json(201, { deviceId, token: await mintToken(deviceId, deps.secret) });
}

async function createShow(request, device, deps) {
  const body = await readJson(request);
  if (!body) return problem(400, 'a JSON body is required');
  if (!CONTENT_TYPES.has(body.contentType)) {
    return problem(415, `contentType must be one of ${[...CONTENT_TYPES].join(', ')}`);
  }
  if (!(body.byteSize > 0) || body.byteSize > deps.maxShowBytes) {
    return problem(413, `byteSize must be between 1 and ${deps.maxShowBytes} bytes`);
  }

  const id = deps.newId();
  const audioKey = `shows/${device}/${id}`;
  const show = await deps.store.createShow({
    id,
    deviceId: device,
    title: body.title ?? null,
    venue: body.venue ?? null,
    performedAt: body.performedAt ?? null,
    // What the recorder measured, when it knows. The probe step settles it from
    // the audio itself; until then it stays absent rather than becoming a zero.
    durationSeconds: typeof body.durationSeconds === 'number' ? body.durationSeconds : null,
    audioKey,
    byteSize: null,
    contentType: body.contentType,
    status: 'awaiting-upload',
    createdAt: deps.now(),
  });

  const upload = await deps.uploads.presignPut({
    key: audioKey,
    contentType: body.contentType,
  });
  return json(201, { showId: show.id, status: show.status, upload });
}

async function completeUpload(show, deps) {
  const object = await deps.uploads.head(show.audioKey);
  // A presigned PUT cannot enforce a size, so the declared size is a claim
  // until the object is there to measure.
  if (!object) return problem(409, 'the audio has not arrived yet');
  if (object.size > deps.maxShowBytes) {
    return problem(413, 'the uploaded audio is larger than a show may be');
  }

  await deps.store.markUploaded(show.id, {
    byteSize: object.size,
    status: 'processing',
    at: deps.now(),
  });
  await deps.workflow.start({ showId: show.id, audioKey: show.audioKey });
  return json(202, { showId: show.id, status: 'processing' });
}

async function readShow(show, deps) {
  const body = {
    showId: show.id,
    status: show.status,
    title: show.title,
    venue: show.venue,
    durationSeconds: show.durationSeconds,
  };
  if (show.status === 'failed') body.failure = show.failure;
  if (show.status === 'ready') body.segments = await deps.store.readSegments(show.id);
  return json(200, body);
}

async function share(request, show, deps) {
  if (show.status !== 'ready') return problem(409, 'the show is still being processed');
  const body = (await readJson(request)) ?? {};
  const slug = unguessableId();
  await deps.store.createShareLink({
    slug,
    showId: show.id,
    fromSeconds: typeof body.fromSeconds === 'number' ? body.fromSeconds : null,
    toSeconds: typeof body.toSeconds === 'number' ? body.toSeconds : null,
    publicKey: `public/${slug}`,
    createdAt: deps.now(),
  });
  return json(201, { slug });
}

function bearer(request) {
  const header = request.headers.get('authorization') ?? '';
  return header.toLowerCase().startsWith('bearer ') ? header.slice(7).trim() : '';
}

async function readJson(request) {
  try {
    const body = await request.json();
    return body && typeof body === 'object' ? body : null;
  } catch {
    return null;
  }
}

function json(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

function problem(status, detail) {
  return json(status, { error: detail });
}
