/**
 * static/js/src/main.js — Main entry point
 * Re-initialize Lucide icons after HTMX swaps.
 */
document.addEventListener('DOMContentLoaded', function() {
  if (typeof lucide !== 'undefined') {
    lucide.createIcons();
  }
});

// Re-render icons after any HTMX content swap
document.addEventListener('htmx:afterSwap', function() {
  if (typeof lucide !== 'undefined') {
    lucide.createIcons();
  }
});
