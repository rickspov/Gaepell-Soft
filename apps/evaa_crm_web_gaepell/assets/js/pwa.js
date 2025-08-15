// PWA Service Worker Registration
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function() {
    navigator.serviceWorker.register('/sw.js')
      .then(function(registration) {
        console.log('SW registered: ', registration);
      })
      .catch(function(registrationError) {
        console.log('SW registration failed: ', registrationError);
      });
  });
}

// PWA Install Prompt
let deferredPrompt;
window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  deferredPrompt = e;
});

// PWA Update Available
window.addEventListener('sw-update-found', () => {
  console.log('New version available');
});

// Mobile navigation handler
function toggleMobileNav() {
  const sidebar = document.querySelector('.sidebar');
  if (sidebar) {
    sidebar.classList.toggle('open');
  }
}

// Close mobile nav when clicking outside
document.addEventListener('click', (e) => {
  const sidebar = document.querySelector('.sidebar');
  const mobileNavToggle = document.querySelector('.mobile-nav-toggle');
  
  if (sidebar && sidebar.classList.contains('open') && 
      !sidebar.contains(e.target) && 
      !mobileNavToggle?.contains(e.target)) {
    sidebar.classList.remove('open');
  }
});

// Handle orientation change
window.addEventListener('orientationchange', () => {
  setTimeout(() => {
    // Recalculate any layout-dependent elements
    window.dispatchEvent(new Event('resize'));
  }, 100);
});

// Prevent pull-to-refresh on mobile
let startY = 0;
let currentY = 0;

document.addEventListener('touchstart', (e) => {
  startY = e.touches[0].pageY;
});

document.addEventListener('touchmove', (e) => {
  currentY = e.touches[0].pageY;
  
  // Prevent pull-to-refresh when at the top
  if (window.scrollY === 0 && currentY > startY) {
    e.preventDefault();
  }
}, { passive: false }); 