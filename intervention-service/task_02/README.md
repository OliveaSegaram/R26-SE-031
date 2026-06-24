# Task 02 — Early Dyslexia Identification (Grade 1)

Child-friendly adaptive assessment inspired by [AdaptedMind](https://www.adaptedmind.com/): purple/teal game UI, coin rewards, progress path, and **interactive flip flashcards**.

**Pictures:** Color PNG icons in `frontend/assets/pictures/` (Twemoji, offline). You can replace any file with NIE textbook art — keep the same name (e.g. `mother.png`).

## Four task types (each with levels 1–3)

| Task | Sinhala | What the child does |
|------|---------|---------------------|
| **Word match** | වචන හඳුනමු | See a word → pick the matching picture |
| **Picture → word** | ඡායාරූපයෙන් වචනය | See picture → pick the correct Sinhala word |
| **Word build** | වචන හදමු | Tap one letter per box to build the word |
| **Picture ↔ word match** | වචන යුගල කරමු | Tap a Sinhala word, then tap its matching picture |

## Adaptive levels (yes — this is the right approach)

Each of the **4 activities** runs **2 questions** (8 total):

1. වචන → පින්තූර (×2)  
2. පින්තූර → වචනය (×2)  
3. අකුරු ස්නැප් (×2)  
4. වචන යුගල (×2)

**Within each activity (same task kind):**

| Question | Level |
|----------|-------|
| 1st in that activity | **Level 2** (medium) |
| Wrong on level 2 | 2nd question → **Level 1** (easy) |
| Correct on level 2 | 2nd question → **Level 3** (hard) |

Home screen is **Start only** — no separate task picker. Questions flow automatically inside the game.

## Word source

Words come from the **approved Grade 1 list** (31 Sinhala words with Tamil) in `data/grade1_textbook_words.json`.

## Run backend

From `intervention-service/task_02/`:

```bat
run_backend.bat
```

Or:

```bat
python -m uvicorn main:app --reload --port 8000
```

**Phone / tablet on same Wi‑Fi** — backend must listen on all interfaces:

```bat
task_02\run_backend_mobile.bat
```

API prefix: `/api/v1/task02/`

## Run Task 02 UI

### Windows (desktop)

```bat
cd task_02\frontend
flutter pub get
flutter run -d windows
```

### Android

1. Install [Android Studio](https://developer.android.com/studio) + Flutter SDK.
2. Start backend with `task_02\run_backend_mobile.bat`.
3. Find your PC IP: `ipconfig` → IPv4 (e.g. `192.168.1.10`).
4. Connect phone (USB debugging) or start an emulator.

**Real Android phone (same Wi‑Fi):**

```bat
cd task_02\frontend
flutter pub get
flutter run -d android --dart-define=API_BASE=http://192.168.1.10:8000
```

**Android emulator only** (uses `10.0.2.2` automatically):

```bat
flutter run -d android
```

Or use `run_android.bat`.

### iOS (iPhone / iPad)

**Requires a Mac** with Xcode — iOS builds do not run on Windows.

1. On the Mac, clone/copy this project and install Flutter + Xcode.
2. Start backend on your Mac or PC (if PC, use LAN IP):

```bash
cd intervention-service/task_02
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

3. Install CocoaPods (first time only):

```bash
cd task_02/frontend/ios
pod install
cd ..
```

4. **iOS Simulator** (backend on same Mac):

```bash
cd task_02/frontend
flutter pub get
open -a Simulator
flutter run -d ios
```

5. **Real iPhone** (same Wi‑Fi as backend PC/Mac):

```bash
flutter run -d ios --dart-define=API_BASE=http://192.168.1.10:8000
```

6. Or open in Xcode and run:

```bash
open ios/Runner.xcworkspace
```

Then select your iPhone → Run (▶). Add `--dart-define=API_BASE=...` in Xcode: **Product → Scheme → Edit Scheme → Run → Arguments → Dart define**: `API_BASE=http://YOUR_IP:8000`

### Configurable API URL

Default: `http://127.0.0.1:8000` (Windows / iOS Simulator on Mac).

Override:

```bat
flutter run --dart-define=API_BASE=http://192.168.1.10:8000
```

Code: `frontend/lib/config/app_config.dart`

### Audio on mobile

Uses **audioplayers** + backend **gTTS** (`/api/v1/c4/tts`) — sound plays inside the app (no external player).

### Picture assets

```bat
python task_02\scripts\download_pictures.py
```

Maps each word visual to a PNG in `frontend/assets/pictures/` (see `manifest.json`).

## Folder layout

```
task_02/
  data/grade1_textbook_words.json
  backend/adaptive_engine.py
  backend/router.py
  frontend/          ← NEW Flutter UI (not the C4 reading theme)
```
