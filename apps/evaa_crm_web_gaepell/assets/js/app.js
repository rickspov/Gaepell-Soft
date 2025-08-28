// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import Sortable from "sortablejs"

// Import agenda drag and drop functionality
import "./agenda_drag_drop.js"
// Import signature pad hook
import SignaturePad from "./hooks/signature_pad.js"

// Custom hook for document upload
const DocumentUpload = {
  mounted() {
    this.input = this.el;
    this.input.addEventListener('change', (e) => {
      const files = Array.from(e.target.files);
      files.forEach(file => {
        this.uploadFile(file);
      });
    });
  },

  uploadFile(file) {
    // Create a unique ref for this upload
    const ref = this.pushEventTo(this.el, "validate-upload", { file: file.name });
    
    // You can add progress tracking here if needed
    console.log(`Uploading ${file.name}...`);
  }
};

// Custom hook for document preview navigation
const DocumentPreview = {
  mounted() {
    this.handleKeydown = this.handleKeydown.bind(this);
    document.addEventListener('keydown', this.handleKeydown);
  },

  destroyed() {
    document.removeEventListener('keydown', this.handleKeydown);
  },

  handleKeydown(e) {
    // Only handle keys when the modal is open
    if (this.el.style.display !== 'none') {
      switch(e.key) {
        case 'ArrowLeft':
          e.preventDefault();
          this.pushEvent('keydown', { key: 'ArrowLeft' });
          break;
        case 'ArrowRight':
          e.preventDefault();
          this.pushEvent('keydown', { key: 'ArrowRight' });
          break;
        case 'Escape':
          e.preventDefault();
          this.pushEvent('keydown', { key: 'Escape' });
          break;
      }
    }
  }
};

// Custom hook for agenda drag and drop
const AgendaDragDrop = {
  mounted() {
    console.log('AgendaDragDrop hook mounted');
    this.initDragAndDrop();
    
    // Re-initialize when the view updates
    this.handleEvent("update", () => {
      console.log('AgendaDragDrop hook update event');
      setTimeout(() => this.initDragAndDrop(), 100);
    });
  },
  
  initDragAndDrop() {
    console.log('Initializing drag and drop from hook...');
    
    // Get all activity elements (draggable)
    const activities = this.el.querySelectorAll('.activity-item');
    const timeSlots = this.el.querySelectorAll('.time-slot');

    console.log('Found activities:', activities.length);
    console.log('Found time slots:', timeSlots.length);

    // Hacer todas las actividades inmediatamente arrastrables
    activities.forEach(activity => {
      activity.setAttribute('draggable', true);
      activity.classList.add('drag-ready');
      activity.style.cursor = 'grab';
      // Registrar el activityId en dragstart
      activity.addEventListener('dragstart', (e) => {
        window.draggedActivityId = activity.getAttribute('data-activity-id');
        activity.style.opacity = '0.5';
      });
      activity.addEventListener('dragend', (e) => {
        window.draggedActivityId = null;
        activity.style.opacity = '1';
      });
    });

    // Add drop event listeners to time slots
    timeSlots.forEach(slot => {
      slot.addEventListener('dragover', this.handleDragOver.bind(this));
      slot.addEventListener('drop', this.handleDrop.bind(this));
      slot.addEventListener('dragenter', this.handleDragEnter.bind(this));
      slot.addEventListener('dragleave', this.handleDragLeave.bind(this));
    });
  },

  handleDragStart(e) {
    console.log('Drag start:', e.target);
    e.target.style.opacity = '0.5';
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/html', e.target.outerHTML);
    
    // Store the activity ID globally for easier access
    window.draggedActivityId = e.target.getAttribute('data-activity-id');
    console.log('Stored activity ID:', window.draggedActivityId);
  },

  handleDragEnd(e) {
    console.log('Drag end');
    e.target.style.opacity = '1';
    
    // Remove all drop zone highlighting
    this.el.querySelectorAll('.drop-zone-active').forEach(zone => {
      zone.classList.remove('drop-zone-active');
    });
    
    // Clear the stored activity ID
    window.draggedActivityId = null;
  },

  handleDragOver(e) {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
  },

  handleDragEnter(e) {
    e.preventDefault();
    const dropZone = e.target.closest('.time-slot');
    if (dropZone) {
      dropZone.classList.add('drop-zone-active');
    }
  },

  handleDragLeave(e) {
    const dropZone = e.target.closest('.time-slot');
    if (dropZone) {
      // Check if we're actually leaving the drop zone
      const rect = dropZone.getBoundingClientRect();
      const x = e.clientX;
      const y = e.clientY;
      
      if (x < rect.left || x > rect.right || y < rect.top || y > rect.bottom) {
        dropZone.classList.remove('drop-zone-active');
      }
    }
  },

  handleDrop(e) {
    e.preventDefault();
    console.log('Drop event triggered from hook');
    
    const dropZone = e.target.closest('.time-slot');
    if (!dropZone) {
      console.log('No drop zone found');
      return;
    }

    // Try multiple ways to get the activity ID
    let activityId = window.draggedActivityId;
    
    if (!activityId) {
      const draggedElement = this.el.querySelector('.activity-item[style*="opacity: 0.5"]');
      if (draggedElement) {
        activityId = draggedElement.getAttribute('data-activity-id');
      }
    }
    
    if (!activityId) {
      console.log('Could not find activity ID');
      return;
    }

    // Get date and time from drop zone
    const date = dropZone.getAttribute('data-date');
    const time = dropZone.getAttribute('data-time');
    
    if (!date || !time) {
      console.log('No date or time found in drop zone');
      return;
    }

    console.log('Moving activity:', activityId, 'to', date, time);

    // Send event directly to this LiveView
    console.log('Sending move_activity event from hook');
    console.log('Event data:', {
      activity_id: activityId,
      new_date: date,
      new_time: time
    });
    
    this.pushEvent('move_activity', {
      activity_id: activityId,
      new_date: date,
      new_time: time
    });

    // Remove drop zone highlighting
    dropZone.classList.remove('drop-zone-active');
  }
};

// Hook for file upload preview
const FileUploadPreview = {
  mounted() {
    console.log('FileUploadPreview hook mounted');
    this.initFilePreview();
  },

  updated() {
    console.log('FileUploadPreview hook updated');
    this.initFilePreview();
  },

  initFilePreview() {
    const fileInput = this.el.querySelector('input[type="file"]');
    const previewContainer = this.el.querySelector('.upload-preview-container');
    
    if (fileInput && previewContainer) {
      fileInput.addEventListener('change', (e) => {
        const files = e.target.files;
        previewContainer.innerHTML = '';
        
        Array.from(files).forEach(file => {
            const reader = new FileReader();
          reader.onload = function(e) {
            const img = document.createElement('img');
            img.src = e.target.result;
            img.className = 'w-16 h-16 object-cover rounded border border-gray-300 dark:border-gray-700';
            previewContainer.appendChild(img);
            };
            reader.readAsDataURL(file);
        });
      });
    }
  }
};

// Hook for theme toggle
const ThemeToggle = {
  mounted() {
    console.log('ThemeToggle hook mounted');
    // Don't duplicate functionality - let the script in root.html.heex handle it
    // This hook is mainly for LiveView compatibility
  },

  updated() {
    console.log('ThemeToggle hook updated');
    // Update icons when the component updates
    this.updateIcons();
  },

  updateIcons() {
    const isDark = document.documentElement.classList.contains('dark');
    const sunIcon = this.el.querySelector('.sun-icon');
    const moonIcon = this.el.querySelector('.moon-icon');
    
    if (sunIcon && moonIcon) {
      if (isDark) {
        sunIcon.style.display = 'none';
        moonIcon.style.display = 'block';
      } else {
        sunIcon.style.display = 'block';
        moonIcon.style.display = 'none';
      }
    }
  }
};

// Hook for digital signature
const DigitalSignature = {
  mounted() {
    console.log('DigitalSignature hook mounted');
    this.canvas = this.el.querySelector('.signature-canvas');
    this.ctx = this.canvas.getContext('2d');
    this.isDrawing = false;
    this.lastX = 0;
    this.lastY = 0;
    this.saveTimeout = null;
    
    this.setupCanvas();
    this.bindEvents();
  },

  setupCanvas() {
    // Set canvas size to match display size
    const rect = this.canvas.getBoundingClientRect();
    this.canvas.width = rect.width;
    this.canvas.height = rect.height;
    
    // Forzar color de fondo oscuro azul para el canvas
    this.ctx.fillStyle = "#374151"; // bg-gray-700
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
    
    // Set drawing context
    this.ctx.strokeStyle = '#ffffff'; // Color blanco para la firma
    this.ctx.lineWidth = 2;
    this.ctx.lineCap = 'round';
    this.ctx.lineJoin = 'round';
  },

  bindEvents() {
    // Mouse events
    this.canvas.addEventListener('mousedown', this.startDrawing.bind(this));
    this.canvas.addEventListener('mousemove', this.draw.bind(this));
    this.canvas.addEventListener('mouseup', this.stopDrawing.bind(this));
    this.canvas.addEventListener('mouseout', this.stopDrawing.bind(this));
    
    // Touch events for mobile/tablet - prevent default to avoid scrolling
    this.canvas.addEventListener('touchstart', this.handleTouch.bind(this), { passive: false });
    this.canvas.addEventListener('touchmove', this.handleTouch.bind(this), { passive: false });
    this.canvas.addEventListener('touchend', this.stopDrawing.bind(this), { passive: false });
    
    // Prevent touch scrolling on the canvas container
    const canvasContainer = this.el.querySelector('.signature-container');
    if (canvasContainer) {
      canvasContainer.addEventListener('touchmove', (e) => {
        e.preventDefault();
      }, { passive: false });
    }
    
    // Clear button
    const clearBtn = this.el.querySelector('.clear-signature');
    if (clearBtn) {
      clearBtn.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.clearSignature();
      });
    }
  },

  handleTouch(e) {
    e.preventDefault();
    e.stopPropagation();
    
    if (e.touches.length === 0) return;
    
    const touch = e.touches[0];
    const rect = this.canvas.getBoundingClientRect();
    
    // Calculate coordinates relative to the canvas
    const x = touch.clientX - rect.left;
    const y = touch.clientY - rect.top;
    
    console.log('DigitalSignature: Touch coordinates - clientX:', touch.clientX, 'clientY:', touch.clientY);
    console.log('DigitalSignature: Canvas rect - left:', rect.left, 'top:', rect.top);
    console.log('DigitalSignature: Calculated coordinates - x:', x, 'y:', y);
    
    // Create a synthetic event with the correct coordinates
    const syntheticEvent = {
      clientX: x,
      clientY: y,
      preventDefault: () => {},
      stopPropagation: () => {}
    };
    
    if (e.type === 'touchstart') {
      this.startDrawing(syntheticEvent);
    } else if (e.type === 'touchmove') {
      this.draw(syntheticEvent);
    }
  },

  startDrawing(e) {
    e.preventDefault();
    e.stopPropagation();
    this.isDrawing = true;
    
    const rect = this.canvas.getBoundingClientRect();
    this.lastX = e.clientX - rect.left;
    this.lastY = e.clientY - rect.top;
    
    console.log('DigitalSignature: Started drawing at:', this.lastX, this.lastY);
  },

  draw(e) {
    if (!this.isDrawing) return;
    
    e.preventDefault();
    e.stopPropagation();
    
    const rect = this.canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    
    this.ctx.beginPath();
    this.ctx.moveTo(this.lastX, this.lastY);
    this.ctx.lineTo(x, y);
    this.ctx.stroke();
    
    this.lastX = x;
    this.lastY = y;
    console.log('DigitalSignature: Drawing to:', x, y);
  },

  stopDrawing() {
    this.isDrawing = false;
    // Clear any existing timeout
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout);
    }
    // Add a small delay to avoid sending too many events
    this.saveTimeout = setTimeout(() => {
      this.saveSignature();
    }, 200);
  },

  clearSignature() {
    // Limpiar y restaurar el color de fondo
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    this.ctx.fillStyle = "#374151"; // bg-gray-700
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
    this.saveSignature();
  },

  saveSignature() {
    // Convert canvas to base64 image
    const signatureData = this.canvas.toDataURL('image/png');
    console.log('DigitalSignature: Saving signature, data length:', signatureData.length);
    
    // Check if canvas has any content (not just empty)
    const imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
    const hasContent = imageData.data.some(pixel => pixel !== 0);
    
    // Only send to LiveView if signature has content
    if (hasContent && signatureData.length > 100) {
      // Send to LiveView
      this.pushEvent('signature_updated', { signature: signatureData });
      console.log('DigitalSignature: Signature event sent to LiveView');
    }
    
    // Update hidden input
    const hiddenInput = this.el.querySelector('.signature-data');
    if (hiddenInput) {
      hiddenInput.value = signatureData;
      console.log('DigitalSignature: Hidden input updated');
    } else {
      console.log('DigitalSignature: Hidden input not found');
    }
  }
};

// Hook for tab functionality
const TabManager = {
  mounted() {
    console.log('TabManager hook mounted on element:', this.el);
    console.log('TabManager element ID:', this.el.id);
    this.bindTabEvents();
  },

  updated() {
    console.log('TabManager hook updated');
    this.bindTabEvents();
  },

  bindTabEvents() {
    console.log('TabManager: Binding tab events');
    const tabButtons = this.el.querySelectorAll('.tab-button');
    const tabContents = this.el.closest('.bg-white').querySelectorAll('.tab-content');
    
    console.log('TabManager: Found tab buttons:', tabButtons.length);
    console.log('TabManager: Found tab contents:', tabContents.length);
    console.log('TabManager: Tab buttons:', Array.from(tabButtons).map(btn => btn.dataset.tab));
    console.log('TabManager: Tab contents:', Array.from(tabContents).map(content => content.id));
    
    tabButtons.forEach(button => {
      console.log('TabManager: Adding click listener to button:', button.dataset.tab);
      button.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        const targetTab = button.dataset.tab;
        console.log('TabManager: Tab clicked:', targetTab);
        
        // Update button states
        tabButtons.forEach(btn => {
          btn.classList.remove('active', 'text-blue-600', 'border-blue-600');
          btn.classList.add('text-gray-500', 'hover:text-gray-700', 'dark:text-gray-400', 'dark:hover:text-gray-300');
        });
        button.classList.add('active', 'text-blue-600', 'border-blue-600');
        button.classList.remove('text-gray-500', 'hover:text-gray-700', 'dark:text-gray-400', 'dark:hover:text-gray-300');
        
        // Update content visibility
        tabContents.forEach(content => {
          content.classList.add('hidden');
          content.classList.remove('active');
        });
        
        const targetContent = this.el.closest('.bg-white').querySelector(`#${targetTab}-tab`);
        console.log('TabManager: Looking for target content:', `#${targetTab}-tab`);
        console.log('TabManager: Found target content:', targetContent);
        if (targetContent) {
          targetContent.classList.remove('hidden');
          targetContent.classList.add('active');
          console.log('TabManager: Tab switched to:', targetTab);
        } else {
          console.log('TabManager: Target content not found!');
          // Try to find any tab content
          const allTabContents = document.querySelectorAll('.tab-content');
          console.log('TabManager: All tab contents found:', Array.from(allTabContents).map(c => c.id));
        }
      });
    });
  }
};

// Hook for agenda form title auto-generation
const AgendaForm = {
  mounted() {
    console.log('AgendaForm hook mounted');
    this.initFormHandlers();
  },

  initFormHandlers() {
    const serviceSelect = this.el.querySelector('select[name="activity[service_id]"]');
    const specialistSelect = this.el.querySelector('select[name="activity[specialist_id]"]');
    const titleInput = this.el.querySelector('input[name="activity[title]"]');

    if (serviceSelect && specialistSelect && titleInput) {
      // Update placeholder when service or specialist changes
      const updatePlaceholder = () => {
        const serviceOption = serviceSelect.options[serviceSelect.selectedIndex];
        const specialistOption = specialistSelect.options[specialistSelect.selectedIndex];
        
        if (serviceOption && specialistOption && serviceOption.value && specialistOption.value) {
          const serviceName = serviceOption.text;
          const specialistName = specialistOption.text;
          titleInput.placeholder = `Se generará: "${serviceName} - ${specialistName}"`;
        } else {
          titleInput.placeholder = "Se generará automáticamente si selecciona servicio y especialista";
        }
      };

      serviceSelect.addEventListener('change', updatePlaceholder);
      specialistSelect.addEventListener('change', updatePlaceholder);
      
      // Initialize placeholder
      updatePlaceholder();
    }
  }
};

let KanbanDragDrop = {
  mounted() {
    console.log("KanbanDragDrop hook mounted");
    this.sortables = [];
    this.initSortables();
  },
  updated() {
    console.log("KanbanDragDrop hook updated");
    this.initSortables();
  },
  destroyed() {
    console.log("KanbanDragDrop hook destroyed");
    this.sortables.forEach(s => s.destroy());
    this.sortables = [];
  },
  initSortables() {
    console.log("KanbanDragDrop initSortables called");
    this.sortables.forEach(s => s.destroy());
    this.sortables = [];
    
    // Buscar las columnas del Kanban
    const columns = this.el.querySelectorAll("[data-kanban-column]");
    console.log("Found columns with data-kanban-column:", columns.length);
    
    if (columns.length === 0) {
      console.log("No columns found with data-kanban-column");
      return;
    }
    
    // Crear sortable para cada columna
    columns.forEach((column, index) => {
      console.log(`Processing column ${index + 1}:`, {
        status: column.dataset.status,
        workflow: column.dataset.workflow
      });
      
      // Buscar el contenedor de las cards dentro de la columna
      const cardsContainer = column.querySelector(".kanban-col-cards");
      if (!cardsContainer) {
        console.log(`No .kanban-col-cards found in column ${index + 1}`);
        return;
      }
      
      console.log(`Creating sortable for column ${index + 1} with ${cardsContainer.children.length} cards`);
      
      // Log all cards in this column
      const cards = cardsContainer.querySelectorAll('[data-id]');
      console.log(`Cards in column ${index + 1}:`, Array.from(cards).map(card => ({
        id: card.dataset.id,
        title: card.textContent?.trim().substring(0, 50)
      })));
      
      let sortable = Sortable.create(cardsContainer, {
        group: "kanban", // Permitir drag entre todas las columnas
        animation: 150,
        ghostClass: 'sortable-ghost',
        chosenClass: 'sortable-chosen',
        dragClass: 'sortable-drag',
        filter: '[data-no-dnd]', // Ignorar elementos con data-no-dnd
        preventOnFilter: false,
        onStart: (evt) => {
          console.log("Drag started", evt);
          console.log("Dragged item:", evt.item);
          console.log("Item dataset:", evt.item.dataset);
          evt.item.style.opacity = '0.5';
        },
        onEnd: (evt) => {
          evt.item.style.opacity = '1';
          const itemId = evt.item.dataset.id;
          const newStatus = evt.to.closest('[data-kanban-column]').dataset.status;
          const oldStatus = evt.from.closest('[data-kanban-column]').dataset.status;
          const workflowId = evt.to.closest('[data-kanban-column]').dataset.workflow;
          
          console.log("Sortable onEnd", { 
            itemId, 
            newStatus, 
            oldStatus, 
            workflowId,
            fromWorkflow: evt.from.closest('[data-kanban-column]').dataset.workflow,
            toWorkflow: evt.to.closest('[data-kanban-column]').dataset.workflow
          });
          
          // Solo actualizar si cambió de estado
          if (newStatus !== oldStatus) {
            console.log("Status changed, sending kanban:move event");
            this.pushEvent("kanban:move", {
              id: itemId,
              new_status: newStatus,
              old_status: oldStatus,
              workflow_id: workflowId
            });
          } else {
            console.log("No status change, not sending event");
          }
        }
      });
      this.sortables.push(sortable);
    });
    
    console.log(`Initialized ${this.sortables.length} sortables`);
  }
};

// Sidebar and User Dropdown functionality
const SidebarManager = {
  mounted() {
    this.initSidebar();
    this.initUserDropdown();
  },

  initSidebar() {
    // Mobile sidebar toggle
    const sidebarToggle = document.querySelector('[data-drawer-toggle="logo-sidebar"]');
    // Desktop sidebar toggle
    const desktopSidebarToggle = document.querySelector('#sidebar-toggle');
    const sidebar = document.querySelector('#logo-sidebar');
    const mainContent = document.querySelector('#main-content');
    
    if (!sidebar || !mainContent) {
      console.error('Sidebar or main content not found');
      return;
    }
    
    // Función para verificar si el sidebar está oculto
    const isSidebarHidden = () => {
      const transform = sidebar.style.transform;
      const isHidden = transform === 'translateX(-100%)' || 
                      transform === 'translateX(-100px)' ||
                      transform === '' || 
                      transform === 'none' ||
                      transform === 'translateX(-256px)' ||
                      transform.includes('-100%') ||
                      transform.includes('-256px') ||
                      transform.includes('-') ||
                      sidebar.classList.contains('-translate-x-full');
      
      console.log('Checking if sidebar is hidden:', {
        transform,
        isHidden,
        includesNegative: transform.includes('-'),
        hasClass: sidebar.classList.contains('-translate-x-full')
      });
      
      return isHidden;
    };
    
    // Función para ocultar sidebar
    const hideSidebar = () => {
      sidebar.style.transform = 'translateX(-100%)';
      sidebar.classList.remove('-translate-x-full');
      sidebar.classList.add('translate-x-0');
      if (window.innerWidth >= 640) {
        mainContent.style.marginLeft = '0';
      }
      localStorage.setItem('sidebar-hidden', 'true');
      console.log('Sidebar hidden');
    };
    
    // Función para mostrar sidebar
    const showSidebar = () => {
      sidebar.style.transform = 'translateX(0)';
      sidebar.classList.remove('-translate-x-full');
      sidebar.classList.add('translate-x-0');
      if (window.innerWidth >= 640) {
        mainContent.style.marginLeft = '16rem'; // 256px = 16rem
      }
      localStorage.setItem('sidebar-hidden', 'false');
      console.log('Sidebar shown');
    };
    
    // Toggle para móvil
    const mobileSidebarToggle = document.getElementById('mobile-sidebar-toggle');
    if (mobileSidebarToggle) {
      mobileSidebarToggle.addEventListener('click', () => {
        console.log('Mobile sidebar toggle clicked');
        if (window.innerWidth < 640) {
          if (isSidebarHidden()) {
            showSidebar();
          } else {
            hideSidebar();
          }
        }
      });
    
      // Close sidebar when clicking outside on mobile
      document.addEventListener('click', (e) => {
        if (window.innerWidth < 640 && 
            !sidebar.contains(e.target) && 
            !mobileSidebarToggle.contains(e.target) &&
            !isSidebarHidden()) {
          hideSidebar();
        }
      });
    }
    
    // Toggle para desktop
    if (desktopSidebarToggle) {
      desktopSidebarToggle.addEventListener('click', () => {
        if (window.innerWidth >= 640) {
          console.log('Desktop sidebar toggle clicked');
          
          // Usar localStorage para determinar el estado actual
          const sidebarHidden = localStorage.getItem('sidebar-hidden');
          const currentlyHidden = sidebarHidden === 'true';
          
          console.log('Current localStorage state:', sidebarHidden);
          console.log('Currently hidden:', currentlyHidden);
          
          if (currentlyHidden) {
            showSidebar();
          } else {
            hideSidebar();
          }
        }
      });
    }
    
    // Configurar estado inicial
    if (window.innerWidth >= 640) {
      const sidebarHidden = localStorage.getItem('sidebar-hidden');
      if (sidebarHidden === 'true') {
        hideSidebar();
      } else {
        // Estado por defecto: sidebar visible
        showSidebar();
      }
    } else {
      // En móviles, el sidebar siempre debe estar oculto por defecto
      sidebar.style.transform = 'translateX(-100%)';
      sidebar.classList.add('-translate-x-full');
      sidebar.classList.remove('translate-x-0');
    }
    
    // Manejar cambio de tamaño de ventana
    window.addEventListener('resize', () => {
      if (window.innerWidth >= 640) {
        // En desktop, restaurar el estado guardado
        const sidebarHidden = localStorage.getItem('sidebar-hidden');
        if (sidebarHidden === 'true') {
          hideSidebar();
        } else {
          showSidebar();
        }
      } else {
        // En móvil, siempre ocultar el sidebar
        hideSidebar();
      }
    });
  },

  initUserDropdown() {
    const userButton = document.querySelector('[data-dropdown-toggle="dropdown-user"]');
    const userDropdown = document.querySelector('#dropdown-user');
    
    if (userButton && userDropdown) {
      userButton.addEventListener('click', () => {
        userDropdown.classList.toggle('hidden');
      });
    
      // Close dropdown when clicking outside
      document.addEventListener('click', (e) => {
        if (!userButton.contains(e.target) && !userDropdown.contains(e.target)) {
          userDropdown.classList.add('hidden');
        }
      });
    }
  }
};

// Hook para debugging del formulario de evaluación
let EvaluationForm = {
  mounted() {
    console.log('🔍 EvaluationForm hook mounted');
    
    // Log cuando se envía el formulario
    this.el.addEventListener('submit', (e) => {
      console.log('📝 Form submit event triggered');
      console.log('📝 Form action:', this.el.action);
      console.log('📝 Form method:', this.el.method);
      
      // Log todos los campos del formulario
      const formData = new FormData(this.el);
      console.log('📊 Form data entries:');
      for (let [key, value] of formData.entries()) {
        console.log(`  ${key}: ${value}`);
      }
    });
  }
};

// Hook para el upload de fotos
let PhotoUpload = {
  mounted() {
    console.log('📸 PhotoUpload hook mounted');
    
    // Buscar el input de archivo
    const fileInput = this.el.querySelector('input[type="file"]');
    if (fileInput) {
      console.log('📸 File input found:', fileInput);
      
      fileInput.addEventListener('change', (e) => {
        console.log('📸 File input change event:', e.target.files);
        console.log('📸 Files selected:', e.target.files.length);
        
        // Forzar el upload manualmente
        if (e.target.files.length > 0) {
          console.log('📸 Triggering manual upload...');
          this.pushEvent('manual_upload_triggered', {
            files: Array.from(e.target.files).map(f => f.name)
          });
        }
      });
    } else {
      console.log('📸 No file input found in element');
    }
  }
};

// Hook para el modal de upload
let UploadModal = {
  mounted() {
    console.log('📁 UploadModal hook mounted');
    
    // Buscar el input de archivo
    const fileInput = this.el.querySelector('input[type="file"]');
    if (fileInput) {
      console.log('📁 File input found:', fileInput);
      
      // Asegurar que el label funcione correctamente
      const label = this.el.querySelector('label[for="file-input"]');
      if (label) {
        label.addEventListener('click', (e) => {
          console.log('📁 Label clicked, triggering file input');
          fileInput.click();
        });
      }
    } else {
      console.log('📁 No file input found in element');
    }
  }
};

// Hook para manejar la carga de imágenes en las miniaturas
let ImageThumbnails = {
  mounted() {
    console.log('🖼️ ImageThumbnails hook mounted');
    console.log('🖼️ Element:', this.el);
    
    // Buscar todas las imágenes en el elemento
    const images = this.el.querySelectorAll('img');
    console.log('🖼️ All images found:', images.length);
    
    images.forEach((img, index) => {
      console.log(`🖼️ Image ${index + 1}:`, {
        src: img.src,
        alt: img.alt,
        className: img.className,
        style: img.style.cssText
      });
    });
    
    // Buscar específicamente imágenes de uploads
    const uploadImages = this.el.querySelectorAll('img[src*="/uploads/"]');
    console.log('🖼️ Upload images found:', uploadImages.length);
    
    uploadImages.forEach((img, index) => {
      console.log(`🖼️ Upload image ${index + 1}:`, img.src);
      
      // Verificar si la imagen ya está cargada
      if (img.complete) {
        console.log(`🖼️ Image already loaded:`, img.src);
        img.style.opacity = '1';
      } else {
        console.log(`🖼️ Image not loaded yet:`, img.src);
        img.style.opacity = '0';
        img.style.transition = 'opacity 0.3s ease-in-out';
      }
      
      // Agregar evento de carga exitosa
      img.addEventListener('load', () => {
        console.log(`🖼️ Image loaded successfully:`, img.src);
        img.style.opacity = '1';
      });
      
      // Agregar evento de error
      img.addEventListener('error', () => {
        console.log(`🖼️ Image failed to load:`, img.src);
        console.log(`🖼️ Error details:`, {
          naturalWidth: img.naturalWidth,
          naturalHeight: img.naturalHeight,
          complete: img.complete
        });
        // Mostrar el fallback
        const fallback = img.nextElementSibling;
        if (fallback && fallback.classList.contains('bg-slate-100')) {
          console.log(`🖼️ Showing fallback for:`, img.src);
          img.style.display = 'none';
          fallback.style.display = 'flex';
        }
      });
    });
  }
};

// Hook para el slider de progreso
let ProgressSlider = {
  mounted() {
    console.log('📊 ProgressSlider hook mounted');
    
    this.el.addEventListener('input', (e) => {
      const progress = e.target.value;
      console.log('📊 Slider value changed to:', progress);
      
      // Enviar el evento al LiveView
      this.pushEvent('update_progress', { progress: progress });
    });
  }
};

// Hook para el wizard de mantenimiento
let MaintenancePhotoUpload = {
  mounted() {
    console.log('🔧 MaintenancePhotoUpload hook mounted');
    console.log('🔧 Element:', this.el);
    
    // Buscar el input de archivo
    const fileInput = this.el.querySelector('input[type="file"]');
    if (fileInput) {
      console.log('🔧 File input found:', fileInput);
      
      fileInput.addEventListener('change', (e) => {
        console.log('🔧 File input change event:', e.target.files);
        console.log('🔧 Files selected:', e.target.files.length);
        
        // Forzar el upload manualmente
        if (e.target.files.length > 0) {
          console.log('🔧 Triggering manual upload...');
          this.pushEvent('maintenance_file_selected', {
            files: Array.from(e.target.files).map(f => f.name)
          });
        }
      });
    } else {
      console.log('🔧 No file input found in element');
    }
  }
};

// Hook específico para el upload de evaluación
let EvaluationPhotoUpload = {
  mounted() {
    console.log('📸 EvaluationPhotoUpload hook mounted');
    
    // Buscar el input de archivo específico para evaluación
    const fileInput = this.el.querySelector('input[type="file"]');
    if (fileInput) {
      console.log('📸 Evaluation file input found:', fileInput);
      
      fileInput.addEventListener('change', (e) => {
        console.log('📸 Evaluation file input change event:', e.target.files);
        console.log('📸 Files selected:', e.target.files.length);
        
        if (e.target.files.length > 0) {
          console.log('📸 Forcing LiveView upload processing...');
          
          // Obtener el liveSocket del elemento
          const liveSocket = window.liveSocket;
          if (liveSocket) {
            console.log('📸 LiveSocket found, triggering upload...');
            
            // Forzar el procesamiento del upload manualmente
            const view = liveSocket.getViewByEl(this.el);
            if (view) {
              console.log('📸 View found, processing uploads...');
              
              // Simular el evento de cambio que LiveView espera
              const changeEvent = new Event('change', { bubbles: true });
              fileInput.dispatchEvent(changeEvent);
              
              // Forzar el procesamiento inmediato
              setTimeout(() => {
                console.log('📸 Forcing upload entries update...');
                this.pushEvent('force_upload_processing', {
                  files: Array.from(e.target.files).map(f => f.name),
                  uploadRef: this.el.getAttribute('data-upload-ref')
                });
              }, 100);
            }
          }
          
          // También enviar evento al servidor como respaldo
          this.pushEvent('evaluation_file_selected', {
            files: Array.from(e.target.files).map(f => f.name),
            uploadRef: this.el.getAttribute('data-upload-ref')
          });
        }
      });
    } else {
      console.log('📸 No evaluation file input found in element');
    }
  }
};

let Hooks = {
  AgendaDragDrop,
  FileUploadPreview,
  AgendaForm,
  KanbanDragDrop,
  SidebarManager,
  ThemeToggle,
  DigitalSignature,
  TabManager,
  EvaluationForm,
  PhotoUpload,
  EvaluationPhotoUpload,
  UploadModal,
  ImageThumbnails,
  MaintenancePhotoUpload,
  ProgressSlider,
  DocumentUpload,
  DocumentPreview,
  SignaturePad
};

let csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
});

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// --- Notificación de actividad reciente con sonido ---
window.addEventListener("phx:actividad_reciente", (event) => {
  let audio = document.getElementById("noti-audio");
  if (!audio) {
    audio = document.createElement("audio");
    audio.id = "noti-audio";
    audio.src = "/sounds/notification.mp3";
    audio.preload = "auto";
    document.body.appendChild(audio);
  }
  audio.currentTime = 0;
  audio.load();
  audio.play().catch(() => {
    // Si el navegador bloquea el autoplay, puedes mostrar un mensaje o pedir interacción
    // Por ejemplo, podrías mostrar un toast: "Activa el sonido para notificaciones"
  });

  // Mostrar toast
  let toast = document.createElement("div");
  toast.className = "fixed bottom-6 right-6 bg-pink-600 text-white px-4 py-3 rounded shadow-lg z-50 animate-bounce";
  toast.innerText = event.detail && event.detail.message ? event.detail.message : "¡Nueva actividad!";
  document.body.appendChild(toast);
  setTimeout(() => toast.remove(), 4000);
});

// --- Hook para firma digital en checkout ---
// SignaturePad hook is now imported from ./hooks/signature_pad.js

// --- User Modal logic ---
document.addEventListener("DOMContentLoaded", function() {
  const userModalToggle = document.getElementById("user-modal-toggle");
  const userModal = document.getElementById("user-modal");
  const userModalClose = document.getElementById("user-modal-close");

  if (userModalToggle && userModal && userModalClose) {
    userModalToggle.addEventListener("click", function(e) {
      e.stopPropagation();
      userModal.classList.remove("hidden");
    });
    userModalClose.addEventListener("click", function() {
      userModal.classList.add("hidden");
    });
    userModal.addEventListener("click", function(e) {
      if (e.target === userModal) {
        userModal.classList.add("hidden");
      }
    });
    document.addEventListener("keydown", function(e) {
      if (e.key === "Escape") {
        userModal.classList.add("hidden");
      }
    });
  }
});

// --- PDF Upload Hook ---
const PdfUpload = {
  mounted() {
    console.log('🔍 PdfUpload hook mounted');
    this.initPdfUpload();
  },
  
  initPdfUpload() {
    console.log('🔍 Initializing PDF upload...');
    const fileInput = this.el.querySelector('#pdf_file');
    const hiddenInput = this.el.querySelector('#pdf_content');
    const submitBtn = this.el.querySelector('#submit-btn');
    
    console.log('🔍 File input found:', !!fileInput);
    console.log('🔍 Hidden input found:', !!hiddenInput);
    console.log('🔍 Submit button found:', !!submitBtn);
    
    if (fileInput && hiddenInput && submitBtn) {
      fileInput.addEventListener('change', (e) => {
        console.log('🔍 File input change event triggered');
        if (e.target.files.length > 0) {
          const file = e.target.files[0];
          console.log('🔍 File selected:', file.name, 'Size:', file.size);
          
          // Show file preview
          this.showFilePreview(file);
          
          // Enable submit button
          submitBtn.disabled = false;
          
          const reader = new FileReader();
          reader.onload = (e) => {
            const pdfContent = e.target.result;
            console.log('🔍 PDF content loaded, size:', pdfContent.length);
            hiddenInput.value = pdfContent;
            console.log('🔍 Hidden input value set, length:', hiddenInput.value.length);
          };
          reader.readAsDataURL(file);
        } else {
          console.log('🔍 No files selected');
          this.hideFilePreview();
        }
      });
      
      // Add form submit handler
      const form = this.el.querySelector('#pdf-upload-form');
      if (form) {
        form.addEventListener('submit', (e) => {
          console.log('🔍 Form submit executed');
          if (hiddenInput.value.length === 0) {
            console.log('🔍 ERROR: No PDF content');
            e.preventDefault();
            alert('Por favor selecciona un archivo PDF válido');
            return false;
          }
          
          // Show loading state
          this.showLoadingState();
          console.log('🔍 Form submitted with content size:', hiddenInput.value.length);
        });
      }
      
      console.log('🔍 Event listeners added successfully');
    } else {
      console.log('🔍 ERROR: Required elements not found');
    }
  },
  
  showFilePreview(file) {
    const preview = this.el.querySelector('#file-preview');
    const fileName = this.el.querySelector('#file-name');
    const fileSize = this.el.querySelector('#file-size');
    
    if (preview && fileName && fileSize) {
      fileName.textContent = file.name;
      fileSize.textContent = this.formatFileSize(file.size);
      preview.classList.remove('hidden');
    }
  },
  
  hideFilePreview() {
    const preview = this.el.querySelector('#file-preview');
    if (preview) {
      preview.classList.add('hidden');
    }
  },
  
  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  },
  
  showLoadingState() {
    const loadingState = this.el.querySelector('#loading-state');
    const submitBtn = this.el.querySelector('#submit-btn');
    
    if (loadingState) {
      loadingState.classList.remove('hidden');
    }
    
    if (submitBtn) {
      submitBtn.disabled = true;
      submitBtn.textContent = '⏳ Procesando...';
    }
  }
};

// Register the hook
window.LiveSocket = window.LiveSocket || {};
window.LiveSocket.Hooks = window.LiveSocket.Hooks || {};
window.LiveSocket.Hooks.PdfUpload = PdfUpload;
console.log('🔍 PdfUpload hook registered:', !!window.LiveSocket.Hooks.PdfUpload);

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Sidebar Toggle Functionality
document.addEventListener('DOMContentLoaded', function() {
  initializeSidebar();
});

// También inicializar cuando LiveView actualiza el DOM
document.addEventListener('phx:update', function() {
  initializeSidebar();
});

function initializeSidebar() {
  const sidebarToggle = document.getElementById('sidebar-toggle');
  const sidebar = document.getElementById('logo-sidebar');
  const mainContent = document.getElementById('main-content');
  
  if (sidebarToggle && sidebar && mainContent) {
    // Obtener estado guardado del localStorage
    let sidebarCollapsed = localStorage.getItem('sidebarCollapsed') === 'true';
    
    // Aplicar estado inicial
    applySidebarState(sidebar, mainContent, sidebarCollapsed);
    
    sidebarToggle.addEventListener('click', function() {
      sidebarCollapsed = !sidebarCollapsed;
      
      // Guardar estado en localStorage
      localStorage.setItem('sidebarCollapsed', sidebarCollapsed);
      
      // Aplicar el nuevo estado
      applySidebarState(sidebar, mainContent, sidebarCollapsed);
    });
    
    // Manejar resize de ventana
    window.addEventListener('resize', function() {
      applySidebarState(sidebar, mainContent, sidebarCollapsed);
    });
  }
}

function applySidebarState(sidebar, mainContent, collapsed) {
  // Solo aplicar en desktop (sm y superior)
  if (window.innerWidth >= 640) {
    if (collapsed) {
      // Colapsar sidebar
      sidebar.style.width = '4rem'; // 64px
      sidebar.style.transform = 'translateX(0)';
      mainContent.style.marginLeft = '4rem';
    
    // Ocultar texto en los elementos del sidebar
    const sidebarTexts = sidebar.querySelectorAll('span, .ms-3');
    sidebarTexts.forEach(text => {
      text.style.display = 'none';
    });
    
    // Centrar iconos
    const sidebarItems = sidebar.querySelectorAll('a, button');
    sidebarItems.forEach(item => {
      item.style.justifyContent = 'center';
      item.style.padding = '0.5rem';
    });
    
      // Ajustar el botón de feedback
      const feedbackBtn = sidebar.querySelector('a[href="/feedback"]');
      if (feedbackBtn) {
        feedbackBtn.style.justifyContent = 'center';
        feedbackBtn.style.padding = '0.75rem';
      }
    } else {
      // Expandir sidebar
      sidebar.style.width = '16rem'; // 256px
      sidebar.style.transform = 'translateX(0)';
      mainContent.style.marginLeft = '16rem';
    
    // Mostrar texto en los elementos del sidebar
    const sidebarTexts = sidebar.querySelectorAll('span, .ms-3');
    sidebarTexts.forEach(text => {
      text.style.display = '';
    });
    
    // Restaurar layout original
    const sidebarItems = sidebar.querySelectorAll('a, button');
    sidebarItems.forEach(item => {
      item.style.justifyContent = '';
      item.style.padding = '';
    });
    
      // Restaurar el botón de feedback
      const feedbackBtn = sidebar.querySelector('a[href="/feedback"]');
      if (feedbackBtn) {
        feedbackBtn.style.justifyContent = '';
        feedbackBtn.style.padding = '';
      }
    }
  } else {
    // En móvil, asegurar que el sidebar esté completamente oculto
    sidebar.style.width = '16rem';
    sidebar.style.transform = 'translateX(-100%)';
    mainContent.style.marginLeft = '0';
    
    // Resetear cualquier estilo de colapso
    const sidebarTexts = sidebar.querySelectorAll('span, .ms-3');
    sidebarTexts.forEach(text => {
      text.style.display = '';
    });
    
    const sidebarItems = sidebar.querySelectorAll('a, button');
    sidebarItems.forEach(item => {
      item.style.justifyContent = '';
      item.style.padding = '';
    });
  }
}

