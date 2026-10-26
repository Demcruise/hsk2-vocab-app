// assign_topics.mjs — klasifikasikan 770 kata HSK2 ke unit tematis (gaya Duolingo).
// Pemakaian: node tools/assign_topics.mjs
// Output: menulis field `topic` ke vocab_data.json + tools/_word_topic.js (const WORD_TOPIC inline utk index.html)
//         + tools/_topics_report.txt (daftar per topik utk review manual)

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const data = JSON.parse(fs.readFileSync(path.join(ROOT, 'vocab_data.json'), 'utf8'));

// ---- Unit definitions (urutan = urutan muncul di path belajar) ----
const UNITS = [
  ['dasar',   'Sapaan & Ungkapan Dasar'],
  ['waktu',   'Angka, Waktu & Ukuran'],
  ['orang',   'Orang & Keluarga'],
  ['tubuh',   'Tubuh, Kesehatan & Perasaan'],
  ['makan',   'Makanan & Minuman'],
  ['rumah',   'Rumah & Benda'],
  ['sekolah', 'Sekolah & Kerja'],
  ['jalan',   'Tempat, Arah & Transportasi'],
  ['belanja', 'Belanja & Uang'],
  ['hobi',    'Aktivitas & Hobi'],
  ['alam',    'Alam, Cuaca & Hewan'],
  ['sifat',   'Sifat & Deskripsi'],
  ['umum',    'Kata Kerja & Kata Umum'],
  ['fungsi',  'Kata Fungsi & Tata Bahasa'],
];
const TOPIC_NAMES = Object.fromEntries(UNITS);

// ---- Override manual per id (untuk kata ambigu / polisemi) ----
// Format: id: 'topik'
const HAND = {
  // dasar — sapaan, sopan santun, ungkapan sehari-hari
  1:'dasar',   // 啊 partikel (unggkapan)
  37:'dasar',  // 不好意思
  85:'dasar',  // 答应 reply/agree
  175:'dasar', // 干杯 cheers
  179:'dasar', // 感谢
  239:'dasar', // 欢迎
  258:'dasar', // 加油
  330:'dasar', // 快点儿
  419:'dasar', // 平安 safe and sound
  559:'dasar', // 晚安
  570:'dasar', // 喂
  604:'dasar', // 小心 be careful
  644:'dasar', // 一路顺风
  649:'dasar', // 一路平安
  43:'dasar',  // 不行 no way (ungkapan harian)
  // waktu
  11:'waktu', 38:'waktu', 45:'waktu', 108:'waktu', 121:'waktu', 167:'waktu',
  182:'waktu', 183:'waktu', 217:'waktu', 228:'waktu', 294:'waktu', 324:'waktu',
  388:'waktu', 390:'waktu', 422:'waktu', 435:'waktu', 467:'waktu', 472:'waktu',
  511:'waktu', 578:'waktu', 590:'waktu', 602:'waktu', 642:'waktu', 643:'waktu',
  648:'waktu', 650:'waktu', 652:'waktu', 662:'waktu', 683:'waktu', 696:'waktu',
  705:'waktu', 720:'waktu', 740:'waktu', 741:'waktu', 742:'waktu', 761:'waktu',
  // orang
  3:'orang', 7:'orang', 93:'orang', 96:'orang', 147:'orang', 198:'orang',
  218:'orang', 341:'orang', // 老年 elderly
  238:'orang', 259:'orang', 300:'orang', 325:'orang', 340:'orang', 342:'orang',
  365:'orang', 383:'orang', 439:'orang', 440:'orang', 455:'orang', 463:'orang',
  474:'orang', 492:'orang', 505:'orang', 517:'orang', 545:'orang', 609:'orang',
  622:'orang', 624:'orang', 625:'orang', 693:'orang', 734:'orang', 743:'orang',
  759:'orang', 766:'orang',
  // tubuh — badan, kesehatan, emosi
  17:'tubuh', 39:'tubuh', 127:'tubuh', 163:'tubuh', 176:'tubuh', 177:'tubuh',
  178:'tubuh', 203:'tubuh', 274:'tubuh', 311:'tubuh', 328:'tubuh',
  331:'tubuh', 351:'tubuh', 374:'tubuh', 393:'tubuh', 395:'tubuh', 406:'tubuh',
  431:'tubuh', 457:'tubuh', 480:'tubuh', 499:'tubuh', 523:'tubuh', 547:'tubuh',
  548:'tubuh', 552:'tubuh', 586:'tubuh', 601:'tubuh', 611:'tubuh', 612:'tubuh',
  614:'tubuh', 632:'tubuh', 633:'tubuh', 637:'tubuh', 638:'tubuh', 639:'tubuh',
  640:'tubuh', 760:'tubuh',
  // makan
  13:'makan', 47:'makan', 105:'makan', 156:'makan', 158:'makan', 276:'makan',
  301:'makan', 329:'makan', 333:'makan', 376:'makan', 378:'makan', 443:'makan',
  485:'makan', 496:'makan', 554:'makan', 558:'makan', 561:'makan', 571:'makan',
  577:'makan', 580:'makan', 679:'makan', 704:'makan', 732:'makan', 765:'makan',
  // rumah — bagian rumah, perabot, pakaian, benda
  52:'rumah',  // 层 floor of building
  95:'rumah', 99:'rumah', 119:'rumah', 254:'rumah', 263:'fungsi', 347:'rumah',
  418:'rumah', 423:'rumah', 436:'rumah', 449:'rumah', 497:'rumah', 585:'rumah',
  610:'rumah', 657:'rumah', 691:'rumah', 694:'rumah', 745:'rumah',
  // sekolah & kerja
  10:'sekolah', 14:'sekolah', 18:'sekolah', 19:'sekolah', 20:'sekolah',
  53:'sekolah', 64:'sekolah', 86:'sekolah', 88:'sekolah', 103:'sekolah',
  138:'sekolah', 166:'sekolah', 171:'sekolah', 180:'sekolah', 185:'sekolah',
  194:'sekolah', 251:'sekolah', 277:'sekolah', 278:'sekolah', 279:'sekolah',
  280:'sekolah', 312:'sekolah', 314:'sekolah', 316:'sekolah', 317:'sekolah',
  326:'sekolah', 352:'sekolah', 353:'sekolah', 399:'sekolah', 425:'sekolah',
  478:'sekolah', 486:'sekolah', 525:'sekolah', 608:'sekolah', 629:'sekolah',
  666:'sekolah', 674:'sekolah', 675:'sekolah', 688:'sekolah', 729:'sekolah',
  735:'sekolah', 749:'sekolah', 768:'sekolah', 769:'sekolah',
  // jalan — tempat, arah, transportasi
  16:'jalan', 24:'jalan',
  61:'jalan', 68:'jalan', 69:'jalan', 70:'jalan', 71:'jalan', 76:'jalan',
  77:'jalan', 112:'jalan', 114:'jalan', 125:'jalan', 126:'jalan', 130:'jalan',
  131:'jalan', 132:'jalan', 146:'jalan', 161:'jalan', 188:'jalan', 189:'jalan',
  192:'jalan', 195:'jalan', 204:'jalan', 231:'jalan', 244:'jalan', 272:'jalan',
  283:'jalan', 302:'jalan', // 酒店 hotel
  345:'jalan', 346:'jalan', 366:'jalan', 379:'jalan', 392:'jalan', 426:'jalan',
  427:'jalan', 430:'jalan', 469:'jalan', 475:'jalan', 482:'jalan', 490:'jalan',
  536:'jalan', 537:'jalan', 538:'jalan', 553:'jalan', 567:'umum', // 网站 website
  575:'jalan', 579:'jalan', 581:'jalan', 582:'jalan', 736:'jalan', 751:'jalan',
  767:'jalan',
  60:'belanja', // 超市 supermarket
  // belanja
  128:'belanja', 164:'belanja', 232:'belanja', 273:'belanja', 292:'belanja',
  309:'belanja', 372:'belanja', 414:'belanja', 471:'belanja', 481:'belanja',
  495:'belanja', 619:'belanja', 671:'belanja', 672:'belanja', 756:'belanja',
  // hobi — media, hiburan, olahraga, jalan-jalan
  15:'hobi', 48:'hobi', 137:'hobi', // 参观 visit, 动物园 zoo
  246:'hobi', // 活动 activity
  199:'hobi', 208:'hobi', 234:'hobi', 235:'hobi', 236:'hobi', 261:'hobi',
  288:'hobi', 290:'hobi', 291:'hobi', 337:'hobi', 367:'hobi', 368:'hobi',
  369:'hobi', 404:'hobi', 405:'hobi', 409:'hobi', 447:'hobi', 448:'hobi',
  466:'hobi', 529:'hobi', 530:'hobi', 531:'hobi', 550:'hobi', 560:'hobi',
  562:'hobi', 566:'hobi', 599:'hobi', 603:'hobi', 606:'hobi', 607:'hobi',
  613:'hobi', 626:'hobi', 669:'hobi', 670:'hobi', 676:'hobi', 680:'hobi',
  700:'hobi', 717:'hobi', 718:'hobi',
  // alam — cuaca, musim, alam, hewan
  50:'alam', 51:'alam', 79:'hobi', // 春节 -> hobi/festival
  80:'alam', 92:'alam', 100:'alam', 124:'alam', 133:'alam', 136:'alam',
  84:'waktu',  // 从小 from childhood
  152:'alam', 196:'alam', 211:'alam', 212:'alam', 221:'alam', 230:'alam',
  233:'alam', 249:'alam', 327:'alam', 354:'alam', 355:'alam', 359:'alam',
  370:'sifat', // 绿 green -> sifat (warna)
  375:'alam', 401:'alam', 432:'alam', 441:'alam', 442:'alam', 445:'alam',
  518:'alam', 532:'alam', 573:'alam', 588:'alam', 589:'alam', 620:'alam',
  630:'alam', 665:'alam', 667:'alam', 687:'alam', 698:'alam', 699:'alam',
  // sifat — warna & deskriptor
  6:'sifat', 223:'sifat', 225:'sifat', 226:'sifat', 227:'sifat', 241:'sifat',
  242:'sifat', 336:'sifat', 338:'sifat', 371:'sifat', 631:'sifat',
  4:'sifat', 5:'sifat', 30:'sifat', 32:'sifat', 55:'sifat', 56:'sifat',
  57:'sifat', 59:'umum', // 超过 to surpass
  123:'sifat', 140:'sifat', 144:'sifat', 157:'sifat', 184:'sifat', 193:'sifat',
  214:'sifat', 215:'umum', 219:'umum', 222:'sifat', 260:'sifat', 264:'umum',
  295:'sifat', 318:'sifat', 357:'sifat', 362:'sifat', 364:'sifat', 373:'sifat',
  377:'umum',  // 面 face/surface
  394:'sifat', 397:'sifat', 400:'sifat', 403:'sifat', 416:'sifat', 417:'sifat',
  420:'sifat', 421:'sifat', 424:'sifat', 437:'sifat', 438:'sifat', 461:'sifat',
  484:'sifat', 488:'sifat', 502:'sifat', 503:'sifat', 510:'sifat', 521:'sifat',
  522:'umum', 540:'sifat', 546:'sifat', 557:'sifat', 591:'sifat', 598:'sifat',
  659:'sifat', 682:'sifat', 685:'sifat', 703:'sifat', 722:'sifat', 723:'sifat',
  725:'sifat', 727:'sifat', 733:'sifat', 744:'sifat', 748:'sifat', 752:'sifat',
  98:'sifat',  // 大小 size
  252:'sifat', // 急 urgent
  // fungsi — partikel, konjungsi, preposisi, aux, tanya, kuantitas, CL
  21:'fungsi', 22:'fungsi', 23:'fungsi', 26:'fungsi', 29:'umum', 31:'fungsi',
  33:'fungsi', 34:'fungsi', 35:'fungsi', 40:'fungsi', 41:'fungsi', 42:'sifat',
  44:'fungsi', 46:'fungsi', 54:'sifat', 58:'fungsi', 89:'fungsi',
  90:'fungsi', 91:'fungsi', 94:'fungsi', 104:'fungsi', 106:'fungsi', 107:'fungsi',
  117:'fungsi', 118:'fungsi', 120:'umum', 122:'umum', 139:'fungsi', 142:'fungsi',
  148:'fungsi', 149:'fungsi', 150:'fungsi', 151:'fungsi', 153:'fungsi',
  168:'fungsi', 169:'fungsi', 172:'fungsi', 187:'fungsi', 190:'fungsi',
  191:'fungsi', 200:'fungsi', 206:'sifat', 207:'umum', 209:'waktu', 210:'fungsi',
  216:'fungsi', 243:'fungsi', 245:'fungsi', 247:'fungsi', 248:'fungsi',
  250:'umum', 256:'fungsi', 286:'fungsi', 287:'fungsi', 303:'fungsi',
  307:'sekolah', 319:'fungsi', 321:'fungsi', 322:'fungsi', 323:'fungsi',
  332:'fungsi', 334:'umum', 335:'umum', 339:'fungsi', 343:'fungsi', 344:'fungsi',
  348:'umum', 349:'fungsi', 350:'umum', 356:'fungsi', 358:'fungsi', 360:'umum',
  361:'umum', 363:'umum', 380:'fungsi', 381:'umum', 382:'umum', 384:'umum',
  387:'fungsi', 389:'fungsi', 391:'fungsi', 396:'umum', 398:'fungsi',
  402:'umum', 407:'fungsi', 408:'umum', 413:'fungsi', 415:'fungsi', 428:'fungsi',
  429:'fungsi', 433:'fungsi', 434:'fungsi', 444:'umum', 446:'umum', 450:'umum',
  451:'umum', 452:'fungsi', 453:'fungsi', 454:'fungsi', 456:'fungsi', 458:'fungsi',
  459:'fungsi', 460:'fungsi', 462:'umum', 464:'fungsi', 465:'umum', 468:'fungsi',
  470:'umum', 473:'fungsi', 476:'fungsi', 477:'umum', 479:'umum', 483:'fungsi',
  487:'umum', 489:'umum', 491:'umum', 493:'umum', 494:'umum', 498:'umum',
  500:'fungsi', 501:'fungsi', 504:'umum', 506:'umum', 507:'umum', 508:'umum',
  509:'fungsi', 512:'fungsi', 513:'fungsi', 514:'fungsi', 515:'fungsi',
  516:'umum', 519:'umum', 520:'fungsi', 524:'umum', 526:'umum', 527:'umum',
  528:'umum', 533:'fungsi', 534:'umum', 535:'umum', 539:'fungsi', 541:'umum',
  542:'umum', 543:'umum', 544:'fungsi', 549:'fungsi', 551:'umum', 555:'umum',
  556:'umum', 563:'fungsi', 564:'umum', 565:'fungsi', 568:'fungsi', 569:'fungsi',
  572:'fungsi', 574:'umum', 576:'umum', 584:'umum', 587:'fungsi', 592:'umum',
  593:'umum', 594:'umum', 595:'umum', 596:'umum', 597:'fungsi', 600:'fungsi',
  605:'umum', 615:'umum', 616:'umum', 617:'umum', 618:'umum', 621:'umum',
  623:'umum', 627:'fungsi', 628:'umum', 634:'umum', 635:'umum', 636:'umum',
  641:'fungsi', 645:'fungsi', 646:'fungsi', 647:'fungsi',
  651:'fungsi', 653:'fungsi', 654:'fungsi', 655:'umum', 656:'fungsi', 658:'fungsi',
  660:'fungsi', 661:'umum', 663:'umum', 664:'fungsi', 668:'fungsi', 673:'fungsi',
  677:'umum', 678:'fungsi', 681:'fungsi', 684:'fungsi', 686:'fungsi', 689:'fungsi',
  690:'umum', 692:'umum', 695:'fungsi', 697:'fungsi', 701:'fungsi', 702:'fungsi',
  706:'fungsi', 707:'fungsi', 708:'fungsi', 709:'fungsi', 710:'umum', 711:'umum',
  712:'umum', 713:'umum', 714:'umum', 715:'umum', 716:'umum', 719:'fungsi',
  721:'fungsi', 724:'fungsi', 726:'fungsi', 728:'fungsi', 730:'fungsi',
  731:'fungsi', 738:'umum', 739:'umum', 746:'tubuh', 747:'umum', 750:'fungsi',
  753:'umum', 754:'umum', 755:'umum', 757:'fungsi', 758:'umum', 762:'fungsi',
  763:'umum', 764:'umum', 770:'umum',
  // koreksi misroute keyword
  8:'umum', 9:'umum', 62:'umum', 67:'fungsi', 101:'umum', 102:'umum', 111:'umum',
  115:'umum', 116:'umum', 129:'umum', 154:'umum', 159:'umum', 160:'umum',
  173:'umum', 181:'fungsi', 197:'fungsi', 213:'umum', 253:'umum', 268:'umum',
  269:'umum', 270:'umum', 282:'umum', 293:'fungsi', 299:'umum', 305:'umum',
  313:'umum', 315:'umum', 365:'sekolah', 411:'umum', 412:'umum', 488:'fungsi',
  502:'umum', 557:'fungsi',
};

// ---- Keyword rules: cek meaning (lowercase), pola regex, first match menang ----
const R = (s) => new RegExp(`\\b(${s})\\b`, 'i');
const RULES = [
  ['tubuh',  R('body|head|face|eye|ear|nose|mouth|tooth|teeth|hair|hand|arm|leg|foot|feet|finger|heart|back|neck|shoulder|skin|blood|brain|health|healthy|sick|ill|disease|pain|hurt|medicine|drug|pill|hospital|pharmacy|clinic|doctor|nurse|patient|dentist|rest|sleep|nap|tired|exercise|bath|shower|comfortable|unwell|feel|feeling|emotion|mood|happy|sad|angry|afraid|fear|scared|worry|worried|cry|laugh|smile|love|hate|miss|surprised|shocked|relieved|calm|nervous|anxious|moved|touched|satisfied|voice|sound')],
  ['makan',  R('food|eat|drink|meal|rice|noodle|dumpling|egg|meat|pork|beef|fruit|apple|banana|orange|vegetable|bread|milk|tea|coffee|juice|wine|beer|beverage|restaurant|menu|dish|cuisine|breakfast|lunch|dinner|hungry|thirsty|full|taste|flavor|delicious|sweet|sour|bitter|spicy|salty|cook|kitchen|bowl|chopstick|spoon|fork|plate|cup|snack|sugar|salt|oil|sauce|toast|supermarket')],
  ['belanja',R('buy|sell|shop|shopping|store|mall|market|price|cost|cheap|expensive|money|cash|pay|payment|spend|discount|yuan|dollar|bill|receipt|wallet|bank|card|rent|fee|charge|customer|sale|income|earn|profit|kilogram|gram|jīn')],
  ['sekolah',R('school|class|classroom|student|teacher|lesson|course|subject|study|learn|exam|test|homework|grade|score|university|college|campus|semester|graduate|education|teach|language|chinese|english|mandarin|dictionary|word|sentence|paragraph|essay|composition|pronunciation|syllable|notebook|blackboard|pen|pencil|book|knowledge|science|practice|review|question|answer|work|job|office|company|business|boss|employee|manager|staff|meeting|salary|factory|career|colleague|labor|print')],
  ['jalan',  R('car|bus|taxi|subway|metro|train|plane|airport|flight|ship|boat|bicycle|bike|vehicle|drive|ride|traffic|station|ticket|passport|luggage|journey|travel|depart|arrive|abroad|road|street|highway|bridge|route|map|direction|way|path|entrance|exit|gate|city|town|village|country|province|capital|place|location|address|area|region|district|park|museum|library|hotel|building|square|plaza|post office|north|south|east|west|center|middle|front|behind|left|right|side|inside|outside|opposite|near|far|pedestrian|seat|kilometer')],
  ['rumah',  R('house|home|room|bedroom|bathroom|toilet|door|window|wall|floor|roof|stairs|bed|table|desk|chair|sofa|lamp|light|television|refrigerator|washing machine|key|box|bag|umbrella|clothes|clothing|shirt|pants|trousers|dress|coat|jacket|shoe|sock|hat|glasses|watch|thing|object|item|tool|furniture|mirror|paper|computer|phone|toy|bottle|gift|present|yard|courtyard|housing')],
  ['hobi',   R('play|game|sport|ball|basketball|football|soccer|volleyball|tennis|swim|run|sing|song|dance|music|concert|movie|film|program|news|newspaper|story|novel|draw|paint|picture|photo|camera|party|birthday|festival|holiday|vacation|celebrate|hobby|fun|interesting|joke|walk|climb|activity|match|competition|win|lose|prize|television|zoo')],
  ['alam',   R('weather|sunny|cloudy|rain|snow|wind|storm|temperature|below zero|sun|moon|star|sky|cloud|season|spring|summer|autumn|winter|air|river|sea|ocean|lake|mountain|hill|forest|tree|grass|flower|plant|nature|earth|planet|environment|animal|dog|cat|bird|fish|chicken|pet|cool|cold|hot|warm|fog')],
  ['orang',  R('person|people|man|woman|boy|girl|friend|guest|customer|teacher|student|doctor|nurse|manager|driver|worker|boss|waiter|host|member|leader|monitor|captain|adult|elderly|youth|teenager|gentleman|lady|population|celebrity|author|mayor|visitor|name|surname|father|mother|parent|brother|sister|son|daughter|child|children|grandfather|grandmother|uncle|aunt|husband|wife|spouse|family|baby|married|relative|everyone|someone|i|me|you|he|she|it|we|they|self')],
  ['sifat',  R('good|bad|big|small|large|tall|short|long|high|low|many|much|few|little|more|most|new|old|young|fast|slow|quick|easy|difficult|hard|simple|right|correct|wrong|true|real|false|same|different|similar|important|special|normal|common|ordinary|strange|famous|popular|beautiful|pretty|handsome|ugly|clean|dirty|quiet|noisy|loud|bright|dark|strong|weak|soft|deep|shallow|wide|narrow|thick|thin|fat|empty|rich|poor|busy|free|boring|tired|convenient|safe|dangerous|useful|enough|ready|willing|clever|smart|stupid|kind|friendly|polite|honest|serious|careful|accurate|exact|clear|certain|sure|able|suitable|proper|direct|straight|smooth|open|closed|close|excellent|perfect|wonderful|terrible|great|fine|nice|lovely|cute|fresh|ripe|cooked|familiar|fluent|equal|fair|peaceful|gentle|main|whole|entire|total|single|several|various|general|average|advanced|intermediate|white|black|red|blue|green|yellow|color')],
  ['fungsi', R('particle|pronoun|preposition|conjunction|auxiliary|modal|interjection|prefix|suffix|aspect|structural|interrogative|if|because|but|and|or|so|although|though|however|therefore|moreover|then|only|just|also|too|either|neither|very|quite|rather|really|even|still|yet|already|perhaps|maybe|probably|certainly|surely|almost|nearly|about|around|everywhere|anywhere|somewhere|nowhere|here|there|where|when|which|who|whose|whom|what|how|why|how many|how much|how long|what kind|example|such as|equal|than|per|each|every|all|both|neither|other|another|any|some|none|total|altogether|in total')],
];

function classify(entry) {
  if (HAND[entry.id]) return HAND[entry.id];
  const m = (entry.meaning || '').toLowerCase();
  if (/^(cl:|aspect particle|structural particle|modal particle|pronoun|prefix|suffix|interjection|measure)/.test(m)) return 'fungsi';
  for (const [topic, rx] of RULES) if (rx.test(m)) return topic;
  return 'umum';
}

// ---- jalankan ----
const topics = data.vocab.map(classify);
const counts = {};
topics.forEach(t => counts[t] = (counts[t] || 0) + 1);

// report utk review
const lines = UNITS.map(([key, name]) => {
  const words = data.vocab.filter((_, i) => topics[i] === key).map(w => `${w.id}:${w.hanzi} ${w.meaning.split('•')[0].trim()}`);
  return `\n=== ${key.toUpperCase()} — ${name} (${words.length} kata) ===\n${words.join('\n')}`;
});
const unknown = topics.filter(t => !TOPIC_NAMES[t]);
if (unknown.length) { console.error('UNKNOWN TOPICS:', unknown); process.exit(1); }

fs.writeFileSync(path.join(ROOT, 'tools/_topics_report.txt'),
  `DISTRIBUSI: ${JSON.stringify(counts)}\n${lines.join('\n')}`, 'utf8');

// tulis topic ke vocab_data.json
data.vocab.forEach((w, i) => { w.topic = topics[i]; });
fs.writeFileSync(path.join(ROOT, 'vocab_data.json'), JSON.stringify(data, null, 1) + '\n', 'utf8');

// emit const WORD_TOPIC + UNIT meta utk di-inline di index.html
const unitMeta = UNITS.map(([key, name]) => `{key:'${key}',name:'${name}'}`).join(',');
fs.writeFileSync(path.join(ROOT, 'tools/_word_topic.js'),
  `const UNIT_DEFS=[${unitMeta}];\nconst WORD_TOPIC=${JSON.stringify(topics)};\n`, 'utf8');

console.log('Distribusi:', counts);
console.log('Total:', topics.length, '| report → tools/_topics_report.txt');
