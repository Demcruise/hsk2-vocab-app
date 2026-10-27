# Kunkwan HSK — dev notes

Single-file PWA (`index.html`) + Flutter app (`mobile/`). Vocab data is embedded in `index.html` (HSK1 `khsk1`, HSK2 `khsk2` storage buckets).

## Verify

- PWA smoke test: serve root over http, then `node tools/_smoke.js` (Puppeteer, 42 checks).
- Flutter: `cd mobile && dart analyze lib/ui`
- Layout stress: `tools/_break.js`-style scripts (write temp scripts outside `tools/_*` — that pattern is gitignored but read-blocked).

## Service worker

Bump `VERSION` in `sw.js` whenever the app shell or `index.html` behavior changes.

## Stickers (fun-isometric)

- Sources: `stickers/icons.ts` (4 icons: loupe, sprout, medal, tile) on the kit runtime `stickers/fun.ts` + `stickers/motions.ts`.
- Rebuild web bundle: `npx esbuild stickers/icons.ts --bundle --format=esm --outfile=stickers/stickers.js`
- Re-export Flutter sprite sheets: `node tools/fi/fiexport.js` → `mobile/assets/stickers/*.png` (160px cells, every 4th frame = 15fps). Update `frames`/`stillFrame` in `mobile/lib/ui/fi_sticker.dart` if icons change.
- Web usage: `<canvas class="fi" data-icon="loupe" aria-hidden="true">` + `FI.mount(root)`; `data-once="1"` for play-once. Flutter usage: `FiSticker.loupe()` / `.sprout()` / `.tile()` / `.medal()` (honors `disableAnimations`).
- Attribution required: "Made with fun-isometric by Kelvin Adithya (x.com/KelvinAdithya), heavily inspired by Slush (slush.app), more at skills.klvn.dev/fun-isometric."
