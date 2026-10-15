const fs = require('fs');
const dataPath = 'C:\\Users\\PC\\Documents\\Kunkwan\\HSK 2\\V3\\vocab_data.json';
const data = JSON.parse(fs.readFileSync(dataPath, 'utf8'));

const stsp = { '长':0x2ED3,'见':0x2EC5,'车':0x2ECB,'门':0x2ED4,'黄':0x2EE9,'角':0x2EC6,'鸟':0x2EE6,'飞':0x2EDC,'青':0x2ED8,'食':0x2EDD,'西':0x2EC4,'风':0x2EDB,'鱼':0x2EE5 };
const fix = (s,h) => { let r=s; if(!h)return r; for(const c of h) { const cp=c.codePointAt(0); if(cp>0x2E00&&cp<0x2FD0) { for(const[k,v]of Object.entries(stsp)) if(v===cp) { r=r.split(k).join(c); break; } } } return r; };

const S = {};

function add(id, s1, p1, i1, s2, p2, i2, s3, p3, i3) {
  S[id] = [[s1,p1,i1],[s2,p2,i2],[s3,p3,i3]];
}

// ===== ID 1-100 =====
add(1,"你好啊！","nǐ hǎo a!","Halo!","好啊，一起去吃饭吧。","hǎo a yìqǐ chīfàn ba","Baiklah ayo kita makan.","真漂亮啊！","zhēn piàoliang a!","Sungguh cantik])
((2,"他们的爱情很美好。","他men de àiqíng hěn měihǎ,","Cinta mereka indah."],["爱情让人开心。","àiqíng ràng rén kāixī,","Cinta buat senang."],["我相信爱情。","w xiāngxìn àiqíng,","Saya percaya cinta."])
add(3["我爱人在家。","wǒ àiren zài jiā.","Pasangan di rumah."],["我爱人照顾我。","wǒ àiren zhàogu wǒ.","Pasangan rawat saya."],["我和爱人去看电影。","wǒ hé àiren qù kàn diànyǐng.","Saya dan pasangan nonton film."])
add(4,"请安静。","qǐng ānjìng.","Mohon tenang.","图书馆很安静。","túshūguǎn hěn ānjìng.","Perpus tenang.","公园里很安静。","gōngyuán lǐ hěn ānjìng.","Taman tenang."])
add(5,"开车要注意安全。","kāichē yào zhùyì ānquán.","Setir harus hati-hati.","这里很安全。","zhèlǐ hěn ānquán.","Di sini aman.","安全第一。","ānquán dìyī.","Keselamatan utama."])
add(6,"我喜欢白色。","wǒ xǐhuan báisè.","Saya suka putih.","白色的花很漂亮。","báisè de huā hěn piàoliang.","Bunga putih cantik.","她穿白色衣服。","tā chuān báisè yīfu.","Dia pakai baju putih."])
add(7,"他是班长。","tā shì bānzhǎng.","Dia ketua kelas.","班长帮老师做事。","bānzhǎng bāng lǎoshī zuò shì.","Ketu kelas bantu guru.","我们选他当班长。","wǒmen xuǎn tā dāng bānzhǎng.","Pilih dia jadi ketua."])
add(8,"我来办这件事。","wǒ lái bàn zhè jiàn shì.","Saya urus ini.","你去办吧。","nǐ qù bàn ba.","Kamu urus saja.","怎么办？","zěnme bàn?","Bagaimana?"])
add(9,"我有办法。","wǒ yǒu bànfǎ.","Saya punya cara.","这个办法很好。","zhège bànfǎ hěn hǎo.","Cara ini bagus.","你想办法吧。","nǐ xiǎng bànfǎ ba.","Kamu cari cara."])
add(10,"老师在办公室。","lǎoshī zài bàngōngshì.","Guru di kantor.","办公室很大。","bàngōngshì hěn dà.","Kantor besar.","去办公室找你。","qù bàngōngshì zhǎo nǐ.","Ke kantor cari kamu."])
add(11,"他半夜才回家。","tā bànyè cái huíjiā.","Pulang tengah malam.","半夜还在学习。","bànyè hái zài xuéxí.","Msh belajar tengah malam.","半夜不要大声说话。","bànyè búyào dàshēng shuōhuà.","Jgn keras tengah malam."])
add(12,"谢谢你帮助我。","xièxie nǐ bāngzhù wǒ.","Makasih bantu saya.","我需要帮助。","wǒ xūyào bāngzhù.","Saya butuh bantuan.","朋友互相帮助。","péngyou hùxiāng bāngzhù.","Teman saling bantu."])
add(13,"我吃饱了。","wǒ chībǎo le.","Saya kenyang.","你吃饱了吗？","nǐ chībǎo le ma?","Kamu kenyang?","今天吃得很饱。","jīntiān chī de hěn bǎo.","Makan kenyang."])
add(14,"我要报名学汉语。","wǒ yào bàomíng xué hànyǔ.","Saya daftar Mandarin.","报名时间到了。","bàomíng shíjiān dào le.","Waktu daftar tiba.","你报名了吗？","nǐ bàomíng le ma?","Kamu daftar?"])
add(15,"爸爸在看报纸。","bàba zài kàn bàozhǐ.","Ayah baca koran.","报纸是今天的。","bàozhǐ shì jīntiān de.","Koran hari ini.","我不常看报纸。","wǒ bù cháng kàn bàozhǐ.","Saya jarang baca koran."])
add(16,"北京在北方。","Běijīng zài běifāng.","Beijing di utara.","北方冬天很冷。","běifāng dōngtiān hěn lěng.","Utara dingin.","他来自北方。","tā láizì běifāng.","Dia dari utara."])
add(17,"他背着书包。","tā bēi zhe shūbāo.","Dia bawa tas.","他的背很疼。","tā de bèi hěn téng.","Punggung sakit.","背了很多书。","bēi le hěnduō shū.","Bawa banyak buku."])
add(18,"他用笔写字。","tā yòng bǐ xiě zì.","Tulis dg pena.","给我一支笔。","gěi wǒ yì zhī bǐ.","Beri satu pena.","一笔钱。","yì bǐ qián.","Sejumlah uang."])
add(19,"他做笔记。","tā zuò bǐjì.","Dia buat catatan.","我看你的笔记。","wǒ kàn nǐ de bǐjì.","Saya lihat catatanmu.","笔记很有用。","bǐjì hěn yǒuyòng.","Catatan berguna."])
add(20,"笔记本是我的。","bǐjìběn shì wǒ de.","Buku catatanku.","买了一个笔记本。","mǎi le yí ge bǐjìběn.","Beli satu buku catatan.","笔记本很好用。","bǐjìběn hěn hǎo yòng.","Buku catatan bagus."])
add(21,"比如苹果和西瓜。","bǐrú píngguǒ hé xīguā.","Misal apel dan semangka.","比如，可以去公园。","bǐrú, kěyǐ qù gōngyuán.","Misal ke taman.","喜欢运动比如跑步。","xǐhuan yùndòng bǐrú pǎobù.","Suka olahraga misal lari."])
add(22,"比如说可以学汉语。","bǐrúshuō kěu hànyǔ.","Mis belajar Mandarin."],["比如说要多练习。","bǐrúshuō yào duō liànxí.","Mis harus banyak latihan."],["比如说早上跑步好。","bǐrúshuō zǎoshang pǎobù hǎo.","Mis pagi lari baik."])