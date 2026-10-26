// assign_topics_hsk1.mjs — klasifikasikan 300 kata HSK1 ke unit tematis (key sama dgn HSK2).
// Input : tools/hsk1_words.json  ({hanzi,pinyin,pos,meaning,traditional,sentences}[])
// Output: menulis field `topic` ke file itu + tools/_hsk1_topics_report.txt

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const FILE = path.join(ROOT, 'tools', 'hsk1_words.json');
const data = JSON.parse(fs.readFileSync(FILE, 'utf8'));

const UNITS = [
  ['dasar', 'Sapaan & Ungkapan Dasar'],
  ['waktu', 'Angka, Waktu & Ukuran'],
  ['orang', 'Orang & Keluarga'],
  ['tubuh', 'Tubuh, Kesehatan & Perasaan'],
  ['makan', 'Makanan & Minuman'],
  ['rumah', 'Rumah & Benda'],
  ['sekolah', 'Sekolah & Kerja'],
  ['jalan', 'Tempat, Arah & Transportasi'],
  ['belanja', 'Belanja & Uang'],
  ['hobi', 'Aktivitas & Hobi'],
  ['alam', 'Alam, Cuaca & Hewan'],
  ['sifat', 'Sifat & Deskripsi'],
  ['umum', 'Kata Kerja & Kata Umum'],
  ['fungsi', 'Kata Fungsi & Tata Bahasa'],
];
const NAMES = Object.fromEntries(UNITS);

// Override manual per hanzi (ambigu/polisemi)
const HAND = {
  // dasar — sapaan & ungkapan sopan
  '你好': 'dasar', '您好': 'dasar', '你们好': 'dasar', '谢谢': 'dasar', '不客气': 'dasar',
  '再见': 'dasar', '对不起': 'dasar', '没关系': 'dasar', '请': 'dasar', '叫': 'dasar',
  '请问': 'dasar', '喂': 'dasar',
  '名字': 'dasar', '是': 'fungsi', '吗': 'fungsi', '的': 'fungsi', '了': 'fungsi',
  '可以': 'fungsi', '能': 'fungsi', '要': 'fungsi', '还': 'fungsi', '不要': 'fungsi',
  '有点儿': 'fungsi', '一下': 'fungsi', '非常': 'fungsi', '没事': 'fungsi', '第': 'fungsi',
  '呢': 'fungsi', '吧': 'fungsi', '不': 'fungsi', '没': 'fungsi', '没有': 'fungsi',
  '都': 'fungsi', '也': 'fungsi', '很': 'fungsi', '太': 'fungsi', '在': 'umum',
  '和': 'fungsi', '吗吗': 'fungsi',
  // orang — kata ganti & keluarga
  '我': 'orang', '你': 'orang', '您': 'orang', '他': 'orang', '她': 'orang', '它': 'orang',
  '我们': 'orang', '你们': 'orang', '他们': 'orang', '她们': 'orang', '大家': 'orang',
  '爸爸': 'orang', '妈妈': 'orang', '儿子': 'orang', '女儿': 'orang', '孩子': 'orang',
  '先生': 'orang', '小姐': 'orang', '老师': 'orang', '学生': 'orang', '医生': 'orang',
  '同学': 'orang', '朋友': 'orang', '谁': 'fungsi', '人': 'orang', '家': 'rumah',
  '女人': 'orang', '男人': 'orang', '中国人': 'orang', '女士': 'orang',
  '男': 'orang', '女': 'orang', '男朋友': 'orang', '女朋友': 'orang', '它们': 'orang',
  // waktu
  '年': 'waktu', '月': 'waktu', '日': 'waktu', '号': 'waktu', '星期': 'waktu', '天': 'waktu',
  '今天': 'waktu', '明天': 'waktu', '昨天': 'waktu', '现在': 'waktu', '时候': 'waktu',
  '点': 'waktu', '分': 'waktu', '钟': 'waktu', '上午': 'waktu', '中午': 'waktu',
  '下午': 'waktu', '晚上': 'waktu', '早上': 'waktu', '周末': 'waktu', '生日': 'hobi',
  '去年': 'waktu', '今年': 'waktu', '明年': 'waktu', '岁': 'waktu', '年龄': 'waktu',
  '时候呢': 'waktu', '前天': 'waktu', '后天': 'waktu', '半': 'waktu', '白天': 'waktu',
  '时间': 'waktu', '小时': 'waktu', '分钟': 'waktu', '星期日': 'waktu', '星期天': 'waktu',
  // makan
  '吃': 'makan', '喝': 'makan', '饭': 'makan', '菜': 'makan', '茶': 'makan', '水': 'makan',
  '咖啡': 'makan', '牛奶': 'makan', '水果': 'makan', '苹果': 'makan', '米饭': 'makan',
  '面条': 'makan', '包子': 'makan', '饭店': 'makan', '杯子': 'makan', '瓶': 'makan',
  '鸡蛋': 'makan', '西瓜': 'makan', '糖': 'makan', '肉': 'makan', '面条儿': 'makan',
  // jalan
  '车': 'jalan', '出租车': 'jalan', '飞机': 'jalan', '火车': 'jalan', '地铁': 'jalan',
  '自行车': 'jalan', '坐': 'jalan', '去': 'umum', '来': 'umum', '回': 'umum', '走': 'umum',
  '好听': 'sifat', '对': 'sifat',
  '机场': 'jalan', '站': 'jalan', '路': 'jalan', '北京': 'jalan', '中国': 'jalan',
  '到': 'jalan',
  '商店': 'belanja', '超市': 'belanja', '买': 'belanja', '钱': 'belanja', '块': 'belanja',
  '毛': 'belanja', '元': 'belanja', '价格': 'belanja', '便宜': 'belanja', '贵': 'belanja',
  '书店': 'belanja',
  // sekolah
  '学校': 'sekolah', '学习': 'sekolah', '学': 'sekolah', '读': 'sekolah', '写': 'sekolah',
  '书': 'sekolah', '字': 'sekolah', '汉语': 'sekolah', '中文': 'sekolah', '英语': 'sekolah',
  '课': 'sekolah', '考试': 'sekolah', '作业': 'sekolah', '笔': 'sekolah', '本子': 'sekolah',
  '工作': 'sekolah', '上班': 'sekolah', '公司': 'sekolah', '医院': 'tubuh',
  // tubuh
  '病': 'tubuh', '看病': 'tubuh', '身体': 'tubuh', '疼': 'tubuh', '累': 'tubuh',
  '睡觉': 'tubuh', '睡': 'tubuh', '休息': 'tubuh', '高兴': 'tubuh', '开心': 'tubuh',
  '生气': 'tubuh', '哭': 'tubuh', '笑': 'tubuh', '爱': 'tubuh', '喜欢': 'tubuh',
  '想': 'umum', '觉得': 'umum', '感冒': 'tubuh',
  // hobi
  '电视': 'hobi', '电影': 'hobi', '音乐': 'hobi', '唱歌': 'hobi', '唱': 'hobi',
  '听': 'hobi', '看': 'umum', '看见': 'umum', '运动': 'hobi', '跑步': 'hobi',
  '游泳': 'hobi', '玩': 'hobi', '旅游': 'hobi', '游戏': 'hobi', '聊天': 'hobi',
  // alam
  '天气': 'alam', '雨': 'alam', '雪': 'alam', '风': 'alam', '冷': 'alam', '热': 'alam',
  '猫': 'alam', '狗': 'alam', '鸟': 'alam', '鱼': 'alam', '山': 'alam', '花': 'alam',
  // rumah
  '房间': 'rumah', '桌子': 'rumah', '椅子': 'rumah', '门': 'rumah', '窗户': 'rumah',
  '床': 'rumah', '住': 'rumah', '家呢': 'rumah', '房子': 'rumah', '电话': 'rumah',
  '手机': 'rumah', '电脑': 'rumah', '桌子呢': 'rumah', '衣服': 'rumah', '东西': 'rumah',
};

const R = (s) => new RegExp(`\\b(${s})\\b`, 'i');
const RULES = [
  ['tubuh', R('body|head|face|eye|ear|nose|mouth|tooth|teeth|hair|hand|arm|leg|foot|feet|finger|heart|back|neck|shoulder|skin|health|sick|ill|disease|pain|hurt|medicine|hospital|doctor|nurse|patient|rest|sleep|tired|feel|feeling|happy|sad|angry|afraid|worry|cry|laugh|smile|love|miss|surprised|calm|nervous|voice')],
  ['makan', R('food|eat|drink|meal|rice|noodle|dumpling|egg|meat|fruit|apple|vegetable|bread|milk|tea|coffee|juice|restaurant|menu|dish|breakfast|lunch|dinner|hungry|thirsty|taste|delicious|cook|kitchen|bowl|cup|sugar|bun|supermarket')],
  ['belanja', R('buy|sell|shop|shopping|store|market|price|cost|cheap|expensive|money|cash|pay|yuan|dollar|customer|sale|jīn|kilogram')],
  ['sekolah', R('school|class|classroom|student|teacher|lesson|course|study|learn|exam|test|homework|university|college|teach|language|chinese|english|mandarin|dictionary|word|sentence|book|pen|pencil|work|job|office|company|boss|employee|meeting|hospital')],
  ['jalan', R('car|bus|taxi|subway|train|plane|airport|ship|bicycle|bike|vehicle|drive|ride|traffic|station|ticket|journey|travel|road|street|map|city|town|country|capital|place|address|hotel|north|south|east|west|front|behind|left|right|side|inside|outside|near|far|seat|beijing|china')],
  ['rumah', R('house|home|room|bedroom|bathroom|toilet|door|window|wall|floor|bed|table|desk|chair|sofa|lamp|television|key|box|bag|umbrella|clothes|shirt|pants|dress|coat|shoe|hat|glasses|computer|phone|toy|bottle|gift')],
  ['hobi', R('play|game|sport|ball|swim|run|sing|song|dance|music|movie|film|news|story|photo|party|birthday|holiday|vacation|hobby|fun|interesting|walk|television|chat|wechat')],
  ['alam', R('weather|sunny|cloudy|rain|snow|wind|temperature|sun|moon|star|sky|cloud|season|spring|summer|autumn|winter|air|river|mountain|tree|flower|animal|dog|cat|bird|fish|pet|cold|hot|warm')],
  ['orang', R('person|people|man|woman|boy|girl|friend|guest|teacher|student|doctor|driver|waiter|adult|name|father|mother|parent|brother|sister|son|daughter|child|children|uncle|aunt|family|baby|married|everyone|someone|self')],
  ['sifat', R('good|bad|big|small|tall|short|long|high|low|many|much|few|little|more|most|new|old|young|fast|slow|easy|difficult|right|wrong|true|real|same|different|important|special|beautiful|pretty|clean|dirty|quiet|loud|bright|strong|busy|free|safe|useful|enough|ready|clever|kind|friendly|white|black|red|blue|green|yellow|color|early|late')],
  ['fungsi', R('particle|pronoun|preposition|conjunction|auxiliary|modal|interjection|interrogative|if|because|but|and|or|so|then|only|just|also|too|very|quite|already|maybe|here|there|where|when|which|who|what|how|why|than|each|every|all|both|other|another|some|none|together|again|measure word|mw\\.|classifier')],
];

function classify(e) {
  if (HAND[e.hanzi]) return HAND[e.hanzi];
  const pos = (e.pos || '').toLowerCase();
  if (/^(pron|part|conj|aux|prep|int|mw|num\.?mw|prefix|suffix)/.test(pos)) {
    if (pos.startsWith('num')) return 'waktu';
    return 'fungsi';
  }
  if (pos.startsWith('num')) return 'waktu';
  const m = (e.meaning || '').toLowerCase();
  for (const [t, rx] of RULES) if (rx.test(m)) return t;
  return 'umum';
}

const report = [];
const dist = {};
for (const e of data) {
  e.topic = classify(e);
  dist[e.topic] = (dist[e.topic] || 0) + 1;
}
let n = 0;
for (const e of data) e.id = ++n; // re-id 1..300 urutan alfabetis

fs.writeFileSync(FILE, JSON.stringify(data, null, 0));
let rep = '';
for (const [k, name] of UNITS) {
  const items = data.filter((e) => e.topic === k);
  rep += `\n=== ${name} (${items.length}) ===\n` + items.map((e) => e.hanzi).join('、') + '\n';
}
rep += '\nDIST: ' + JSON.stringify(dist);
fs.writeFileSync(path.join(ROOT, 'tools', '_hsk1_topics_report.txt'), rep);
console.log('DIST:', dist);
console.log('report -> tools/_hsk1_topics_report.txt');
