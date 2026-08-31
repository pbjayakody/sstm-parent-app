# Smart School Transport Manager — Parent App

A minimal Flutter app for parents to check their child's bus payment
status and history. Talks to `parent_server.py` in the main project
(read-only, no admin access).

## 1. Deploy the backend (free, on Render)

1. Push the **Smart School Transport Manager v3** project (the one
   containing `parent_server.py`, `render.yaml`, and `requirements.txt`)
   to a GitHub repo.
2. Go to https://render.com → New → Web Service → connect that repo.
   Render will read `render.yaml` automatically (free plan, no card
   required). If asked manually:
   - Build command: `pip install -r requirements.txt`
   - Start command: `gunicorn parent_server:app`
3. Once deployed you'll get a URL like
   `https://sstm-parent-api.onrender.com`. Open `<that-url>/healthz` in a
   browser — you should see `{"ok": true, "service": "parent-api"}`.

Note: the free plan sleeps after ~15 minutes idle and takes 30-50s to
wake on the next request — fine for an app parents check occasionally.

**Database**: the SQLite file that ships in the repo is what Render will
use. If you want the *live* school database (not a stale copy), either
(a) redeploy whenever the office data changes, or (b) move to Render's
paid persistent disk / a hosted Postgres later — ask me if you want that
set up.

## 2. Point the app at your backend

Edit `lib/api/parent_api.dart`:
```dart
static const String baseUrl = "https://sstm-parent-api.onrender.com";
```
Replace with your actual Render URL.

## 3. Run / build the Flutter app

You'll need the Flutter SDK installed (https://flutter.dev, `flutter doctor`
to verify). This folder only has the Dart source (`lib/`, `pubspec.yaml`) —
platform folders (`android/`, `ios/`) aren't included, so generate them
first:

```bash
cd parent_app
flutter create --org com.yourschool.parentapp .   # adds android/, ios/, etc. without touching lib/
flutter pub get
flutter run                 # test on a connected device/emulator
flutter build apk           # Android install file (android/app/build/.../app-release.apk)
flutter build ios           # iOS build (requires a Mac + Xcode)
```

Share the built `.apk` file directly with parents (no Play Store needed),
or publish to the Play Store / App Store later if you want a store listing.

## What parents see

1. **Login** — enter the Student ID (e.g. `NB-1234/01`) and the phone
   number on file. The backend checks both together; there is no
   separate password to manage.
2. **Monthly status tab** — every billing month with Paid / Partial /
   Pending status and balance due.
3. **Payment history tab** — every payment recorded, most recent first.

The app never lets a parent edit anything — it's read-only by design,
matching what `controllers/parent_controller.py` exposes on the backend.
