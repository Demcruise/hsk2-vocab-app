// Kunkwan HSK sticker set — drawn on the fun-isometric kit.
import { VIEWS, ellipse, line, onFace, pill, poly, rect, ring, spark, star } from './fun'
import { bob, drift, float, glint, hop, sway, twinkle, wobble } from './motions'
import type { Icon, Layer, Motion } from './fun'

export { play, paint, draw, PALETTES, RISO } from './fun'

const LINE = 5
const { tilt: FACE, extrude: EXT } = VIEWS.right

// white sparkle riding a parent layer
const glow = (parent: string, p: readonly [number, number], r: number, m: Motion | ReadonlyArray<Motion>, extra: { ip?: number; op?: number } = {}): Layer => ({
  parent,
  a: p,
  p,
  m,
  ...extra,
  shapes: [{ d: spark(p[0], p[1], r), fill: 'white' }],
})

/** Magnifier leaning over a sheet of notes — the "nothing found" sticker. */
export const loupe: Icon = {
  name: 'loupe',
  frames: 180,
  line: LINE,
  extrude: EXT,
  still: 40,
  layers: [
    {
      id: 'paper',
      p: [238, 268],
      tilt: FACE,
      m: bob,
      shapes: [
        { d: rect(-96, -116, 192, 232, 14), fill: 'white', depth: 0.8 },
        { d: line([-62, -72], [50, -72]), line: 5 },
        { d: line([-62, -40], [62, -40]), line: 5 },
        { d: line([-62, -8], [20, -8]), line: 5 },
        { d: line([-62, 24], [44, 24]), line: 5 },
        { d: poly([[-96, 66], [-46, 116], [-96, 116]], 10), fill: 'tint', depth: 0.2 },
      ],
    },
    {
      id: 'lens',
      parent: 'paper',
      a: [0, 0],
      p: [34, 30],
      m: [{ p: [[0, [0, 0], [0.33, 0, 0.67, 1]], [44, [-26, -30], [0.33, 0, 0.67, 1]], [96, [-10, 18], [0.33, 0, 0.67, 1]], [150, [0, 0]]] }, { r: [[0, 0, [0.33, 0, 0.67, 1]], [70, 7, [0.33, 0, 0.67, 1]], [130, 0]] }],
      shapes: [
        { d: poly([[30, 44], [52, 26], [108, 86], [86, 104]], 12), fill: 'main', depth: 0.7 },
        { d: ring(0, 0, 64, 44), fill: 'white', depth: 1 },
        { d: ellipse(0, 0, 44), fill: 'tint', depth: 0.15 },
        { d: ellipse(0, 0, 30), fill: 'white' },
      ],
    },
    glow('lens', [-34, -40], 20, twinkle(52), { ip: 52 }),
  ],
}

/** A sprout in a pot — the "nothing memorized yet" sticker. */
export const sprout: Icon = {
  name: 'sprout',
  frames: 180,
  line: LINE,
  extrude: EXT,
  still: 90,
  layers: [
    {
      id: 'pot',
      p: [250, 300],
      tilt: FACE,
      m: bob,
      shapes: [
        { d: poly([[-72, -34], [72, -34], [52, 68], [-52, 68]], 10), fill: 'hot', depth: 1 },
        { d: rect(-82, -56, 164, 26, 10), fill: 'deep', depth: 0.8 },
      ],
    },
    {
      parent: 'pot',
      a: [0, -30],
      p: [0, -30],
      m: [{ r: [[0, 0, [0.33, 0, 0.67, 1]], [80, -7, [0.33, 0, 0.67, 1]], [160, 0]], loop: 160 }],
      shapes: [
        { d: 'M0 -50Q8 -84 0 -110', line: 5, round: true },
        { d: 'M0 -104C-30 -120 -54 -112 -60 -86C-34 -74 -8 -82 0 -104Z', fill: 'ok', depth: 0.5 },
        { d: 'M0 -110C30 -128 56 -118 62 -90C36 -78 8 -86 0 -110Z', fill: 'ok', depth: 0.5 },
      ],
    },
    glow('pot', [-76, -70], 22, twinkle(70), { ip: 70 }),
  ],
}

/** Medal on a ribbon — lesson complete. */
export const medal: Icon = {
  name: 'medal',
  frames: 180,
  line: LINE,
  extrude: EXT,
  still: 94,
  layers: [
    {
      id: 'medal',
      p: [250, 286],
      tilt: FACE,
      m: hop,
      shapes: [
        { d: poly([[-46, -148], [-12, -148], [-34, -68], [-66, -68]], 8), fill: 'hot', depth: 0.4 },
        { d: poly([[12, -148], [46, -148], [66, -68], [34, -68]], 8), fill: 'deep', depth: 0.4 },
        { d: ring(0, 10, 92, 68), fill: 'gold', depth: 1 },
        { d: ellipse(0, 10, 68), fill: 'gold', depth: 0.4 },
        { d: star(0, 12, 46, 0.44, 5, 5), fill: 'white', depth: 0.2 },
      ],
    },
    glow('medal', [-88, -58], 24, twinkle(46), { ip: 46 }),
    glow('medal', [92, 66], 20, twinkle(62), { ip: 62 }),
  ],
}

/** A hanzi flashcard — the character 中 boxed with its vertical stroke. */
export const tile: Icon = {
  name: 'tile',
  frames: 168,
  line: LINE,
  extrude: EXT,
  still: 84,
  layers: [
    {
      id: 'card',
      p: [250, 258],
      tilt: FACE,
      m: wobble,
      shapes: [
        { d: rect(-88, -114, 176, 228, 18), fill: 'white', depth: 1 },
        { d: rect(-88, -114, 176, 30, [18, 18, 0, 0]), fill: 'main', depth: 0.2 },
        { d: rect(-36, -36, 72, 74, 8), line: 5 },
        { d: line([0, -62], [0, 50]), line: 5, round: true },
        { d: pill(-44, 68, 88, 16), fill: 'tint', depth: 0.2 },
      ],
    },
    glow('card', [96, -128], 22, twinkle(58), { ip: 58 }),
  ],
}
