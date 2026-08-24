# The Phase B backend

The Cloudflare side of the product: a show is uploaded here, transcribed, laugh-detected,
cut into bits and handed back as a share link. What it is and why it is shaped this way is
[`dev/design/architecture.md`](../dev/design/architecture.md); this file is how to work on it.

```
npm install
npm test          # node:test, no account and no network
```

Everything with a rule in it — routing, chunk planning, stitching, boundary proposal, the
laugh detector — is plain modules under `src/`, proved against the fakes in `test/support/`.
`src/index.js` is the only file that touches a binding: it turns R2, D1, Workers AI, the
Container and Workflows into the ports the rest is written against.

## What these tests do not prove

- **The SQL.** `src/api/store.js` and `migrations/0001_init.sql` are read together in review;
  only a run against a real D1 shows they agree.
- **Workers AI's behaviour on club audio** — its input ceiling (risk R3), whether chunked
  Whisper timestamps stitch cleanly (D6), whether embedding minima fall where a bit changes.
  Those are what the first real show settles, and the chunk size is a `vars` entry rather than
  a constant for exactly that reason.
- **The presigned PUT.** `aws4fetch` signs it; nothing here checks R2 accepts the signature.

## Deploying

Not yet — no account, no domain (decision D5 is open). When it happens, the secrets are
`API_TOKEN_SECRET`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, and `wrangler.jsonc` needs the
real `database_id`.
