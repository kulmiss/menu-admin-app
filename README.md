# Menu Admin

The Flutter app for restaurant teams (Owner, Manager, Staff) of the Menu platform ([kulmiss/menu](https://github.com/kulmiss/menu)), plus a small Super Admin screen (overview, emergency switches, link to the web console). Android first; iOS builds from the same code.

- Plan and architecture: [PLAN.md](PLAN.md) · Decisions: [QUESTIONS.md](QUESTIONS.md) · Progress: [handover.md](handover.md)
- Design (tokens, components, top tasks, before/after): [docs/redesign.md](docs/redesign.md)
- Run it on your laptop: [docs/laptop.md](docs/laptop.md) · Firebase: [docs/firebase.md](docs/firebase.md) · Release and Play Store: [docs/release.md](docs/release.md)

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<your PC's IP>:8000
flutter test --exclude-tags golden
```

Stack: Riverpod 3, go_router, dio (Bearer token, Idempotency-Key, retries, error mapping), drift (offline-first cache), flutter_secure_storage, Firebase (optional: push, Crashlytics, Analytics), the web admin's shadcn tokens + Inter + Lucide icons, light/dark (phone setting or Settings › Theme), phones and tablets.
