import { test } from 'node:test';
import assert from 'node:assert/strict';

import { route } from '../src/api/router.js';
import { testDeps, tokenFor, post, get } from './support/fakes.js';

const A_SHOW = { contentType: 'audio/mp4', byteSize: 60_000, title: 'Tuesday new material' };

async function registeredShow(deps, device = 'device-a', body = A_SHOW) {
  const token = await tokenFor(device);
  const response = await route(post('/v1/shows', { token, body }), deps);
  return { token, created: await response.json(), response };
}

test('a device registers and gets a token that names it', async () => {
  const deps = testDeps();
  const response = await route(post('/v1/devices'), deps);
  assert.equal(response.status, 201);

  const { token, deviceId } = await response.json();
  const shows = await route(post('/v1/shows', { token, body: A_SHOW }), deps);
  assert.equal(shows.status, 201);
  assert.equal(deps.store.shows.get('id-2').deviceId, deviceId);
});

test('no token reaches nothing', async () => {
  const deps = testDeps();
  for (const request of [post('/v1/shows', { body: A_SHOW }), get('/v1/shows/id-1')]) {
    assert.equal((await route(request, deps)).status, 401);
  }
});

test('a forged token reaches nothing', async () => {
  const deps = testDeps();
  const response = await route(post('/v1/shows', { token: 'device-a.forged', body: A_SHOW }), deps);
  assert.equal(response.status, 401);
});

test('registering a show hands back somewhere to put the audio', async () => {
  const deps = testDeps();
  const { created } = await registeredShow(deps);
  assert.equal(created.status, 'awaiting-upload');
  assert.match(created.upload.url, /^https:\/\/r2\.invalid\/shows\/device-a\/id-1\?signed$/);
  assert.equal(created.upload.method, 'PUT');
});

test('a show nobody has measured yet has no duration, rather than a duration of zero', async () => {
  const deps = testDeps();
  const { created } = await registeredShow(deps);
  assert.equal(deps.store.shows.get(created.showId).durationSeconds, null);
});

test('a format the pipeline cannot read is refused before anything is uploaded', async () => {
  const deps = testDeps();
  const { response } = await registeredShow(deps, 'device-a', { ...A_SHOW, contentType: 'video/mp4' });
  assert.equal(response.status, 415);
  assert.equal(deps.store.shows.size, 0);
});

test('a show larger than the ceiling is refused', async () => {
  const deps = testDeps();
  const { response } = await registeredShow(deps, 'device-a', { ...A_SHOW, byteSize: 2_000_000 });
  assert.equal(response.status, 413);
});

test('another device`s show is not there, rather than forbidden', async () => {
  const deps = testDeps();
  const { created } = await registeredShow(deps, 'device-a');
  const response = await route(get(`/v1/shows/${created.showId}`, { token: await tokenFor('device-b') }), deps);
  assert.equal(response.status, 404);
});

test('processing does not start until the audio is actually there', async () => {
  const deps = testDeps();
  const { token, created } = await registeredShow(deps);
  const response = await route(post(`/v1/shows/${created.showId}/uploaded`, { token }), deps);
  assert.equal(response.status, 409);
  assert.deepEqual(deps.workflow.started, []);
});

test('the uploaded size is measured, not believed, and then the pipeline runs', async () => {
  const deps = testDeps();
  const { token, created } = await registeredShow(deps);
  deps.uploads.objects.set('shows/device-a/id-1', { size: 61_234 });

  const response = await route(post(`/v1/shows/${created.showId}/uploaded`, { token }), deps);
  assert.equal(response.status, 202);
  assert.equal(deps.store.shows.get(created.showId).byteSize, 61_234);
  assert.deepEqual(deps.workflow.started, [
    { showId: created.showId, audioKey: 'shows/device-a/id-1' },
  ]);
});

test('an upload past the ceiling is caught after the fact, since a presigned PUT cannot refuse it', async () => {
  const deps = testDeps();
  const { token, created } = await registeredShow(deps);
  deps.uploads.objects.set('shows/device-a/id-1', { size: 5_000_000 });

  const response = await route(post(`/v1/shows/${created.showId}/uploaded`, { token }), deps);
  assert.equal(response.status, 413);
  assert.deepEqual(deps.workflow.started, []);
});

test('a show still processing reports no segments', async () => {
  const deps = testDeps();
  const { token, created } = await registeredShow(deps);
  const body = await (await route(get(`/v1/shows/${created.showId}`, { token }), deps)).json();
  assert.equal(body.status, 'awaiting-upload');
  assert.equal(body.segments, undefined);
});

test('a finished show reports its segments in order', async () => {
  const deps = testDeps();
  const { token, created } = await registeredShow(deps);
  deps.store.shows.get(created.showId).status = 'ready';
  deps.store.setSegments(created.showId, [
    { ordinal: 0, startSeconds: 0, endSeconds: 60, title: 'Airports', provenance: 'detected' },
  ]);

  const body = await (await route(get(`/v1/shows/${created.showId}`, { token }), deps)).json();
  assert.equal(body.segments.length, 1);
  assert.equal(body.segments[0].title, 'Airports');
});

test('a show cannot be shared before it has been cut up', async () => {
  const deps = testDeps();
  const { token, created } = await registeredShow(deps);
  const response = await route(post(`/v1/shows/${created.showId}/share`, { token, body: {} }), deps);
  assert.equal(response.status, 409);
  assert.deepEqual(deps.store.shareLinks, []);
});

test('sharing mints an unguessable slug for the requested slice', async () => {
  const deps = testDeps();
  const { token, created } = await registeredShow(deps);
  deps.store.shows.get(created.showId).status = 'ready';

  const response = await route(
    post(`/v1/shows/${created.showId}/share`, { token, body: { fromSeconds: 600, toSeconds: 1200 } }),
    deps,
  );
  assert.equal(response.status, 201);
  const { slug } = await response.json();
  assert.ok(slug.length >= 20, 'a slug short enough to enumerate is not a slug');
  assert.deepEqual(deps.store.shareLinks[0].fromSeconds, 600);
  assert.equal(deps.store.shareLinks[0].publicKey, `public/${slug}`);
});
