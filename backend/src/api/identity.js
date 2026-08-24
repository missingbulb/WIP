/**
 * Who is calling, and the names things get.
 *
 * Phase B has no accounts (the design defers them to sync): a device holds a
 * token this Worker minted, and that token names the device. Everything a
 * device may touch is keyed by that name, so a stolen token reaches one
 * comedian's shows and never anybody else's.
 */

const encoder = new TextEncoder();

/**
 * Reads the device out of a bearer token, or returns null.
 *
 * The token is `<deviceId>.<signature>`; the signature is HMAC-SHA256 of the
 * device id under the Worker's secret. Nothing is stored server-side, because
 * there is nothing to store — the signature *is* the record that this Worker
 * issued the token.
 */
export async function deviceFromToken(token, secret) {
  if (typeof token !== 'string' || !token.includes('.')) return null;
  const separator = token.lastIndexOf('.');
  const deviceId = token.slice(0, separator);
  const presented = token.slice(separator + 1);
  if (!deviceId || !presented) return null;

  const expected = await sign(deviceId, secret);
  return timingSafeEqual(presented, expected) ? deviceId : null;
}

export async function mintToken(deviceId, secret) {
  return `${deviceId}.${await sign(deviceId, secret)}`;
}

async function sign(deviceId, secret) {
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(deviceId));
  return base64url(new Uint8Array(signature));
}

/** Compares without leaking, through timing, how much of a guess was right. */
function timingSafeEqual(a, b) {
  if (a.length !== b.length) return false;
  let difference = 0;
  for (let i = 0; i < a.length; i++) difference |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return difference === 0;
}

/** An id nobody can guess and nobody can enumerate: 128 bits, as the design asks. */
export function unguessableId() {
  return base64url(crypto.getRandomValues(new Uint8Array(16)));
}

function base64url(bytes) {
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
