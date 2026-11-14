# Questions and decisions — Menu Admin app

The owner asked (2026-11-14 23:47 EAT) to work non-stop: Claude picks the recommended option for every question and records it here. **Every item is changeable**; reply with the number to change one.
Backend decisions for this app are also listed in `kulmiss/menu` QUESTIONS.md (#187 onwards) with a pointer here.

## Decided at Step 1/2 (Claude, 2026-11-14)

| # | Question | Decision (recommended) | Why |
|---|---|---|---|
| M1 | Flutter version | **3.47.9 stable** pinned (`.flutter-version`, CI) | Matches the laptop (3.47); 3.50.0 is 2 days old. Upgrade later in one PR. |
| M2 | Local cache | **drift (SQLite)**, one `cache_entries` table (key, json, etag, fetched_at, user/tenant scope) + typed repositories on top | Reactive streams for stale-while-revalidate, SQL for search/filter of All dishes offline, mature, MIT. hive_ce has no queries. |
| M3 | State / nav / HTTP / models | Riverpod 3 (no codegen for providers), go_router, dio, freezed + json_serializable | As requested. Provider codegen skipped: fewer build_runner minutes. |
| M4 | Token lifetime | Sanctum token per device, **sliding**: restaurant users expire after **60 days unused**, Super Admins after **14 days unused**; hard max 365 days. No refresh token (using the app keeps it alive). | Simple, revocable, no refresh-token storage. |
| M5 | Super Admin 2FA in the app | Same as web: platform routes need confirmed 2FA; the login asks for the code whenever 2FA is on. Setting up 2FA is possible in the app (QR + secret shown, then confirm). | Mirrors the server rule. |
| M6 | Forgot password | Opens the web page `/auth/forgot-password` in the browser | Fortify's reset flow already works and is CSRF-protected; no new public endpoint. |
| M7 | "Log in as" in the app | **Yes**, with a short-lived owner token (2 h) holding `impersonator_id`; same blocks as web; not recorded (owner decision #170); "Back to platform" revokes it. | Requested; same rules as web. Security note in PR. |
| M8 | Backup downloads | **Web only** (status + "Back up now" + settings view in the app) | Archives hold all customer data; phones get lost. |
| M9 | Base URL | Build-time `--dart-define=API_BASE_URL=…` (default `https://menu.example.com` until the live domain is known); debug builds have a hidden "Server address" field on the sign-in screen (tap the logo 5×) for the laptop (`http://<PC-IP>:8000`). | Domain not decided yet (deploy.md uses menu.example.com). |
| M10 | Deep links | Push payload carries an in-app path (`/r/12/dishes/5`); custom scheme `menuadmin://open/<path>` for links; https App Links **later** (needs `/.well-known/assetlinks.json` with the release key fingerprint). | App Links need the signing key that only the owner has. |
| M11 | FCM sender on the server | FCM **HTTP v1** with a service-account JSON at a path in `.env` (`FCM_CREDENTIALS=storage/app/private/firebase.json`), JWT signed with PHP's openssl (no new Composer package); sent from the queue (existing cron `queue:work --stop-when-empty`). | Shared-hosting friendly, no secrets in the database or repo. |
| M12 | Push event switches | Per user, per type, all **on** by default except "platform announcements" (on) and "follow-ups due" (on, daily 08:00 restaurant-agnostic) — every type can be switched off in the app. | Useful by default; easy opt-out. |
| M13 | Notification inbox | Server keeps the last **90 days** (`app_notifications` table), app shows them and marks read. | Works across devices, survives reinstall. |
| M14 | App lock | Off by default; biometric (local_auth) with a 4–6 digit PIN fallback (PBKDF2 hash in secure storage); auto-lock after **5 minutes** in the background (choices 1/5/15/30 min). | Optional as requested. |
| M15 | Analytics | Firebase Analytics **on** by default (anonymous screen + feature events, no user id, no restaurant names); off switch in Settings; Crashlytics on (user id not set). | As requested; the Privacy Policy says so. |
| M16 | Firebase missing | App starts without Firebase (`google-services.json` absent → Gradle skips the plugin; Dart `Firebase.initializeApp` is guarded); push/analytics/crash show "not set up". | Owner configures Firebase later. |
| M17 | Photo picking | `image_picker` (Android Photo Picker, no storage permission) + `image_cropper` (uCrop) + `flutter_image_compress` (≤ 2048 px, JPEG q85, ≤ 2 MB) | Play photo-permission policy; reuses server pipeline. |
| M18 | PDFs/CSVs | Downloaded with the token to the app cache, then **open** (system viewer via `open_filex`) or **share** (`share_plus`); no in-app PDF engine | Keeps the app under 20 MB/ABI. |
| M19 | Charts | `fl_chart` | MIT, small, smooth. |
| M20 | Live preview | `webview_flutter`: the app fetches `appearance/preview` HTML with the token and loads it with the site as base URL; JavaScript on, navigation limited to that page | The real customer menu, no cookies needed. |
| M21 | Font | **Inter** bundled (same OFL files the web self-hosts, Latin subset) | Matches web admin. |
| M22 | Icon | Concept **B "Menu card + QR corner"** chosen (see PLAN.md §9) | Clearest at 24–48 px, says "menu" and "QR" at once. |
| M23 | Brand colour in the app | Slate neutrals + accent **#0F766E** (teal-700) for the platform; in restaurant mode the restaurant's brand colour is the accent when its contrast is ≥ 4.5:1, else teal | Matches web admin shadcn look; contrast kept. |
| M24 | Tablet layout | ≥ 600 dp: navigation rail; ≥ 840 dp: rail + list/detail two panes; < 600 dp: bottom bar (5 items + "More") | Material 3 window classes. |
| M25 | Offline writes | Refused with a clear banner; sold-out toggle, availability and price edits are optimistic with rollback + snackbar | As requested. |
| M26 | CI for the app | The owner made the repo **public** (2026-11-14), so Actions minutes are free. Still lean: one test job (format, analyze, unit + widget + golden tests) and, on PRs only, one arm64 release APK build that checks the 20 MB budget. Flutter and pub are cached, docs-only changes are skipped, and cancel-in-progress is on. | Fast feedback; catches Gradle/R8 problems early. |
| M27 | Integration tests | `integration_test` flows run with a fake API (`FakeApi` dio adapter) here and in CI as widget-level tests; the same files run on the real phone on the laptop (`flutter test integration_test`) | No emulator in the cloud. |
| M28 | Play Store category / content | Category "Business", content rating "Everyone", no ads, free | Admin tool. |
| M29 | Account deletion (Play) | The app has no sign-up; Settings links to the web "Delete account / contact support" page | Play rule applies to in-app account creation; link still given. |
| M31 | Models | Core models (`/me`, tenants, roles) hand-written in `core/auth/models.dart`; the many admin answers read through a tiny typed accessor (`J`), so no freezed/json_serializable code generation. drift keeps its generated file. | Fewer build steps, the API shape changes without regenerating, a smaller app. Freezed stays an option for later. |
| M32 | PR size for the app | The app arrives in **3 PRs** (plan, app, store assets) rather than ~20, each with commits per area. The screens share one router, one design system and one API layer, so splitting them would have meant temporary stubs. | Each PR still compiles, has tests and passes CI. Reviewing commit by commit gives the same view as small PRs. |
| M33 | Sold out per branch | The Sold-out screen switches the restaurant-wide flag (like the web's dashboard list). Sold out or hidden for one branch is set in Branches › Prices and availability. | Same split as the web admin. |
| M34 | How the 20 MB budget is measured | On the **compressed download** of the arm64 release (the APK gzipped, about what Play sends). The APK file itself is about 24 MB because Android stores native libraries (Flutter engine 11.7 MB, Dart code 8.8 MB, SQLite 1.7 MB) uncompressed for faster installs and less storage. CI prints both numbers. | This is the size users download. Compressing libraries in the APK (`useLegacyPackaging`) would shrink the file but make installs bigger. |
| M30 | Languages | English only, all texts in ARB (`lib/l10n/app_en.arb`), `flutter gen-l10n` | As requested. |

## Owner requests (2026-11-14, later)

| # | Question | Decision | Why |
|---|---|---|---|
| M35 | Feature switches in the app (backend #191/#192) | The app reads `features` in `/me` (plan + restaurant + global switch already combined by the server). New keys (`sold_out`, `share`, `print_materials`) count as **on unless the server says `false`**, so an older server keeps them. "Sold out" off: no Sold out tab (the address shows "turned off"), no dashboard card, no switches in Menu, the dish editor (the field isn't sent), All dishes (filter, bulk) or branch overrides; marks show as available. `print_materials` off hides Print materials; `share`, `pdf_menu`, `order_list` off hide their Appearance switches (like the web). | Same rules as the web admin; the server refuses the calls anyway (402). |

## Open (owner)
- Live domain for `API_BASE_URL` (M9).
- Firebase project, `google-services.json`, FCM service-account JSON on the server (see docs/firebase.md).
- Release keystore + Play Console (see docs/release.md).
