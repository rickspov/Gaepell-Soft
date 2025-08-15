// Offline Sync Handler
class OfflineSync {
  constructor() {
    this.syncQueue = [];
    this.isOnline = navigator.onLine;
    this.init();
  }

  init() {
    window.addEventListener('online', () => {
      this.isOnline = true;
      this.processQueue();
    });

    window.addEventListener('offline', () => {
      this.isOnline = false;
    });
  }

  addToQueue(action) {
    this.syncQueue.push(action);
    if (this.isOnline) {
      this.processQueue();
    }
  }

  processQueue() {
    if (!this.isOnline || this.syncQueue.length === 0) return;

    while (this.syncQueue.length > 0) {
      const action = this.syncQueue.shift();
      this.executeAction(action);
    }
  }

  executeAction(action) {
    // Execute pending actions when back online
    console.log('Executing offline action:', action);
  }
  }

// Initialize offline sync
window.offlineSync = new OfflineSync();