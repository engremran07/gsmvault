/**
 * static/js/src/admin.js — Admin panel utilities
 * Sidebar state persistence, command search, bulk actions.
 */
document.addEventListener('DOMContentLoaded', function() {
  // Restore sidebar state from localStorage
  const saved = localStorage.getItem('admin_sidebar_open');
  if (saved !== null) {
    const sidebar = document.querySelector('[x-data]');
    if (sidebar && sidebar.__x) {
      sidebar.__x.$data.sidebarOpen = saved === 'true';
    }
  }

  // Keyboard shortcut: Ctrl+K for command search
  document.addEventListener('keydown', function(e) {
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
      e.preventDefault();
      const searchInput = document.querySelector('[data-admin-search]');
      if (searchInput) {
        searchInput.focus();
      }
    }
  });

  // Confirm destructive actions
  document.querySelectorAll('[data-confirm]').forEach(function(el) {
    el.addEventListener('click', function(e) {
      const message = el.getAttribute('data-confirm') || 'Are you sure?';
      if (!confirm(message)) {
        e.preventDefault();
      }
    });
  });

  // Select all checkbox for bulk actions
  const selectAll = document.querySelector('[data-select-all]');
  if (selectAll) {
    selectAll.addEventListener('change', function() {
      const checkboxes = document.querySelectorAll('[data-select-row]');
      checkboxes.forEach(function(cb) { cb.checked = selectAll.checked; });
    });
  }
});

// Save sidebar state when toggled
document.addEventListener('alpine:initialized', function() {
  const sidebarEl = document.querySelector('[x-data]');
  if (sidebarEl && sidebarEl.__x) {
    sidebarEl.__x.$watch('sidebarOpen', function(val) {
      localStorage.setItem('admin_sidebar_open', val);
    });
  }
});
