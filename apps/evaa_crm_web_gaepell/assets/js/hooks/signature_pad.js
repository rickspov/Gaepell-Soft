const SignaturePad = {
  mounted() {
    this.canvas = this.el.querySelector('canvas');
    if (!this.canvas) {
      this.canvas = document.createElement('canvas');
      this.canvas.width = this.el.offsetWidth;
      this.canvas.height = this.el.offsetHeight;
      this.canvas.style.border = '1px solid #ccc';
      this.canvas.style.borderRadius = '4px';
      this.el.appendChild(this.canvas);
    }

    this.ctx = this.canvas.getContext('2d');
    this.isDrawing = false;
    this.lastX = 0;
    this.lastY = 0;

    this.setupCanvas();
    this.setupEventListeners();
  },

  setupCanvas() {
    this.ctx.strokeStyle = '#000';
    this.ctx.lineWidth = 2;
    this.ctx.lineCap = 'round';
    this.ctx.lineJoin = 'round';
  },

  setupEventListeners() {
    this.canvas.addEventListener('mousedown', this.startDrawing.bind(this));
    this.canvas.addEventListener('mousemove', this.draw.bind(this));
    this.canvas.addEventListener('mouseup', this.stopDrawing.bind(this));
    this.canvas.addEventListener('mouseout', this.stopDrawing.bind(this));

    // Touch events for mobile
    this.canvas.addEventListener('touchstart', this.handleTouch.bind(this));
    this.canvas.addEventListener('touchmove', this.handleTouch.bind(this));
    this.canvas.addEventListener('touchend', this.stopDrawing.bind(this));

    // Clear button
    const clearBtn = document.getElementById('clear-signature');
    if (clearBtn) {
      clearBtn.addEventListener('click', this.clearCanvas.bind(this));
    }

    // Save button
    const saveBtn = document.getElementById('save-signature');
    if (saveBtn) {
      saveBtn.addEventListener('click', this.saveSignature.bind(this));
    }
  },

  startDrawing(e) {
    this.isDrawing = true;
    const rect = this.canvas.getBoundingClientRect();
    this.lastX = e.clientX - rect.left;
    this.lastY = e.clientY - rect.top;
  },

  draw(e) {
    if (!this.isDrawing) return;

    const rect = this.canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    this.ctx.beginPath();
    this.ctx.moveTo(this.lastX, this.lastY);
    this.ctx.lineTo(x, y);
    this.ctx.stroke();

    this.lastX = x;
    this.lastY = y;
  },

  stopDrawing() {
    this.isDrawing = false;
  },

  handleTouch(e) {
    e.preventDefault();
    const touch = e.touches[0];
    const mouseEvent = new MouseEvent(e.type === 'touchstart' ? 'mousedown' : 
                                     e.type === 'touchmove' ? 'mousemove' : 'mouseup', {
      clientX: touch.clientX,
      clientY: touch.clientY
    });
    this.canvas.dispatchEvent(mouseEvent);
  },

  clearCanvas() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
  },

  saveSignature() {
    const signatureData = this.canvas.toDataURL('image/png');
    this.pushEvent('save_signature', { signature: signatureData });
  }
};

export default SignaturePad;
