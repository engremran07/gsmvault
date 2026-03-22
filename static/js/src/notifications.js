/**
 * static/js/src/notifications.js — Global notification system
 *
 * Alpine.js stores for:
 *   $store.notify  — Toast notifications (success/error/warning/info)
 *   $store.confirm — Confirmation dialogs (replaces browser confirm())
 *
 * Usage from Alpine components:
 *   $store.notify.success('File uploaded successfully')
 *   $store.notify.error('Upload failed: file too large')
 *   $store.notify.warning('Your session expires in 5 minutes')
 *   $store.notify.info('New firmware version available')
 *
 * Usage for confirmations:
 *   $store.confirm.show({
 *     title: 'Delete device?',
 *     message: 'This action cannot be undone.',
 *     confirmText: 'Delete',
 *     danger: true,
 *     onConfirm: () => { ... }
 *   })
 */
document.addEventListener('alpine:init', () => {

  /* --------------------------------------------------------
   * Toast Notification Store
   * -------------------------------------------------------- */
  Alpine.store('notify', {
    items: [],
    _counter: 0,

    /**
     * Add a toast notification.
     * @param {string} type    — 'success' | 'error' | 'warning' | 'info'
     * @param {string} message — Human-readable message
     * @param {object} opts    — { duration: ms, title: string, dismissible: bool }
     */
    add(type, message, opts = {}) {
      const id = ++this._counter;
      const duration = opts.duration ?? (type === 'error' ? 8000 : 5000);
      const toast = {
        id,
        type,
        message,
        title: opts.title || this._defaultTitle(type),
        dismissible: opts.dismissible !== false,
        visible: true,
        progress: 100,
      };
      this.items.push(toast);

      // Auto-dismiss with progress countdown
      if (duration > 0) {
        const step = 50; // update every 50ms
        const decrement = (step / duration) * 100;
        const interval = setInterval(() => {
          const item = this.items.find(t => t.id === id);
          if (!item || !item.visible) {
            clearInterval(interval);
            return;
          }
          item.progress = Math.max(0, item.progress - decrement);
          if (item.progress <= 0) {
            clearInterval(interval);
            this.dismiss(id);
          }
        }, step);
      }

      // Cap at 5 visible toasts
      if (this.items.length > 5) {
        this.items.splice(0, this.items.length - 5);
      }
    },

    dismiss(id) {
      const item = this.items.find(t => t.id === id);
      if (item) item.visible = false;
      // Remove from DOM after transition
      setTimeout(() => {
        this.items = this.items.filter(t => t.id !== id);
      }, 300);
    },

    dismissAll() {
      this.items.forEach(t => { t.visible = false; });
      setTimeout(() => { this.items = []; }, 300);
    },

    // Convenience methods
    success(message, opts = {}) { this.add('success', message, opts); },
    error(message, opts = {})   { this.add('error', message, opts); },
    warning(message, opts = {}) { this.add('warning', message, opts); },
    info(message, opts = {})    { this.add('info', message, opts); },

    _defaultTitle(type) {
      const titles = {
        success: 'Success',
        error: 'Error',
        warning: 'Warning',
        info: 'Notice',
      };
      return titles[type] || 'Notice';
    },

    /** Icon name for Lucide */
    icon(type) {
      const icons = {
        success: 'check-circle',
        error: 'alert-circle',
        warning: 'alert-triangle',
        info: 'info',
      };
      return icons[type] || 'info';
    },
  });

  /* --------------------------------------------------------
   * Confirmation Dialog Store
   * -------------------------------------------------------- */
  Alpine.store('confirm', {
    open: false,
    title: '',
    message: '',
    confirmText: 'Confirm',
    cancelText: 'Cancel',
    danger: false,
    _onConfirm: null,
    _onCancel: null,

    /**
     * Show a confirmation dialog.
     * @param {object} opts
     *   title       — Dialog heading
     *   message     — Body text
     *   confirmText — Confirm button label (default: 'Confirm')
     *   cancelText  — Cancel button label (default: 'Cancel')
     *   danger      — Red/destructive styling (default: false)
     *   onConfirm   — Callback when confirmed
     *   onCancel    — Callback when cancelled
     */
    show(opts = {}) {
      this.title = opts.title || 'Are you sure?';
      this.message = opts.message || '';
      this.confirmText = opts.confirmText || 'Confirm';
      this.cancelText = opts.cancelText || 'Cancel';
      this.danger = opts.danger || false;
      this._onConfirm = opts.onConfirm || null;
      this._onCancel = opts.onCancel || null;
      this.open = true;
    },

    confirm() {
      this.open = false;
      if (this._onConfirm) this._onConfirm();
      this._reset();
    },

    cancel() {
      this.open = false;
      if (this._onCancel) this._onCancel();
      this._reset();
    },

    _reset() {
      // Delay reset so exit animation completes
      setTimeout(() => {
        this.title = '';
        this.message = '';
        this.confirmText = 'Confirm';
        this.cancelText = 'Cancel';
        this.danger = false;
        this._onConfirm = null;
        this._onCancel = null;
      }, 200);
    },
  });

  /* --------------------------------------------------------
   * HTMX integration — show toasts on HTMX response headers
   * Server can send: HX-Trigger: {"showToast": {"type":"success","message":"Saved!"}}
   * -------------------------------------------------------- */
  document.addEventListener('showToast', (evt) => {
    const detail = evt.detail || {};
    const type = detail.type || 'info';
    const message = detail.message || '';
    if (message) {
      Alpine.store('notify').add(type, message, {
        title: detail.title,
        duration: detail.duration,
      });
    }
  });

  /* --------------------------------------------------------
   * Listen for HTMX errors and show toast
   * -------------------------------------------------------- */
  document.addEventListener('htmx:responseError', (evt) => {
    const xhr = evt.detail.xhr;
    let msg = 'Request failed';
    if (xhr) {
      if (xhr.status === 403) msg = 'Access denied — you don\'t have permission for this action';
      else if (xhr.status === 404) msg = 'The requested resource was not found';
      else if (xhr.status === 429) msg = 'Too many requests — please slow down';
      else if (xhr.status >= 500) msg = 'Server error — please try again later';
      else msg = 'Request failed (HTTP ' + xhr.status + ')';
    }
    Alpine.store('notify').error(msg);
  });

  document.addEventListener('htmx:sendError', () => {
    Alpine.store('notify').error('Network error — check your connection and try again');
  });

  document.addEventListener('htmx:timeout', () => {
    Alpine.store('notify').warning('Request timed out — the server may be busy, please try again');
  });
});
