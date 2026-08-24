/**
 * The world the API and the pipeline are proved against: an in-memory store,
 * an R2 that remembers what was put in it, and a model that answers whatever
 * the test says it answers.
 *
 * These stand in for bindings, never for the code under test — every rule the
 * tests assert runs in `src/`.
 */

import { mintToken } from '../../src/api/identity.js';

export const SECRET = 'test-secret';

export function memoryStore() {
  const shows = new Map();
  const segments = new Map();
  const shareLinks = [];
  return {
    shows,
    shareLinks,
    setSegments: (showId, list) => segments.set(showId, list),
    async createShow(show) {
      shows.set(show.id, show);
      return show;
    },
    async readShow(id) {
      return shows.get(id) ?? null;
    },
    async markUploaded(id, { byteSize, status }) {
      Object.assign(shows.get(id), { byteSize, status });
    },
    async readSegments(showId) {
      return segments.get(showId) ?? [];
    },
    async createShareLink(link) {
      shareLinks.push(link);
      return link;
    },
  };
}

export function testDeps(overrides = {}) {
  let ids = 0;
  const started = [];
  const objects = new Map();
  return {
    store: memoryStore(),
    uploads: {
      objects,
      presignPut: async ({ key }) => ({ url: `https://r2.invalid/${key}?signed`, method: 'PUT' }),
      head: async (key) => objects.get(key) ?? null,
    },
    workflow: { started, start: async (params) => started.push(params) },
    secret: SECRET,
    maxShowBytes: 1_000_000,
    now: () => '2026-08-24T12:00:00.000Z',
    newId: () => `id-${++ids}`,
    ...overrides,
  };
}

export async function tokenFor(deviceId) {
  return mintToken(deviceId, SECRET);
}

export function post(path, { token, body } = {}) {
  return new Request(`https://api.invalid${path}`, {
    method: 'POST',
    headers: {
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      'content-type': 'application/json',
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

export function get(path, { token } = {}) {
  return new Request(`https://api.invalid${path}`, {
    headers: token ? { authorization: `Bearer ${token}` } : {},
  });
}
