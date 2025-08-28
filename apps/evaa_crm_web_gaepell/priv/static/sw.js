// Service Worker básico
self.addEventListener('install', function(event) {
  console.log('Service Worker instalado');
});

self.addEventListener('activate', function(event) {
  console.log('Service Worker activado');
});

self.addEventListener('fetch', function(event) {
  // Interceptar peticiones si es necesario
  event.respondWith(fetch(event.request));
}); 