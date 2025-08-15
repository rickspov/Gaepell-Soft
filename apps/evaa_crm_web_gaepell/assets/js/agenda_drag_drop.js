// Agenda Drag and Drop functionality
// Un solo archivo robusto para todas las vistas

// Hook para el tab Equipo (solo vertical)
window.AgendaDragDropEq = {
  mounted() {
    this.initEqDragDrop();
  },
  updated() {
    this.initEqDragDrop();
  },
  initEqDragDrop() {
    const activities = this.el.querySelectorAll('.activity-item');
    const slots = this.el.querySelectorAll('.agenda-eq-slot');
    let dragged = null;
    let draggedSpecialist = null;
    // Limpiar event listeners previos
    activities.forEach(item => {
      item.removeEventListener('dragstart', this.handleEqDragStart);
      item.removeEventListener('dragend', this.handleEqDragEnd);
      item.removeEventListener('mouseenter', this.handleActivityMouseEnter);
      item.removeEventListener('mouseleave', this.handleActivityMouseLeave);
    });
    activities.forEach(item => {
      item.setAttribute('draggable', true);
      item.addEventListener('dragstart', this.handleEqDragStart.bind(this));
      item.addEventListener('dragend', this.handleEqDragEnd.bind(this));
      item.addEventListener('mouseenter', this.handleActivityMouseEnter.bind(this));
      item.addEventListener('mouseleave', this.handleActivityMouseLeave.bind(this));
    });
    slots.forEach(slot => {
      slot.removeEventListener('dragover', this.handleEqDragOver);
      slot.removeEventListener('dragleave', this.handleEqDragLeave);
      slot.removeEventListener('drop', this.handleEqDrop);
    });
    slots.forEach(slot => {
      slot.setAttribute('tabindex', '-1');
      slot.addEventListener('dragover', this.handleEqDragOver.bind(this));
      slot.addEventListener('dragleave', this.handleEqDragLeave.bind(this));
      slot.addEventListener('drop', this.handleEqDrop.bind(this));
    });
  },
  handleEqDragStart(e) {
    e.stopPropagation();
    const item = e.target;
    this.dragged = item;
    this.draggedSpecialist = item.getAttribute('data-specialist-id');
    this.draggedHour = item.getAttribute('data-hour');
    this.draggedMinute = item.getAttribute('data-minute');
    item.classList.add('dragging-eq');
  },
  handleEqDragEnd(e) {
    e.stopPropagation();
    const item = e.target;
    this.dragged = null;
    this.draggedSpecialist = null;
    this.draggedHour = null;
    this.draggedMinute = null;
    item.classList.remove('dragging-eq');
    this.el.querySelectorAll('.drop-zone-active').forEach(slot => {
      slot.classList.remove('drop-zone-active');
    });
  },
  handleEqDragOver(e) {
    e.preventDefault();
    e.stopPropagation();
    if (!this.dragged) return;
    const slot = e.currentTarget;
    if (slot.getAttribute('data-specialist-id') === this.draggedSpecialist) {
      slot.classList.add('drop-zone-active');
    } else {
      slot.classList.remove('drop-zone-active');
    }
  },
  handleEqDragLeave(e) {
    e.stopPropagation();
    const slot = e.currentTarget;
    slot.classList.remove('drop-zone-active');
  },
  handleActivityMouseEnter(e) {
    const activity = e.currentTarget;
    const slotId = activity.getAttribute('data-slot-id');
    const status = activity.getAttribute('data-activity-status');
    if (slotId && status) {
      const slot = document.getElementById(slotId);
      if (slot) {
        const statusText = this.getStatusText(status);
        slot.setAttribute('data-tooltip-status', `Estado: ${statusText}`);
        slot.classList.add('show-status-tooltip');
      }
    }
  },
  handleActivityMouseLeave(e) {
    const activity = e.currentTarget;
    const slotId = activity.getAttribute('data-slot-id');
    if (slotId) {
      const slot = document.getElementById(slotId);
      if (slot) {
        slot.classList.remove('show-status-tooltip');
        slot.removeAttribute('data-tooltip-status');
      }
    }
  },
  getStatusText(status) {
    const statusMap = {
      'pending': 'Pendiente',
      'in_progress': 'En progreso',
      'completed': 'Completado',
      'cancelled': 'Cancelado'
    };
    return statusMap[status] || 'Desconocido';
  },
  handleEqDrop(e) {
    e.preventDefault();
    e.stopPropagation();
    if (!this.dragged) return;
    const slot = e.currentTarget;
    slot.classList.remove('drop-zone-active');
    if (slot.getAttribute('data-specialist-id') === this.draggedSpecialist) {
      const activityId = this.dragged.getAttribute('data-activity-id');
      const hour = slot.getAttribute('data-hour');
      const minute = slot.getAttribute('data-minute');
      const date = slot.getAttribute('data-date');
      if (activityId && hour && date) {
        let timeString;
        if (minute && minute !== 'null' && minute !== 'undefined') {
          timeString = `${hour}:${minute.padStart(2, '0')}`;
        } else {
          timeString = `${hour}:00`;
        }
        if (this.pushEvent) {
          this.pushEvent('move_activity', {
            activity_id: activityId,
            new_date: date,
            new_time: timeString
          });
        }
      }
    } else {
      slot.classList.add('drop-zone-error');
      setTimeout(() => slot.classList.remove('drop-zone-error'), 500);
    }
  }
};

// Hook principal para drag and drop y tooltip en agenda (día, semana, mes, lista)
window.AgendaDragDrop = {
  mounted() {
    this.initDragAndDrop();
    this.handleEvent("update", () => setTimeout(() => this.initDragAndDrop(), 100));
  },
  initDragAndDrop() {
    const activities = this.el.querySelectorAll('.activity-item');
    const timeSlots = this.el.querySelectorAll('.time-slot');
    activities.forEach(activity => {
      activity.setAttribute('draggable', true);
      activity.classList.add('drag-ready');
      activity.style.cursor = 'grab';
      // DRAG EVENTS
      activity.addEventListener('dragstart', (e) => {
        window.draggedActivityId = activity.getAttribute('data-activity-id');
        activity.style.opacity = '0.5';
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/html', activity.outerHTML);
      });
      activity.addEventListener('dragend', (e) => {
        window.draggedActivityId = null;
        activity.style.opacity = '1';
        this.el.querySelectorAll('.drop-zone-active').forEach(zone => {
          zone.classList.remove('drop-zone-active');
        });
      });
      // HOVER EVENTS
      activity.addEventListener('mouseenter', this.handleActivityMouseEnter.bind(this));
      activity.addEventListener('mouseleave', this.handleActivityMouseLeave.bind(this));
    });
    timeSlots.forEach(slot => {
      slot.addEventListener('dragover', this.handleDragOver.bind(this));
      slot.addEventListener('drop', this.handleDrop.bind(this));
      slot.addEventListener('dragenter', this.handleDragEnter.bind(this));
      slot.addEventListener('dragleave', this.handleDragLeave.bind(this));
    });
  },
  handleDragOver(e) {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
  },
  handleDrop(e) {
    e.preventDefault();
    const dropZone = e.target.closest('.time-slot');
    let activityId = window.draggedActivityId;
    if (!activityId) {
      const draggedElement = this.el.querySelector('.activity-item[style*="opacity: 0.5"]');
      if (draggedElement) {
        activityId = draggedElement.getAttribute('data-activity-id');
      }
    }
    if (!activityId) return;
    const date = dropZone.getAttribute('data-date');
    const time = dropZone.getAttribute('data-time');
    if (this.pushEvent) {
      this.pushEvent('move_activity', { activity_id: activityId, new_date: date, new_time: time });
    }
    dropZone.classList.remove('drop-zone-active');
  },
  handleDragEnter(e) {
    e.preventDefault();
    const dropZone = e.target.closest('.time-slot');
    if (dropZone) dropZone.classList.add('drop-zone-active');
  },
  handleDragLeave(e) {
    const dropZone = e.target.closest('.time-slot');
    if (dropZone) {
      const rect = dropZone.getBoundingClientRect();
      const x = e.clientX, y = e.clientY;
      if (x < rect.left || x > rect.right || y < rect.top || y > rect.bottom) {
        dropZone.classList.remove('drop-zone-active');
      }
    }
  },
  // --- HOVER/TOOLTIP LOGIC ---
  handleActivityMouseEnter(e) {
    const activity = e.currentTarget;
    const slotId = activity.getAttribute('data-slot-id');
    const status = activity.getAttribute('data-activity-status');
    if (slotId && status) {
      const slot = document.getElementById(slotId);
      if (slot) {
        const statusText = this.getStatusText(status);
        slot.setAttribute('data-tooltip-status', `Estado: ${statusText}`);
        slot.classList.add('show-status-tooltip');
      }
    }
  },
  handleActivityMouseLeave(e) {
    const activity = e.currentTarget;
    const slotId = activity.getAttribute('data-slot-id');
    if (slotId) {
      const slot = document.getElementById(slotId);
      if (slot) {
        slot.classList.remove('show-status-tooltip');
        slot.removeAttribute('data-tooltip-status');
      }
    }
  },
  getStatusText(status) {
    const statusMap = {
      'pending': 'Pendiente',
      'in_progress': 'En progreso',
      'completed': 'Completado',
      'cancelled': 'Cancelado'
    };
    return statusMap[status] || 'Desconocido';
  }
}; 