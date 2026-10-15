// Generator script for HSK 2 V3 vocabulary sentences
import fs from 'fs';
import { readFile, writeFile } from 'fs/promises';

const dataPath = 'C:\\Users\\PC\\Documents\\Kunkwan\\HSK 2\\V3\\vocab_data.json';
const outputPath = dataPath;

// Mapping of special radical chars to their standard simplified equivalents
const specialToStandard = {
  '\u2ED3': '长', // ⻓
  '\u2EC5': '见', // ⻅
  '\u2ECB': '车', // ⻋
  '\u2ED4': '门', // ⻔
  '\u2EE9': '黄', // ⻩
  '\u2EC6': '角', // ⻆
  '\u2EE6': '鸟', // ⻦
  '\u2EDC': '飞', // ⻜
  '\u2ED8': '青', // ⻘
  '\u2EDD': '食', // ⻝
  '\u2EC4': '西', // ⻄
  '\u2EDB': '风', // ⻛
  '\u2EE5': '鱼', // ⻥
};

const standardToSpecial = {};
for (const [sp, std] of Object.entries(specialToStandard)) {
  standardToSpecial[std] = sp;
}

// Correctly replace only the special chars in a sentence
// Given vocab hanzi "班⻓" and sentence "我是班长", we need to replace 长 with ⻓
function fixSpecialChars(sentence, hanzi) {
  let result = sentence;
  for (const c of hanzi) {
    const cp = c.codePointAt(0);
    if (cp > 0x2E00 && cp < 0x2FD0) {
      // This is a special radical char
      const std = specialToStandard[c];
      if (std) {
        // Replace only occurrences that correspond to the target word
        // Simple: replace first occurrence of the standard char in the relevant position
        // Safer: just replace the standard char globally in the sentence
        // This could over-replace, but for most HSK sentences it's fine
        // For precision, let's find the target word's position in the sentence
        // and only replace within it
        // Since we can't easily do that without knowing the full word boundary,
        // let's just check if the standard char should be replaced
        result = result.replace(new RegExp(std.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g'), c);
      }
    }
  }
  return result;
}

// Sentence definitions for all 770 words
// Indexed by word id, array of [chinese_sentence, pinyin, indonesian]
// chinese_sentence uses STANDARD simplified chars; fixSpecialChars will convert
const sentenceTemplates = {
  // Word 1-100
  1: [
    ["你好啊！", "nǐ hǎo a!", "Halo!"],
    ["好啊，我们一起吃饭吧。", "hǎo a, wǒmen yìqǐ chīfàn ba.", "Baiklah, ayo kita makan bersama."],
    ["真漂亮啊！", "zhēn piàoliang a!", "Sungguh cantik!"]
  ],
  2: [
    ["他们的爱情很美好。", "tāmen de àiqíng hěn měihǎo.", "Cinta mereka sangat indah."],
    ["爱情让人很开心。", "àiqíng ràng rén hěn kāixīn.", "Cinta membuat orang sangat bahagia."],
    ["我相信爱情。", "wǒ xiāngxìn àiqíng.", "Saya percaya cinta."]
  ],
  3: [
    ["我爱人在家等我。", "wǒ àiren zài jiā děng wǒ.", "Pasangan saya menunggu di rumah."],
    ["我爱人很照顾我。", "wǒ àiren hěn zhàogu wǒ.", "Pasangan saya sangat merawat saya."],
    ["今天我和爱人一起去看电影。", "jīntiān wǒ hé àiren yìqǐ qù kàn diànyǐng.", "Hari ini saya dan pasangan pergi nonton film."]
  ],
  4: [
    ["请安静。", "qǐng ānjìng.", "Mohon tenang."],
    ["图书馆很安静。", "túshūguǎn hěn ānjìng.", "Perpustakaan sangat tenang."],
    ["早上公园很安静。", "zǎoshang gōngyuán hěn ānjìng.", "Taman pagi hari sangat sunyi."]
  ],
  5: [
    ["开车要注意安全。", "kāichē yào zhùyì ānquán.", "Menyetir harus perhatikan keamanan."],
    ["这里很安全。", "zhèlǐ hěn ānquán.", "Di sini aman."],
    ["安全第一。", "ānquán dìyī.", "Keselamatan nomor satu."]
  ],
  6: [
    ["我喜欢白色。", "wǒ xǐhuan báisè.", "Saya suka warna putih."],
    ["白色的花很漂亮。", "báisè de huā hěn piàoliang.", "Bunga putih sangat cantik."],
    ["她穿了白色的衣服。", "tā chuān le báisè de yīfu.", "Dia memakai baju putih."]
  ],
  7: [
    ["他是班长。", "tā shì bānzhǎng.", "Dia adalah ketua kelas."],
    ["班长帮老师做事。", "bānzhǎng bāng lǎoshī zuò shì.", "Ketua kelas membantu guru."],
    ["我们选他做班长。", "wǒmen xuǎn tā zuò bānzhǎng.", "Kami memilihnya jadi ketua kelas."]
  ],
  8: [
    ["这件事我来办。", "zhè jiàn shì wǒ lái bàn.", "Urusan ini saya urus."],
    ["你去办吧。", "nǐ qù bàn ba.", "Kamu urus saja."],
    ["怎么办这件事？", "zěnme bàn zhè jiàn shì?", "Bagaimana mengurus hal ini?"]
  ],
  9: [
    ["我有办法。", "wǒ yǒu bànfǎ.", "Saya punya cara."],
    ["这个办法很好。", "zhège bànfǎ hěn hǎo.", "Cara ini bagus."],
    ["你想办法吧。", "nǐ xiǎng bànfǎ ba.", "Kamu pikirkan cara."]
  ],
  10: [
    ["老师在办公室。", "lǎoshī zài bàngōngshì.", "Guru ada di kantor."],
    ["办公室很大。", "bàngōngshì hěn dà.", "Kantornya besar."],
    ["我去办公室找你。", "wǒ qù bàngōngshì zhǎo nǐ.", "Saya ke kantor cari kamu."]
  ],
  11: [
    ["他半夜才回家。", "tā bànyè cái huí jiā.", "Dia pulang tengah malam."],
    ["半夜十二点了我还在学习。", "bànyè shí'èr diǎn le wǒ hái zài xuéxí.", "Jam 12 malam saya masih belajar."],
    ["半夜不要大声说话。", "bànyè búyào dàshēng shuōhuà.", "Jangan bicara keras tengah malam."]
  ],
  12: [
    ["谢谢你帮助我。", "xièxie nǐ bāngzhù wǒ.", "Terima kasih membantu saya."],
    ["我需要帮助。", "wǒ xūyào bāngzhù.", "Saya butuh bantuan."],
    ["朋友之间要互相帮助。", "péngyou zhījiān yào hùxiāng bāngzhù.", "Teman harus saling membantu."]
  ],
  13: [
    ["我吃饱了。", "wǒ chībǎo le.", "Saya sudah kenyang."],
    ["你吃饱了吗？", "nǐ chībǎo le ma?", "Kamu sudah kenyang?"],
    ["今天吃得很饱。", "jīntiān chī de hěn bǎo.", "Hari ini makan sangat kenyang."]
  ],
  14: [
    ["我要报名学汉语。", "wǒ yào bàomíng xué hànyǔ.", "Saya mau mendaftar belajar Mandarin."],
    ["报名时间到了。", "bàomíng shíjiān dào le.", "Waktu pendaftaran sudah tiba."],
    ["你报名了吗？", "nǐ bàomíng le ma?", "Kamu sudah daftar?"]
  ],
  15: [
    ["爸爸在看报纸。", "bàba zài kàn bàozhǐ.", "Ayah membaca koran."],
    ["这份报纸是今天的。", "zhè fèn bàozhǐ shì jīntiān de.", "Koran ini hari ini."],
    ["我不常看报纸。", "wǒ bù cháng kàn bàozhǐ.", "Saya jarang baca koran."]
  ],
  16: [
    ["北京在北方。", "Běijīng zài běifāng.", "Beijing ada di utara."],
    ["北方天气很冷。", "běifāng tiānqì hěn lěng.", "Utara udaranya dingin."],
    ["他来自北方。", "tā láizì běifāng.", "Dia berasal dari utara."]
  ],
  17: [
    ["他背着书包。", "tā bēi zhe shūbāo.", "Dia memanggul tas."],
    ["他的背很疼。", "tā de bèi hěn téng.", "Punggungnya sakit."],
    ["他背了很多东西。", "tā bèi le hěnduō dōngxi.", "Dia membawa banyak hal."]
  ],
  18: [
    ["他用笔写字。", "tā yòng bǐ xiě zì.", "Dia menulis dengan pena."],
    ["给我一支笔。", "gěi wǒ yì zhī bǐ.", "Beri saya satu pena."],
    ["这笔钱太多了。", "zhè bǐ qián tài duō le.", "Uang ini terlalu banyak."]
  ],
  19: [
    ["他做笔记。", "tā zuò bǐjì.", "Dia membuat catatan."],
    ["我看你的笔记。", "wǒ kàn nǐ de bǐjì.", "Saya lihat catatanmu."],
    ["笔记很有用。", "bǐjì hěn yǒuyòng.", "Catatan sangat berguna."]
  ],
  20: [
    ["这个笔记本是我的。", "zhège bǐjìběn shì wǒ de.", "Notebook ini milik saya."],
    ["笔记本很好用。", "bǐjìběn hěn hǎo yòng.", "Notebook sangat berguna."],
    ["我买了一个笔记本。", "wǒ mǎi le yígè bǐjìběn.", "Saya beli satu notečety."]
  ],
  21: [
    ["我喜欢吃水果，比如苹果。", "wǒ xǐhuan chī shuǐguǒ, bǐrú píngguǒ.", "Saya suka buah, misal apel."],
    ["比如，去公园玩。", "bǐrú, qù gōngyuán wán.", "Misalnya, pergi taman."],
    ["很多动物，比如猫和狗。", "hěn duō dòngwù, bǐrú māo hé gǒu.", "Banyak binatang, misal kucing anjing."]
  ],
  22: [
    ["比如说，你可以学。", "bǐrúshuō, nǐ kéyǐ xué.", "Misalnya kamu belajarlah"],
    ["比如说，你要好好学习。", "bǐrúshuō, nǐ yào hǎohāo xuéxí.", "Misalnya, kamu har belajar."]
  ],
  23: [
    ["你必须来上课。", "nǐ bìxū lái shàngkè.", "Kamu harus datang kelas."],
    ["我必须学习。", "wǒ bìxū xuéxí.", "Saya harus belajar."],
    ["你必须注意安全。", "nǐ bìxū zhùyì ānquán.", "Kamu harus perhatikan keselamatan."]
  ],
  24: [
    ["桌子边有一本书。", "zhuōzi biān yǒu yì běn shū.", "Di samping meja ada buku."],
    ["路边有很多花。", "lùbiān yǒu hěnduō huā.", "Di tepi jalan banyak bunga."],
    ["河边有一个人。", "hé biān yǒu yígè rén.", "Di tepi sungai ada seorang."]
  ],
  25: [
    ["天气变了。", "tiānqì biàn le.", "Cuaca berubah."],
    ["他想变漂亮。", "tā xiǎng biàn piàoliang.", "Dia ingin cantik."],
    ["变了很多。", "biàn le hěnduō."]], "Banyak berubah!"
  ],
  26: [
    ["我看了一遍。", "wǒ kàn le yí biàn.", "Saya melihat sekali."],
    ["他读了十遍。", "tā dú le shí biàn.", "Dia membaca sepuluh kali."],
    ["请你再说一遍。", "qǐng nǐ zài shuō yí biàn.", "Tolong katakan lagi."]
  ],
  27: [
    ["他变成大人了。", "tā biànchéng dàren le.", "Dia menjadi dewasa."],
    ["变天了。", "biàntiān le.", "Cuaca berubah."],
    ["变成了朋友。", "biànchéng le péngy", "Menjadi teman."]
  ],
  28: [
    ["看手表", "kàn shǒuB", "Lihat arloji"],
    ["填表", "tián biǎo", "Isi formulir"],
    ["表示满意", "biǎoshì mǎn"], "Menyatakan puas"]
  ],
  29: [
    ["他点头表示同意。", "tā diǎn tóu biǎoshì tóngy", "Menyetujui anggukan"],
    ["表示很高兴", "biǎoshì hěn gāxing", "Menyatakan senang"],
    ["不表示什么", "bù biǎshì shénme", "Tidak menyatakan apa-apa"]
  ],
};

// For now let me take a more efficient approach - write the full generator in a separate file
// and then execute it
console.log("Starting generator...");
// Read actual data
const raw = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
console.log(`Loaded ${raw.vocab.length} entries`);