# Kunkwan HSK — Flutter (mobile)

Port native (Flutter/Dart) dari PWA di folder induk. Konten identik: **HSK 1 (300 vocab, 3.000 kalimat)** dan **HSK 2 (770 vocab, 7.700 kalimat, 149 radikal)** — level dipilih via pemilih level dan **progresnya tersimpan terpisah** (`khsk1` / `khsk2`, level terakhir di `khsk-level`). Unit tematis gaya Duolingo, flashcard, latihan terjemah word-bank (toggle 拼音, badge KATA BARU/LATIHAN SULIT, ⚡∞, overlay PERFECT, band benar/salah), streak/XP/achievement, backup JSON per level (format sama dengan versi web), dark mode.

## Struktur

```
lib/
  main.dart            # entry point + tema
  data/
    models.dart        # VocabWord, Sentence, RadicalEntry, Unit, Lesson
    content.dart       # load JSON assets, build unit tematis, pinyin/plain, grup A–Z
    app_state.dart     # ChangeNotifier: progres, streak, XP, known, achievement per level ('khsk1'/'khsk2' — sama dgn web)
    services.dart      # TtsService (flutter_tts zh-CN), SfxService, BackupService
  ui/
    duo.dart           # token warna + DuoButton/DuoCard/DuoBar
    home_shell.dart    # topbar + bottom nav (mobile), sidebar + rail (≥1024px)
    learn_screen.dart  # jalur unit meliuk + node + bubble MULAI
    session_screen.dart# sesi flashcard (flip, kalimat, Sulit/Baik/Mudah)
    quiz_screen.dart   # exercise word-bank gaya Duo + band + confetti
    vocab_screen.dart  # Vocab & Hafal (A–Z, search, tandai)
    radicals_screen.dart
    progress_screen.dart
    widgets.dart       # HanziText + tooltip, confetti, toast
assets/
  data/                # vocab.json (HSK2: 770 + topic), vocab_hsk1.json (HSK1: 300 + topic), radicals.json, hanzi.json
  audio/               # correct.wav, incorrect.wav, finish.mp3
  svg/                 # maskot, bendera, hati, ikon nav
  fonts/Nunito-Var.ttf
```

## Menjalankan

Flutter SDK ada di `C:\src\flutter` (sudah di PATH user). Di terminal baru:

```bash
cd mobile
flutter pub get
flutter run -d chrome      # dev di browser
flutter run -d web-server  # atau: serve build/web setelah build
```

## Build

```bash
flutter build web --release        # → build/web (bisa di-serve statis / hosting)
flutter build apk --release        # → butuh Android SDK (install Android Studio dulu)
flutter build appbundle --release  # untuk Play Store
```

`flutter doctor` saat ini: Chrome ✓, jaringan ✓. **Android Studio belum terinstall** — untuk APK install https://developer.android.com/studio lalu `flutter doctor` lagi.

## Catatan

- TTS Mandarin via `flutter_tts` (suara zh-CN perangkat; di web pakai Web Speech API).
- File backup `.json` kompatibel dengan PWA — Muat file di sini menerima backup dari web dan sebaliknya (per level: `hsk1-...` / `hsk2-...`).
- Data di `assets/data/` dihasilkan dari `index.html` via `tools/_extract_data.py` — jalankan ulang kalau vocab_data.json diperbarui.
