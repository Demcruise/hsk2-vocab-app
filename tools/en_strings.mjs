// English UI string pass for index.html — ordered exact replacements,
// applied line-by-line so giant data const lines are skipped.
import fs from 'fs';
const f = 'index.html';
let lines = fs.readFileSync(f, 'utf8').split('\n');
const SKIP = /^\s*(const\s+)?(VOCAB_DATA|HSK1_VOCAB_DATA|RADICALS_DATA|HANZI_DATA|WORD_TOPIC|HSK1_WORD_TOPIC|KNOWN_DEFAULT|UNIT_COLOR|UNIT_ICONS|NODE_WAVE|Q_MIX)\s*=/;

// [old, new] — longest/most-specific first within each group.
const R = [
// meta / head
['content="Belajar kosakata HSK 1 (300 kata) & HSK 2 (770 kata) HSK 3.0: 10 kalimat contoh per kata, audio normal & lambat."','content="Learn HSK 1 (300 words) & HSK 2 (770 words) vocabulary, HSK 3.0: 10 example sentences per word, normal & slow audio."'],
// nav / tabs
['>Belajar<span class="nav-arrow">›</span>','>Learn<span class="nav-arrow">›</span>'],
['>Hafal<span class="nav-arrow">›</span>','>Memorized<span class="nav-arrow">›</span>'],
['>Radikal<span class="nav-arrow">›</span>','>Radicals<span class="nav-arrow">›</span>'],
['>Progres<span class="nav-arrow">›</span>','>Progress<span class="nav-arrow">›</span>'],
['<span class="nav-icon">🏠</span>Belajar','<span class="nav-icon">🏠</span>Learn'],
['<span class="nav-icon">✅</span>Hafal','<span class="nav-icon">✅</span>Memorized'],
['<span class="nav-icon">🀄</span>Radikal','<span class="nav-icon">🀄</span>Radicals'],
['<span class="nav-icon">📊</span>Progres','<span class="nav-icon">📊</span>Progress'],
['MODE GELAP','DARK MODE'],
// learn screen
['🚫 Belum Hafal','🚫 Not Memorized'],
['data-mode="new"','data-mode="new"'],
['✨ Baru','✨ New'],
['📝 Belajar</button>','📝 Learning</button>'],
['🔄 Review','🔄 Review'],
['⭐ Dikuasai','⭐ Mastered'],
['▶ Mulai Latihan Bebas','▶ Start Free Practice'],
['Belum hafal','Not memorized'],
['Sudah hafal','Memorized'],
['🔍 Cari hanzi / pinyin / arti...','🔍 Search hanzi / pinyin / meaning...'],
['🔍 Cari radikal / pinyin / arti...','🔍 Search radical / pinyin / meaning...'],
// exercise / quiz
['id="exPrompt">Terjemahkan kalimat ini','id="exPrompt">Translate this sentence'],
['title="Dengarkan"','title="Listen"'],
['>PERIKSA<','>CHECK<'],
['>LANJUT<','>CONTINUE<'],
['>ULANG QUIZ<','>RETRY QUIZ<'],
['📝 Review yang Salah','📝 Review Mistakes'],
['alt="Selesai"','alt="Done"'],
['id="qdTitle">Latihan selesai!','id="qdTitle">Practice complete!'],
['KATA BARU','NEW WORD'],
['LATIHAN SULIT','HARD EXERCISE'],
["'Keren!','Awesome!','Bagus sekali!','Mantap!'","'Nice!','Awesome!','Great job!','Perfect!'"],
["'Jawaban benar: '","'Correct answer: '"],
["'Dengarkan & susun terjemahannya'","'Listen & arrange the translation'"],
["'Terjemahkan kalimat ini'","'Translate this sentence'"],
["'Ucapkan kalimat ini'","'Say this sentence'"],
["'Tulis karakter ini'","'Write this character'"],
["'Tap 🎤 lalu ucapkan'","'Tap 🎤 and speak'"],
["'Mendengarkan… ucapkan sekarang'","'Listening… say it now'"],
["'Kamu bilang: '","'You said: '"],
["'Tidak terdengar — coba lagi'","'Didn\u2019t catch that — try again'"],
["'Mic/ASR tidak didukung — dengarkan contoh, ucapkan, lalu nilai sendiri'","'Mic/ASR not supported — listen to the example, speak, then rate yourself'"],
["'Tap 🎤 untuk merekam & membandingkan (opsional)'","'Tap 🎤 to record & compare (optional)'"],
["'Merekam… tap 🎤 lagi untuk berhenti'","'Recording… tap 🎤 again to stop'"],
["'✅ Benar'","'✅ Correct'"],
["'❌ Belum'","'❌ Not yet'"],
["'Lewati ›'","'Skip ›'"],
["'Gores sesuai urutan yang benar'","'Trace the strokes in order'"],
["'💡 Petunjuk'","'💡 Hint'"],
["'Data goresan tidak ada — jawab di hati lalu lanjut'","'No stroke data — answer in your head, then continue'"],
["'Coba lagi…'","'Try again…'"],
["'Luar biasa! Kamu hampir sempurna.'","'Outstanding! Almost perfect.'"],
["'Bagus! Terus pertahankan.'","'Great! Keep it up.'"],
["'Lumayan, latihan lagi ya.'","'Not bad — keep practicing.'"],
["'Ayo belajar lagi, kamu pasti bisa.'","'Practice more — you can do it.'"],
["'Latihan selesai!'","'Practice complete!'"],
["'Jangan menyerah!'","'Don\u2019t give up!'"],
["'Tidak ada salah!'","'No mistakes!'"],
["'Belum ada kata untuk latihan ini'","'No words for this practice yet'"],
// progress / hub / save
['🔥 Streak Belajar','🔥 Study Streak'],
['💪 Latihan Skill','💪 Skill Practice'],
['📚 Koleksi Cerita','📚 Story Collection'],
['🏆 Pencapaian','🏆 Achievements'],
['💾 Simpan Progres','💾 Save Progress'],
['Belum ada data.','No data yet.'],
['Progres tersimpan <b>otomatis</b> di browser ini setiap kali kamu menilai kartu atau kuis. Untuk cadangan atau pindah perangkat, gunakan tombol di bawah.','Progress is saved <b>automatically</b> in this browser every time you rate a card or finish a quiz. Use the buttons below to back up or move devices.'],
['💾 Simpan Progres ke File','💾 Save Progress to File'],
['📥 Muat Progres dari File','📥 Load Progress from File'],
['📋 Salin Backup (teks)','📋 Copy Backup (text)'],
['🔄 Reset Semua Progress','🔄 Reset All Progress'],
['Setelah pembaruan, kalau tampilan aplikasi terasa belum berubah, ketuk tombol di bawah lalu buka ulang aplikasi.','After an update, if the app looks unchanged, tap the button below and reopen it.'],
['Cadangkan progresmu','Back up your progress'],
['Simpan file progres biar aman pindah perangkat.','Save a progress file so it\u2019s safe to move devices.'],
['Simpan ke File','Save to File'],
['Versi aplikasi: ','App version: '],
["'Yakin reset semua progress?'","'Reset all progress?'"],
["'Progres disimpan!'","'Progress saved!'"],
["'Gagal menyimpan file'","'Failed to save file'"],
["'Progres dimuat!'","'Progress loaded!'"],
["'File tidak valid'","'Invalid file'"],
["'File tidak bisa dibaca'","'Couldn\u2019t read file'"],
["'Gagal membaca file'","'Failed to read file'"],
["'Backup disalin!'","'Backup copied!'"],
["'Gagal menyalin'","'Copy failed'"],
["'Tekan Ctrl+C untuk menyalin'","'Press Ctrl+C to copy'"],
["'Memeriksa pembaruan...'","'Checking for updates...'"],
["' — ganti level dulu'","' — switch levels first'"],
["'File ini untuk '","'This file is for '"],
// hub tiles
["n:'Kesalahan'","n:'Mistakes'"],
["n:'Dengar'","n:'Listening'"],
["n:'Bicara'","n:'Speaking'"],
["n:'Menulis'","n:'Writing'"],
["' kata'","' words'"],
["' salah'","' missed'"],
["'Tidak ada kesalahan 🎉'","'No mistakes 🎉'"],
["'Data goresan belum dimuat'","'Stroke data not loaded yet'"],
["'Cerita belum tersedia.'","'No stories yet.'"],
["'Cerita untuk topik ini belum ada'","'No story for this topic yet'"],
// stories / session
["'Tutup'","'Close'"],
["'Tidak ada kartu'","'No cards'"],
["'Memuat...'","'Loading...'"],
["'Beralih ke '+L.label+' • '+vocab.length+' kata'","'Switched to '+L.label+' • '+vocab.length+' words'"],
// session UI
['id="sessLabel">Latihan','id="sessLabel">Practice'],
['🔊 Baca','🔊 Read'],
['👆 Tap kartu untuk balik','👆 Tap the card to flip'],
['🎤 Latih Ucap','🎤 Speak'],
['✍️ Latih Tulis','✍️ Write'],
['😰 Sulit','😰 Hard'],
['👍 Baik','👍 Good'],
['⭐ Mudah','⭐ Easy'],
['✅ Hafal','✅ Know it'],
['◀ Sebelum','◀ Prev'],
['Berikut ▶','Next ▶'],
['🐢 Lambat','🐢 Slow'],
["'Contoh Kalimat <span style=\"font-size:11px\">(🔊 untuk dengar)</span>:'","'Example Sentences <span style=\"font-size:11px\">(🔊 to listen)</span>:'"],
["'Radical: '+mr.radical+' ('+mr.pinyin+') - '+mr.meaning","'Radical: '+mr.radical+' ('+mr.pinyin+') - '+mr.meaning"],
["'Radikal: '+mr.radical+' ('+mr.pinyin+') - '+mr.meaning","'Radical: '+mr.radical+' ('+mr.pinyin+') - '+mr.meaning"],
// vocab/known screens
["'↩️ Batalkan'","'↩️ Undo'"],
["'\\u2705 Hafal'","'\\u2705 Know it'"],
["' kata ditampilkan • '","' words shown • '"],
["' grup'","' groups'"],
["' (pencarian)'","' (search)'"],
["' kata</span>'","' words</span>'"],
["+' kata'","+' words'"],
["' ditandai hafal'","' marked as known'"],
["' kata ditandai hafal'","' words marked as known'"],
// node sheet
["'✅ Tandai Semua Hafal'","'✅ Mark All Known'"],
["' hafal • '","' known • '"],
// writing overlay
["'Latihan Menulis'","'Writing Practice'"],
["' goresan'","' strokes'"],
["' goresan meleset'","' strokes missed'"],
["'Giliranmu — ikuti urutan goresan'","'Your turn — follow the stroke order'"],
["'Selesai — '","'Done — '"],
["'karakter '","'character '"],
["'Tidak ada data goresan'","'No stroke data'"],
["'▶ Tonton urutan'","'▶ Watch the order'"],
// speak overlay
["'Tap 🎤 lalu ucapkan kata / kalimat'","'Tap 🎤 and say the word / sentence'"],
["'Mantap! Pengucapanmu cocok ✅'","'Nice! Your pronunciation matches ✅'"],
["'Belum cocok — dengar contoh & coba lagi'","'Not matching — hear the example & try again'"],
["'ASR tidak didukung — dengar contoh, ucapkan, nilai sendiri'","'ASR not supported — hear the example, speak, rate yourself'"],
["'Bagus! Tandai benar ✅'","'Nice! Marked correct ✅'"],
["'Terus berlatih 💪'","'Keep practicing 💪'"],
["'Mendengarkan…'","'Listening…'"],
["'Kamu bilang: '+heard","'You said: '+heard"],
// learn path leftover
["'Bagian '","'Section '"],
["' kata</div>'","' words</div>'"],
["' kata • '","' words • '"],
["' — bagian '","' — part '"],
// misc
["'MULAI'","'START'"],
["'Belum ada kata'","'No words yet'"],
["'Langkah Pertama'","'First Steps'"],
["'Pemula'","'Beginner'"],
["'Rajin'","'Diligent'"],
["'Kolektor'","'Collector'"],
["'Quiz Pertama'","'First Quiz'"],
["'Konsisten'","'Consistent'"],
["'7 hari streak'","'7-day streak'"],
["'Jaga streak 7 hari'","'Keep a 7-day streak'"],
["'Kumpulkan 500 XP'","'Collect 500 XP'"],
["'Kuasai 100 kata'","'Master 100 words'"],
["'MISI'","'MISSIONS'"],
["' vocab'","' words'"],
["' quiz'","' quizzes'"],
["'1 vocab'","'1 word'"],
["'10 vocab'","'10 words'"],
["'50 vocab'","'50 words'"],
["'100 vocab'","'100 words'"],
["'1 quiz'","'1 quiz'"],
// hub subtitle / grids
['Cerita interaktif per topik — baca, dengar, dan jawab.','Interactive stories per topic — read, listen, and answer.'],
['Latihan terarah dari kesalahanmu — ','Targeted practice from your mistakes — '],
[' kata ditandai',' words marked'],
['Tap untuk merekam','Tap to record'],
// session footer leftover labels
['>Balik kartu<','>Flip card<'],
// radicals screen
['Radikal yang muncul pada kosakata HSK 1.','A radical appearing in HSK 1 vocabulary.'],
["'Radikal: '","'Radical: '"],
];

let miss = [], hit = 0;
const out = lines.map(l => {
  if (SKIP.test(l)) return l;
  let s = l;
  for (const [a, b] of R) {
    if (s.indexOf(a) >= 0) { s = s.split(a).join(b); hit++; }
  }
  return s;
});
// report which patterns never matched (for cleanup of the map)
for (const [a] of R) {
  let found = out.some(l => l.indexOf(a) >= 0) || lines.some(l => !SKIP.test(l) && l.indexOf(a) >= 0);
  if (!lines.some(l => !SKIP.test(l) && l.indexOf(a) >= 0)) miss.push(a);
}
fs.writeFileSync(f, out.join('\n'));
console.log('applied sites:', hit);
console.log('patterns with no match (stale):', miss.length);
miss.forEach(m => console.log('  ?', m.slice(0, 80)));
