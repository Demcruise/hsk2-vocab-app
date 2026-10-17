/* Service worker for the Kunkwan HSK 2 app.
 *
 * Strategy
 *   - navigations  -> network first, fall back to the cached shell (offline use)
 *   - other GETs   -> cache first, then network (and populate the cache)
 *
 * Bump VERSION when the app shell itself changes in a way that must be
 * re-precached; normal `index.html` edits are picked up by the network-first
 * navigation handler.
 */
const VERSION = 'v5';
const CACHE = `khsk2-${VERSION}`;

const APP_SHELL = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/icon-maskable-192.png',
  './icons/icon-maskable-512.png',
  './icons/apple-touch-icon.png',
  './icons/favicon-32.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(CACHE)
      .then((cache) => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
      .catch(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  let url;
  try {
    url = new URL(req.url);
  } catch {
    return;
  }
  if (url.origin !== self.location.origin) return;

  // Page loads: try the network so updates land, fall back to cache offline.
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches
            .open(CACHE)
            .then((c) => c.put('./index.html', copy))
            .catch(() => {});
          return res;
        })
        .catch(() =>
          caches
            .match('./index.html')
            .then((r) => r || caches.match('./'))
            .then((r) => r || new Response('Offline', { status: 503, statusText: 'Offline' }))
        )
    );
    return;
  }

  // Everything else: cache first.
  event.respondWith(
    caches.match(req).then((cached) => {
      if (cached) return cached;
      return fetch(req).then((res) => {
        if (res && res.status === 200 && res.type === 'basic') {
          const copy = res.clone();
          caches
            .open(CACHE)
            .then((c) => c.put(req, copy))
            .catch(() => {});
        }
        return res;
      });
    })
  );
});
