# Handover — Menu Admin app

_Last updated: 2026-11-14 03:00 EAT._

> **Working mode (owner, 2026-11-14):** work non-stop through Steps 1–5. Pick the recommended option for every question and record it in QUESTIONS.md. Stop only for: deleting the owner's files, paid services, irreversible security choices, or a real blocker. Small PRs into `develop` (never `main`), tests in every PR, CI green. The app repo is **public** now, so CI minutes are free.

## Links
- Design preview (canvas, phone-friendly): https://claude.ai/artifact/TsJJLddM7a56sJn9FoKprK
- Plan: PLAN.md · Decisions: QUESTIONS.md (M1–M33) · Step 1: docs/step1-safety-check.md
- Laptop: docs/laptop.md · Firebase: docs/firebase.md · Release/Play: docs/release.md · Store texts: store/listing.md

## PRs — merge in this order
| Repo | PR | Branch | What |
|---|---|---|---|
| menu | #92 | feat/mobile-auth | Token sign-in, 2FA challenge, devices, account endpoints (QUESTIONS #187) |
| menu | #93 | feat/mobile-impersonation | "Log in as" token (#188) — stacked on #92 |
| menu | #94 | feat/mobile-push | Push: FCM v1 sender, switches, inbox, events (#189) — stacked on #93 |
| menu | #95 | feat/mobile-config | `mobile/config` + Privacy Policy lines (#190) — stacked on #94 |
| app | #1 | docs/plan | Plan, decisions, Step 1 check, icon concepts |
| app | #2 | feat/app | The whole app (setup, CI, core, all screens, push, lock, icon/splash, tests) — stacked on #1 |
| app | #3 | feat/store | Store listing, feature graphic, screenshots — stacked on #2 |

Backend after merging: `php artisan migrate --force` (four migrations). Optional: `FCM_CREDENTIALS` (kulmiss/menu docs/deploy.md §10a). New scheduled commands: `mobile:prune-tokens` 03:25, `push:plan-reminders` 09:00, `push:followups` 08:00, `push:health` every 15 min, inbox prune 03:35.

## App structure (lib/)
- `app/`: identity, env (`API_BASE_URL`), theme (`AppTokens` = web shadcn tokens), theme mode, icons (generated Lucide subset, `tool/icons/gen.py`), router (go_router: `/r/:tid/...` restaurant shell, `/p` Super Admin screen, `/account`, `/inbox`), app widget.
- `core/api`: dio client + interceptors (Bearer, Idempotency-Key reused on retry, retries, error mapping → `ApiError`).
- `core/cache`: drift `cache_entries` + `cachedProvider(path)` (stale-while-revalidate).
- `core/auth`: models, permissions (`Can`), token store, auth repository; `core/providers.dart` has the session (sign-in, restaurant switch, "log in as" stash, sign-out).
- `core/platform`: Firebase (optional), push, app lock, in-app update/review.
- `core/widgets`: ui (Button, Badge, Card, Sheet, Toast, SkeletonBox, PageTitle), kit (states, upgrade card, helpers), adaptive shell (bottom bar / rail / two-pane), paged list, images.
- `features/restaurant|platform|account|auth`: screens. `restaurant/quick_edit.dart` = price and hide/show sheets; `platform/super_admin_screen.dart` = the whole Super Admin.

## Redesign 2026-11
PRs #16–#22 (stacked, merge in order): before screenshots, theme tokens, icons + components, Home + nav, quick sheets + Menu, minimal Super Admin, docs + after screenshots. See docs/redesign.md.

## Tests
`flutter test`: 32 tests (API/idempotency/errors, permissions, links, units, 4 flows: login+2FA, sold-out, edit dish, record payment; 8 goldens). `integration_test/app_test.dart` runs the same 4 flows on a phone. Goldens are Linux-only (`--exclude-tags golden` elsewhere).

## Not done / known limits
- Real-device checks (cold start time, 60 fps, size per ABI on a real build) are for the laptop: docs/laptop.md.
- Branch prices screen loads the first 100 dishes (search finds the rest).
- Settings → "Logo and link preview" upload is on the web only for now (all other settings tabs are in the app).
- iOS: bundle ID and Info.plist are set; building needs a Mac.

## Claude's workspace notes
- Flutter 3.47.9 in `/opt/sdk/flutter`, Android SDK in `/opt/sdk/android`. Gradle downloads through the proxy sometimes fail with 429 or a dropped connection; retrying the build works.
- Backend: `composer install --prefer-source`, with phpstan/larastan removed from a local copy of the lock first (that package is dist-only and the GitHub API is blocked). MariaDB: `service mariadb start`, user `menu`/`menu`, `.env` stays local. Full Pest run: 479 tests, about 4 min.
