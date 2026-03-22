/**
 * static/js/src/theme-switcher.js — Theme switching logic
 * Uses Alpine.js store for state management.
 */
document.addEventListener('alpine:init', () => {
  Alpine.store('theme', {
    current: localStorage.getItem('theme') || 'dark',
    themes: ['dark', 'light', 'contrast'],

    set(name) {
      this.current = name;
      document.documentElement.setAttribute('data-theme', name);
      localStorage.setItem('theme', name);
    },

    cycle() {
      const idx = this.themes.indexOf(this.current);
      const next = this.themes[(idx + 1) % this.themes.length];
      this.set(next);
    }
  });

  // Apply stored theme on init
  const stored = localStorage.getItem('theme') || 'dark';
  document.documentElement.setAttribute('data-theme', stored);
});
