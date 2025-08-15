const CACHE_NAME = 'eva-crm-v1';
const urlsToCache = [
  '/',
  '/css/app.css',
  '/js/app.js',
  '/images/logo.svg',
  '/images/icon-192x192.png',
  '/images/icon-512x512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', (event) => {
  // No cachear requests a la API de sincronización
  if (event.request.url.includes('/api/sync')) {
    event.respondWith(fetch(event.request));
    return;
  }

  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        // Return cached version or fetch from network
        return response || fetch(event.request);
      })
  );
});

// Background sync para cambios offline
self.addEventListener('sync', (event) => {
  if (event.tag === 'background-sync') {
    event.waitUntil(syncPendingChanges());
  }
});

async function syncPendingChanges() {
  // Esta función se ejecutará cuando el navegador detecte conexión
  console.log('🔄 Background sync iniciado');
  
  // Notificar a la página principal
  const clients = await self.clients.matchAll();
  clients.forEach(client => {
    client.postMessage({
      type: 'SYNC_REQUESTED'
    });
  });
}

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
}); 