# HSK 2 Vocabulary App (Kunkwan HSK 2 V3)

Aplikasi belajar kosakata **HSK 2 (HSK 3.0 Level 2)** dalam **satu file HTML** — bisa dibuka langsung dari HP tanpa server, tanpa install.

## Fitur

- **770 kata** HSK 2 dengan hanzi, pinyin (berton), dan arti.
- **3 kalimat contoh per kata** (2.310 kalimat) yang ditulis pada level HSK 2 (hanya kosakata HSK 3.0 Level 1 + Level 2), berisi hanzi + pinyin + terjemahan Indonesia.
- **Audio TTS** untuk kata dan tiap kalimat, dua kecepatan (normal / lambat) memakai `speechSynthesis` bawaan browser.
- **Tooltip per hanzi** — sentuh/hover karakter mana pun di kalimat contoh untuk melihat pinyin, arti, dan radikalnya.
- **149 radikal** dengan penjelasan (Indonesia), daftar karakter, dan kata yang memakainya.
- **Flashcard** dengan mode Belajar / Baru / Diulang / Hafal, penilaian kartu, dan progres.
- **Kuis** (hanzi→arti, arti→hanzi, pinyin→hanzi) + pencapaian (achievement) & XP.
- **Simpan progres otomatis** di browser, plus **Simpan/Muat ke File** (JSON) untuk backup atau pindah perangkat.

## Cara Pakai

1. Unduh `index.html`.
2. Buka dengan browser (Chrome/Safari/Edge) — langsung jalan, bisa offline.
3. Di HP: buka file, lalu "Add to Home Screen" agar seperti aplikasi.

## Struktur

| File | Keterangan |
|---|---|
| `index.html` | Aplikasi lengkap (HTML + CSS + JS + semua data tertanam) |
| `vocab_data.json` | Sumber data: 770 kata + 149 radikal |
| `full_generator.js` | Generator data |
| `generate_sentences.mjs` | Skrip pembantu pembuatan kalimat |
| `HSK2_v3_vocabulary_list_EN.pdf` | Daftar kosakata HSK 2 (EN) |
| `New-HSK-Vocabulary-Level-2.pdf` | Daftar kosakata HSK (level 2) |
| `HSK2-Vocabulary-3.0.pdf` | Rujukan kosakata HSK 3.0 |

## Catatan

- Progres disimpan di `localStorage` browser ini. Kalau membuka file dari path/domain berbeda, gunakan **Simpan/Muat Progres ke File** untuk memindahkan.
- Audio bergantung pada voice Mandarin (`zh-CN`) yang tersedia di perangkat. Jika belum ada, instal paket suara Mandarin di sistem.
