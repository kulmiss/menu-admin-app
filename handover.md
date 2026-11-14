# Handover — Menu Admin app

_Last updated: 2026-11-14 (Step 1+2 done; Step 3 in progress)._

> **Working mode (owner, 2026-11-14):** work non-stop through Steps 1–5; recommended option for every question, recorded in QUESTIONS.md. Stop only for deleting the owner's files, paid services, irreversible security choices, or a real blocker. Small PRs into `develop` (never `main`), tests in every PR, CI green.

## Links
- Design preview (phone-friendly canvas, 9 artboards incl. icon concepts): https://claude.ai/artifact/TsJJLddM7a56sJn9FoKprK
- Plan: PLAN.md · Decisions: QUESTIONS.md · Step 1: docs/step1-safety-check.md

## Repos and branches
- `kulmiss/menu-admin-app`: `main` = bootstrap commit only; `develop` = integration branch. (Note: the first push accidentally put the plan files on `main`; Claude replaced it within minutes with a bootstrap-only commit — nothing else was ever on the repo.)
- `kulmiss/menu`: backend PRs for the app are branches `feat/mobile-*`.

## PRs (merge in order)
| Repo | PR | What |
|---|---|---|
| app | A0 | Plan, decisions, Step 1 check, icon concepts |

## Claude's workspace notes
- Flutter 3.47.9 in `/opt/sdk/flutter` (`export PATH=/opt/sdk/flutter/bin:$PATH`), Android SDK in `/opt/sdk/android` (platform 36, build-tools 36).
- Backend: `composer install --prefer-source` needs phpstan/larastan removed from a local copy of the lock (dist-only package, GitHub API blocked); MariaDB `service mariadb start`, user `menu`/`menu`, `.env` local only. Full Pest: 450 tests, ~4 min.
