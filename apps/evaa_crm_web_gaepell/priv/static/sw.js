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
  // Solo interceptar peticiones GET del mismo origen
  if (event.request.method !== 'GET') {
    return;
  }
  
  // Ignorar peticiones de extensiones del navegador, chrome-extension, etc.
  const url = new URL(event.request.url);
  if (url.protocol === 'chrome-extension:' || 
      url.protocol === 'moz-extension:' || 
      url.protocol === 'safari-extension:' ||
      !url.href.startsWith(self.location.origin)) {
    return; // Dejar que el navegador maneje estas peticiones normalmente
  }
  
  // Manejar peticiones del mismo origen
  event.respondWith(
    fetch(event.request).catch(function(error) {
      console.log('Fetch failed:', error);
      // Fallback: devolver respuesta vacía o error
      return new Response('Network error', {
        status: 408,
        headers: { 'Content-Type': 'text/plain' }
      });
    })
  );
}); 