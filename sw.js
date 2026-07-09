// bib Service Worker — PWA offline support
// Strategy: cache shell on install, cache Bible data on fetch, serve offline
// v14 (2026-07-08): Tailwind pré-compilado + fontes self-hosted em /assets + /fonts —
// CDN (cdn.tailwindcss.com, fonts.g*) eliminado. Bug antigo: respostas cross-origin
// no-cors são opaque (r.ok=false) e NUNCA entravam no cache → offline ficava sem CSS.
const CACHE_NAME = 'bib-v14';
const SHELL_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/icon.svg',
  '/data/red-letter.json',
  '/assets/tw.css',
  '/assets/fonts.css',
  '/fonts/inter-400-latin.woff2',
  '/fonts/inter-400-latin-ext.woff2',
  '/fonts/inter-600-latin.woff2',
  '/fonts/inter-600-latin-ext.woff2',
  '/fonts/literata-400-latin.woff2',
  '/fonts/literata-400-latin-ext.woff2',
  '/fonts/literata-600-latin.woff2',
  '/fonts/literata-600-latin-ext.woff2',
  '/fonts/lora-400-latin.woff2',
  '/fonts/lora-400-latin-ext.woff2',
  '/fonts/lora-600-latin.woff2',
  '/fonts/lora-600-latin-ext.woff2',
  '/fonts/sourceserif4-400-latin.woff2',
  '/fonts/sourceserif4-400-latin-ext.woff2',
  '/fonts/sourceserif4-600-latin.woff2',
  '/fonts/sourceserif4-600-latin-ext.woff2',
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then(c => c.addAll(SHELL_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);

  // Skip non-GET
  if (e.request.method !== 'GET') return;

  // External API (bolls.life, gemini-proxy, qrserver): network-only, no cache
  if (url.hostname !== self.location.hostname) return;

  // Bible data + devotional: network-first, cache fallback (stale data OK offline)
  if (url.pathname.startsWith('/data/') || url.pathname.startsWith('/devotional/')) {
    e.respondWith(
      fetch(e.request).then(r => {
        if (r.ok) {
          const clone = r.clone();
          caches.open(CACHE_NAME).then(c => c.put(e.request, clone));
        }
        return r;
      }).catch(() => caches.match(e.request))
    );
    return;
  }

  // App shell (HTML, CSS, fontes, ícones): cache-first with network update
  e.respondWith(
    caches.match(e.request).then(cached => {
      const fetchPromise = fetch(e.request).then(r => {
        if (r.ok) {
          const clone = r.clone();
          caches.open(CACHE_NAME).then(c => c.put(e.request, clone));
        }
        return r;
      }).catch(() => cached);
      return cached || fetchPromise;
    })
  );
});
