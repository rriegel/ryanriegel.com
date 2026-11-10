# AGENTS.md — ryanriegel.com

Agent-facing project rules. Claude Code, Codex, and Hermes all read this file;
keep it in sync with reality — a stale rule here is worse than no rule.

**Privacy:** this repo must stay free of personal paths, hostnames, and
secrets. Use placeholders (`/path/to/repo`, `$DATABASE_PASSWORD`) and
environment variables. Seed credentials (`admin@example.com` / the seed
password in `db/seeds.rb`) are dev-only placeholders that exist in the repo on
purpose — never replace them with real credentials, and never commit real
secrets alongside them. Runtime media lives under `storage/` (gitignored);
check `git status` before committing anything a feature wrote to disk.

## Stack

- **Backend:** Ruby on Rails 8.1, API-only mode, Ruby 3.3.6 (`.ruby-version`)
- **Frontend:** Astro 7 SSR (node adapter, `output: 'server'`) + React islands
  (Tiptap editor), TypeScript, Vitest + Testing Library
- **Database:** PostgreSQL 16, Docker container on the dev machine, port **5434**
- **Auth:** Devise + devise-jwt, JWT in the `auth_token` cookie
- **Storage:** ActiveStorage Disk service (local); blob URLs served relative
- **CI:** GitHub Actions — 5 jobs: `scan_ruby` (brakeman + bundler-audit),
  `scan_js` (npm audit), `lint` (rubocop), `test` (rspec + undercover),
  `frontend_test` (astro check + vitest + build). Fires on PRs and pushes to
  `main`.

## Environment

- **The agent box has no Ruby** — no `ruby`, no `bundler`. Everything under
  `spec/`, `bin/rails`, `bin/rubocop`, `bin/brakeman`, `bin/bundler-audit` is
  unrunnable agent-side. Backend test runs are the human's, same split as
  strava-trends: hand over targeted commands
  (`bundle exec rspec spec/requests/api/posts_spec.rb -e "..."`), agent-side
  runs only on explicit request and only on the dev machine.
- No Docker on the agent box either. The dev DB (`ryanriegel-com-db`, port
  5434) is only reachable over TCP while its container is up on the dev
  machine — connection refused means `make db` hasn't been run, not a code
  bug.
- **Frontend gates run freely agent-side** (Node 22 available, matches CI):
  `npm test` (vitest), `npm run check` (astro check), `npm run build` in
  `frontend/`. All three verified green agent-side.
- `test/` is untouched Rails scaffold — dead. **RSpec in `spec/` is the only
  real backend suite.** Don't add tests there.
- First-time test DB: `RAILS_ENV=test bin/rails db:create db:migrate` (dev
  machine only). CI uses port 5432 via service container; local dev is 5434.
  Never change `config/database.yml` ports to "fix" connectivity.

## Testing

- TDD per the README workflow: failing spec first, then implementation.
- CI's `test` job runs `undercover --compare origin/main` and fails when
  changed code lacks coverage — new controllers/models need specs, not just
  green existing ones.
- Request specs cover draft-visibility semantics; if you touch auth
  before-actions or scopes on `Post`, extend
  `spec/requests/api/posts_spec.rb` rather than working around it.
- Seeds are idempotent (`find_or_create_by!`). `bin/rails db:seed:reseed`
  for a clean slate, `db:seed:destroy` to remove seeded rows without dropping
  the DB. Seed media goes in `db/seeds/media/` and is skipped gracefully when
  absent.

## Workflow

- Specs written and approved before branching; feature branches only, merge
  via PR. No direct pushes to `main`.
- Bug reports mix observed + desired behavior in one sentence — confirm which
  clause is bug vs spec before coding.
- Update `README.md` when setup, ports, seeds, or workflow change — it is the
  fresh-clone developer's entry point. Verify steps actually work.

## API / backend conventions

- **Auth ordering is load-bearing:** `authenticate_user!` (or
  `optional_authenticate_user!`) MUST run before any action that scopes by
  `current_user`. In `PostsController`, draft visibility depends on auth
  having run before `set_post_for_show` — preserve the order.
- **Drafts are invisible, not forbidden:** anonymous requests get 404 for
  drafts (no existence leak); the public index is always published-only;
  `include_body=true` on list responses is opt-in (RSS) and public feed
  requests never carry a session, so draft bodies can't leak.
- **Optimistic locking (`lock_version`):** the update action's staleness
  check is strictly-behind (`posted_lock < db_version` → 409), deliberately
  not `!=`, and runs before the cover attach. Attaching is non-touching
  (`touch_attachment_records = false` in `application.rb`) so it can't bump
  `lock_version` out from under the save. Preserve all three properties in
  any refactor.
- **`cover_image_signed_id` and `cover_image` are NOT Post attributes** —
  permitting them in `post_params` raises `ActiveModel::UnknownAttributeError`
  (500). They're read from raw params by `attach_cover_image_from_signed_id`,
  which swallows `InvalidSignature`/`RecordNotFound` (post saves without a
  cover). Keep that failure mode soft.
- **`sanitize_body`:** the `attributes:` option is a FLAT list applied to all
  tags — a per-tag hash is silently ignored (past bug: stripped every img
  src). URL-scheme safety comes from rails-html-sanitizer's default URI
  filter, not from stripping attributes.
- **Blob URLs stay relative** (`rails_blob_path`, `only_path: true`) except in
  production with `ASSET_HOST` set. Relative paths ride the Astro same-origin
  proxy and work under SSR regardless of Host header. Don't "fix" them to
  absolute.
- Body media: `<img>`, `<video>`, `<audio>`, `<iframe>` are allowed by the
  sanitizer — the blog's model is cover image + rich inline HTML, not a
  structured media library.
- `max_request_size` is 1MB; cover images upload via ActiveStorage direct
  upload (browser → storage PUT), then `POST /api/v1/uploads/create_blob`
  exchanges the blob reference for a signed_id.

## Frontend conventions

- **Astro dev proxy must NOT set `changeOrigin`** on `/api` or
  `/rails/active_storage` — Rails has to see the browser's Host header so
  direct-upload PUT targets and blob preview URLs point back at the origin
  the browser is using. The proxy also strips the `domain=` attribute from
  Rails' `Set-Cookie` so the JWT cookie works on localhost. Preserve both.
- **RSS (`frontend/src/pages/rss.xml.astro`):** full-content CDATA
  descriptions + `<enclosure>` for cover images (needs absolute URL, blob
  content_type, byte_size). All `src`/`href` in item HTML get absolutized
  against `SITE_URL` — relative blob paths break in feed readers. New feed
  fields must keep that absolutization.
- Admin pages are SSR-guarded via `src/lib/admin-auth.ts` (cookie check +
  server-side token validation); on API-unreachable the token is assumed
  valid and errors surface client-side. Don't switch admin routes to
  client-only auth.
- API base comes from `API_URL` env (`frontend/.env`, see
  `.env.example`); `SITE_URL` drives absolute URLs (RSS, canonical links).
- Editor components (`PostEditor`, `MediaUploader`, `TagInput`) are React
  islands — their tests run in vitest/jsdom; keep lib modules (`post-form`,
  `taxonomy`, `utils`) pure and unit-tested, UI thin.

## Debugging discipline

- Verified diagnostics beat assumption: DB probe → API probe → real browser
  with screenshot before concluding anything is broken.
- Proxy/auth issues: check the `[PROXY]` logs from `astro.config.mjs` (status
  + Set-Cookie headers) before suspecting Devise.
- 401s on localhost usually mean the cookie's `domain=` attribute survived
  the proxy rewrite, or the Vite proxy gained a `changeOrigin` it must not
  have.
