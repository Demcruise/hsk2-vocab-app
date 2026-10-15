/**
 * make-icons.mjs — generate PWA icons for the Kunkwan HSK 2 app.
 *
 * Pure Node.js (no dependencies). Renders a green rounded square with a white
 * "中" glyph and writes PNGs into ../icons/.
 *
 * Usage:  node tools/make-icons.mjs
 */
import zlib from 'node:zlib';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT_DIR = path.join(__dirname, '..', 'icons');

/* ---------- PNG encoder (RGBA8, no dependencies) ---------- */

const CRC_TABLE = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c;
  }
  return t;
})();

function crc32(buf) {
  let c = -1;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ -1) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body), 0);
  return Buffer.concat([len, body, crc]);
}

function encodePNG(width, height, rgba) {
  const stride = width * 4;
  const raw = Buffer.alloc((stride + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (stride + 1)] = 0; // filter: none
    rgba.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // colour type: RGBA
  ihdr[10] = 0; // compression
  ihdr[11] = 0; // filter
  ihdr[12] = 0; // interlace
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

/* ---------- geometry ---------- */

// "中" drawn inside a unit square [0,1] x [0,1].
function glyphCoverage(u, v) {
  const L = 0.20, R = 0.80, T = 0.30, B = 0.80, TH = 0.10;
  const inFrame =
    u >= L && u <= R && v >= T && v <= B &&
    !(u >= L + TH && u <= R - TH && v >= T + TH && v <= B - TH);
  const inBar = u >= 0.45 && u <= 0.55 && v >= 0.08 && v <= 0.95;
  return inFrame || inBar;
}

function inRoundRect(x, y, n, r) {
  const cx = Math.min(Math.max(x, r), n - r);
  const cy = Math.min(Math.max(y, r), n - r);
  const dx = x - cx, dy = y - cy;
  return dx * dx + dy * dy <= r * r;
}

const hex = (h) => [
  parseInt(h.slice(1, 3), 16),
  parseInt(h.slice(3, 5), 16),
  parseInt(h.slice(5, 7), 16),
];

const BG_TOP = hex('#77DC28');
const BG_BOTTOM = hex('#46AE00');
const FG = [255, 255, 255];

/**
 * @param {number} n   output size in px
 * @param {object} o   { radius: fraction of n, glyphScale: fraction of n, maskable: bool }
 */
function makeIcon(n, { radius = 0.20, glyphScale = 0.80, maskable = false } = {}) {
  const S = 4; // supersampling
  const W = n * S;
  const r = radius * n;
  const g = glyphScale * n;
  const gx0 = (n - g) / 2;
  const gy0 = (n - g) / 2;

  const cover = new Float32Array(n * n); // glyph coverage per pixel
  const alpha = new Float32Array(n * n); // shape coverage per pixel

  for (let sy = 0; sy < W; sy++) {
    const py = (sy + 0.5) / S;
    const row = (sy / S) | 0;
    for (let sx = 0; sx < W; sx++) {
      const px = (sx + 0.5) / S;
      const col = (sx / S) | 0;
      const i = row * n + col;

      if (!maskable && !inRoundRect(px, py, n, r)) continue;
      alpha[i] += 1 / (S * S);

      const u = (px - gx0) / g;
      const v = (py - gy0) / g;
      if (u >= 0 && u <= 1 && v >= 0 && v <= 1 && glyphCoverage(u, v)) {
        cover[i] += 1 / (S * S);
      }
    }
  }

  const rgba = Buffer.alloc(n * n * 4);
  for (let y = 0; y < n; y++) {
    const t = n === 1 ? 0 : y / (n - 1);
    const bg = [
      BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * t,
      BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * t,
      BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * t,
    ];
    for (let x = 0; x < n; x++) {
      const i = y * n + x;
      const k = cover[i];
      const o = i * 4;
      rgba[o] = Math.round(bg[0] + (FG[0] - bg[0]) * k);
      rgba[o + 1] = Math.round(bg[1] + (FG[1] - bg[1]) * k);
      rgba[o + 2] = Math.round(bg[2] + (FG[2] - bg[2]) * k);
      rgba[o + 3] = Math.round(alpha[i] * 255);
    }
  }
  return encodePNG(n, n, rgba);
}

/* ---------- output ---------- */

fs.mkdirSync(OUT_DIR, { recursive: true });

const jobs = [
  ['icon-192.png', 192, { radius: 0.20, glyphScale: 0.80 }],
  ['icon-512.png', 512, { radius: 0.20, glyphScale: 0.80 }],
  ['icon-maskable-192.png', 192, { maskable: true, glyphScale: 0.58 }],
  ['icon-maskable-512.png', 512, { maskable: true, glyphScale: 0.58 }],
  ['apple-touch-icon.png', 180, { radius: 0.20, glyphScale: 0.80 }],
  ['favicon-32.png', 32, { radius: 0.18, glyphScale: 0.84 }],
];

for (const [name, size, opts] of jobs) {
  const png = makeIcon(size, opts);
  fs.writeFileSync(path.join(OUT_DIR, name), png);
  console.log(`${name.padEnd(24)} ${size}x${size}  ${(png.length / 1024).toFixed(1)} KB`);
}

console.log('\nIcons written to', OUT_DIR);
