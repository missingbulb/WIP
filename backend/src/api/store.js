/**
 * The D1 half of the API: every statement the Worker runs, in one place.
 *
 * The router talks to this shape, never to a binding, so the routing rules are
 * provable against an in-memory stand-in while the SQL stays reviewable as SQL.
 * What that split cannot prove is that these statements match the schema — only
 * a run against a real D1 does that, which is why the migration and this file
 * are read together in review.
 */
export function d1Store(db) {
  return {
    async createShow(show) {
      await db
        .prepare(
          `INSERT INTO shows (id, device_id, title, venue, performed_at, duration_seconds,
             audio_key, byte_size, content_type, status, created_at, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        )
        .bind(
          show.id,
          show.deviceId,
          show.title ?? null,
          show.venue ?? null,
          show.performedAt ?? null,
          show.durationSeconds ?? null,
          show.audioKey,
          show.byteSize ?? null,
          show.contentType,
          show.status,
          show.createdAt,
          show.createdAt,
        )
        .run();
      return show;
    },

    async readShow(id) {
      const row = await db
        .prepare(
          `SELECT id, device_id, title, venue, performed_at, duration_seconds, audio_key,
                  byte_size, content_type, status, failure
             FROM shows WHERE id = ?`,
        )
        .bind(id)
        .first();
      return row ? fromRow(row) : null;
    },

    async markUploaded(id, { byteSize, status, at }) {
      await db
        .prepare('UPDATE shows SET byte_size = ?, status = ?, updated_at = ? WHERE id = ?')
        .bind(byteSize, status, at, id)
        .run();
    },

    async readSegments(showId) {
      const { results = [] } = await db
        .prepare(
          `SELECT ordinal, start_seconds, end_seconds, title, transcript, provenance
             FROM segments WHERE show_id = ? ORDER BY ordinal`,
        )
        .bind(showId)
        .all();
      return results.map((row) => ({
        ordinal: row.ordinal,
        startSeconds: row.start_seconds,
        endSeconds: row.end_seconds,
        title: row.title,
        transcript: row.transcript,
        provenance: row.provenance,
      }));
    },

    async createShareLink(link) {
      await db
        .prepare(
          `INSERT INTO share_links (slug, show_id, from_seconds, to_seconds, public_key, created_at)
           VALUES (?, ?, ?, ?, ?, ?)`,
        )
        .bind(
          link.slug,
          link.showId,
          link.fromSeconds ?? null,
          link.toSeconds ?? null,
          link.publicKey,
          link.createdAt,
        )
        .run();
      return link;
    },
  };
}

function fromRow(row) {
  return {
    id: row.id,
    deviceId: row.device_id,
    title: row.title,
    venue: row.venue,
    performedAt: row.performed_at,
    durationSeconds: row.duration_seconds,
    audioKey: row.audio_key,
    byteSize: row.byte_size,
    contentType: row.content_type,
    status: row.status,
    failure: row.failure,
  };
}
