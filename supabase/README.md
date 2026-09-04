# Supabase backend for Aperture

Aperture uses hosted Supabase **Auth only**, for email/password accounts. There is
no database schema, Data API usage, Storage, Edge Functions or Realtime. Favorites
stay in local storage (assignment requirement) and will later be namespaced by
the Supabase user id.

## Project

| Item | Value |
| --- | --- |
| Project name | Aperture |
| Project ref | `ezbczxhwznbyxjnsxsvv` |
| Region | ap-northeast-2 (Seoul) |
| Dashboard | https://supabase.com/dashboard/project/ezbczxhwznbyxjnsxsvv |
| `SUPABASE_URL` | `https://ezbczxhwznbyxjnsxsvv.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | the **default publishable key** (`sb_publishable_…`), Dashboard → Project Settings → API Keys |

The Flutter app must only ever receive the publishable key. Never use the
`service_role`, `sb_secret_…` or legacy `anon` JWT keys in the app.

## Client configuration

Values are supplied at build time, exactly like `PIXABAY_API_KEY`:

```sh
flutter run --dart-define-from-file=env.json
# or
flutter run \
  --dart-define=PIXABAY_API_KEY=... \
  --dart-define=SUPABASE_URL=https://ezbczxhwznbyxjnsxsvv.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

`env.example.json` lists the keys; `env.json` is gitignored.

## Auth configuration (source of truth: `config.toml`)

| Setting | Value | Why |
| --- | --- | --- |
| Providers | email/password only | No OAuth, phone, anonymous, magic-link-only, MFA, passkeys or SSO |
| Sign-up | enabled | |
| Email confirmation | **disabled** | Sign-up returns a session immediately; reviewers never need an inbox. Hosted Supabase without custom SMTP can only email org members anyway. |
| Minimum password length | **8 characters**, no character-class rules | Reasonable without being annoying; the UI must say "at least 8 characters" |
| Access token lifetime | 3600 s, refresh-token rotation on | `supabase_flutter` refreshes automatically |
| Site URL | `http://localhost:3000` (placeholder) | Required field; unused because no email-link flows exist. No deep links are needed. |
| MFA TOTP | disabled (was on by default for new projects) | Out of scope |

Apply edits to `config.toml` with:

```sh
supabase config push --project-ref ezbczxhwznbyxjnsxsvv
```

(Requires `supabase login`. No Docker or local stack is needed.)

## What the Flutter Auth slice can rely on

- `signUp(email, password)` returns a `Session` and a confirmed `User` at once.
- `signInWithPassword` returns the same; wrong credentials yield
  `AuthApiException` with code `invalid_credentials` (HTTP 400).
- Passwords under 8 characters yield code `weak_password` (HTTP 422) with the
  message "Password should be at least 8 characters."
- `User.id` is a stable UUID; `User.email` is set; `appMetadata.provider` is
  `email`. Use `User.id` to namespace local favorites (`favorites_<userId>`).
- Sessions persist and restore on launch through `supabase_flutter`'s default
  local storage; `signOut()` revokes the session (HTTP 204).

## Test account

A development account exists: **aperture.test@example.com**. Its password, the
database password and the project ref are kept outside the repo in
`~/.claude/aperture-supabase.local` (owner-only). Sign-up in the app works
without it.

## Later, if email flows are ever enabled

Password reset or confirmation links would require custom SMTP and a deep-link
redirect (e.g. `io.supabase.aperture://login-callback`) added to
`additional_redirect_urls` plus Android/iOS URL-scheme setup. None of that is
configured or needed today.
