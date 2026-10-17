# Kunkwan HSK 2 — Kosakata

Aplikasi belajar kosakata **HSK 2 (HSK 3.0 Level 2)** — 770 kata, satu file HTML, bisa dipakai di HP sebagai aplikasi (PWA) atau langsung dibuka dari file.

## Fitur

- **770 kata** HSK 2 dengan hanzi, pinyin (berton), dan arti.
- **10 kalimat contoh per kata** (7.700 kalimat) bertema pemakaian sehari-hari nyata (belanja, transportasi, makan, rumah, kerja, chat, kesehatan, sekolah, rencana, cuaca, sosial/hobi, perasaan, HP/internet, keuangan), berisi hanzi + pinyin + terjemahan Indonesia. Ditulis pada level HSK 2 (mayoritas kosakata HSK 3.0 Level 1–2).
- **Audio TTS** untuk kata dan tiap kalimat, dua kecepatan (normal / lambat) memakai `speechSynthesis` bawaan browser.
- **Tooltip per hanzi** — sentuh/hover karakter mana pun di kalimat contoh untuk melihat pinyin, arti, dan radikalnya.
- **149 radikal** dengan penjelasan (Indonesia), daftar karakter, dan kata yang memakainya.
- **Flashcard** dengan mode Belum Hafal / Belajar / Baru / Review / Dikuasai, penilaian kartu, dan progres.
- **Halaman "Hafal"** — daftar hanzi yang sudah hafal dipisahkan dari yang belum, **dikelompokkan per huruf awal pinyin (A–Z)**. Ada tombol **"sudah hafal"** untuk menandai satu kata, satu kelompok sekaligus, atau semua; plus filter **Belum hafal / Sudah hafal**.
- **Halaman "Vocab"** — daftar semua kata juga **dikelompokkan per huruf awal pinyin (A–Z)**, dengan tombol **✅ Hafal** per kelompok (menandai/atau membatalkan seluruh kelompok sekaligus), filter **Belum hafal / Sudah hafal / Semua**, dan pencarian yang cocok dengan **hanzi, pinyin (berton maupun tanpa tone, mis. `hao`), atau arti**.
- **Kuis tiga arah**: **hanzi + pinyin → arti**, **arti → hanzi + pinyin**, dan **pinyin → hanzi**, plus pencapaian (achievement) & XP.
- **Simpan progres otomatis** di browser (termasuk layar terakhir, mode, dan posisi kartu — saat dibuka lagi langsung kembali ke tempat terakhir), plus **Simpan/Muat ke File** (JSON) untuk backup atau pindah perangkat.
- **Bisa di-install sebagai aplikasi (PWA)** dan **jalan offline** setelah pertama kali dibuka.
- **Pembaruan aplikasi** — halaman **Progres** menampilkan **versi aplikasi** dan tombol **🔄 Perbarui Aplikasi** (memeriksa service worker lalu memuat ulang) supaya versi terbaru langsung terpasang di HP Android.

## Cara Pakai

### Di browser (paling cepat)
Buka `index.html` dengan Chrome/Safari/Edge — langsung jalan, bisa offline, tidak perlu server.

### Install di HP Android (disarankan)
1. Buka **https://demcruise.github.io/hsk2-vocab-app/** di **Chrome Android**.
2. Tunggu sebentar sampai halaman termuat penuh.
3. Ketuk menu **⋮** (kanan atas) → **"Tambahkan ke Layar utama"** / *Add to Home screen*.
4. Konfirmasi → ikon **HSK 2 V3** muncul di layar utama.
5. Buka dari ikon itu: tampil tanpa address bar (mode aplikasi), dan tetap bisa dibuka **tanpa internet**.

> Catatan: fitur install hanya tersedia lewat **https** (GitHub Pages), bukan saat file dibuka dari `file://`. Aplikasi tetap berfungsi normal di `file://`, hanya tanpa tombol install.

## Struktur

| File | Keterangan |
|---|---|
| `index.html` | Aplikasi lengkap (HTML + CSS + JS + semua data tertanam) |
| `vocab_data.json` | Sumber data: 770 kata + 149 radikal |
| `manifest.webmanifest` | Manifest PWA (nama, ikon, warna tema) |
| `sw.js` | Service worker — caching offline |
| `icons/` | Ikon aplikasi (192/512, versi maskable, apple-touch, favicon) |
| `tools/make-icons.mjs` | Generator ikon (Node murni, tanpa dependency) |
| `full_generator.js`, `generate_sentences.mjs` | Generator data |
| `HSK2_v3_vocabulary_list_EN.pdf` | Daftar kosakata HSK 2 (EN) |
| `New-HSK-Vocabulary-Level-2.pdf` | Daftar kosakata HSK (level 2) |
| `HSK2-Vocabulary-3.0.pdf` | Rujukan kosakata HSK 3.0 |

## Catatan

- Progres disimpan di `localStorage` browser. Kalau membuka dari path/domain berbeda (mis. pindah dari `file://` ke GitHub Pages), gunakan **Simpan/Muat Progres ke File** untuk memindahkannya.
- Audio bergantung pada voice Mandarin (`zh-CN`) yang tersedia di perangkat. Jika belum ada, instal paket suara Mandarin di pengaturan sistem.
- Setelah mengubah `index.html`, versi terbaru otomatis terambil saat online (navigasi bersifat *network-first*). Tapi agar versi **offline** juga ikut ter-perbarui, naikkan `VERSION` di `sw.js` (buka lalu tutup sekali dengan koneksi internet). Di HP, ketuk **Progres → 🔄 Perbarui Aplikasi** kalau versi belum berubah.
