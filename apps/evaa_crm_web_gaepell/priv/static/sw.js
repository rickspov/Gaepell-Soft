// Service Worker básico para EvaaCRM
const CACHE_NAME = 'evaa-crm-v1';
const urlsToCache = [
  '/',
  '/css/app.css',
  '/js/app.js'
];

self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        return cache.addAll(urlsToCache);
      })
  );
});

self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.match(event.request)
      .then(function(response) {
        if (response) {
          return response;
        }
        return fetch(event.request);
          }
    )
  );
}); 