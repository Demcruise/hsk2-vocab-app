import re, json, sys
import pypdf

PDF = r'C:\Users\PC\Documents\Kunkwan\HSK 1.0 V3\HSK1-Vocabulary-3.0.pdf'
OUT = r'C:\Users\PC\Documents\Kunkwan\HSK 2\V3\tools\hsk1_raw.json'

r = pypdf.PdfReader(PDF)
lines = []
for pg in r.pages:
    for ln in pg.extract_text().split('\n'):
        ln = ln.strip()
        if ln:
            lines.append(ln)

# Filter header/footer noise
noise = re.compile(r'^(HSK 3\.0|Level 1|Page \d|hanzistroke\.com|Vocabulary|HSK|Word|Pinyin|Definition|·)', re.I)
lines = [l for l in lines if not noise.match(l)]

# Parse triples: hanzi / pinyin / (pos.) definition
# A hanzi line contains at least one CJK char and nothing else (no latin except maybe -)
cjk = re.compile(r'[一-鿿]')
entries = []
i = 0
while i < len(lines):
    w = lines[i]
    if cjk.search(w) and not re.search(r'[a-zA-Zāáǎàēéěèīíǐìōóǒòūúǔùüǖǘǚǜ]', w):
        if i + 2 < len(lines):
            pinyin = lines[i + 1]
            defin = lines[i + 2]
            pos = ''
            m = re.match(r'^\(([^)]*)\)\s*(.*)$', defin)
            if m:
                pos, defin = m.group(1), m.group(2)
            entries.append({'hanzi': w.strip(), 'pinyin': pinyin.strip(), 'pos': pos.strip(), 'meaning': defin.strip()})
            i += 3
            continue
    i += 1

print('extracted:', len(entries))
for e in entries[:5]:
    print(e)
# sanity: any leftover hanzi lines unparsed?
json.dump(entries, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('written', OUT)
