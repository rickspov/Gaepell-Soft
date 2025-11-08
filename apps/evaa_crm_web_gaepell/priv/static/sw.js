// Service Worker básico
self.addEventListener('install', function(event) {
  console.log('Service Worker instalado');
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  console.log('Service Worker activado');
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', function(event) {
  // Solo interceptar peticiones GET
  if (event.request.method !== 'GET') {
    return;
  }
  
  // Manejar peticiones correctamente sin only-if-cached
  event.respondWith(
    fetch(event.request, {
      cache: 'default',
      mode: 'same-origin'
    }).catch(function(error) {
      console.log('Fetch failed:', error);
      // Fallback: devolver respuesta vacía o error
      return new Response('Network error', {
        status: 408,
        headers: { 'Content-Type': 'text/plain' }
      });
    })
  );
}); 