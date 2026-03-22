/**
 * static/js/src/admin-charts.js — Alpine.js Chart.js integration
 * Theme-aware charts that auto-update colors on theme switch.
 * Usage in templates:
 *   <div x-data="adminChart({
 *     type: 'line',
 *     labels: {{ chart_labels|safe }},
 *     datasets: {{ chart_datasets|safe }}
 *   })" x-init="init($refs.canvas)">
 *     <canvas x-ref="canvas" height="200"></canvas>
 *   </div>
 */
document.addEventListener('alpine:init', () => {

  /**
   * Read a CSS custom property from :root.
   */
  function getCSSVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  }

  /**
   * Build Chart.js-compatible color palette from theme tokens.
   */
  function themeColors() {
    return {
      accent: getCSSVar('--color-accent'),
      accentSoft: getCSSVar('--color-accent-soft'),
      success: getCSSVar('--color-success'),
      warning: getCSSVar('--color-warning'),
      error: getCSSVar('--color-error'),
      info: getCSSVar('--color-info'),
      text: getCSSVar('--color-text-secondary'),
      textMuted: getCSSVar('--color-text-muted'),
      border: getCSSVar('--color-border'),
      grid: getCSSVar('--color-border'),
      bg: getCSSVar('--color-bg-secondary'),
    };
  }

  /**
   * Predefined color palette for multi-series charts (pie, doughnut, bar).
   */
  function chartPalette() {
    return [
      getCSSVar('--color-accent'),
      getCSSVar('--color-success'),
      getCSSVar('--color-warning'),
      getCSSVar('--color-error'),
      getCSSVar('--color-info'),
      '#8b5cf6', // violet
      '#ec4899', // pink
      '#14b8a6', // teal
      '#f97316', // orange
      '#6366f1', // indigo
    ];
  }

  /**
   * Default chart options — dark-friendly, minimal, clean.
   */
  function defaultOptions(type, colors) {
    const base = {
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 600, easing: 'easeOutQuart' },
      plugins: {
        legend: {
          display: false,
          labels: { color: colors.text, font: { family: "'Inter', sans-serif", size: 12 } }
        },
        tooltip: {
          backgroundColor: colors.bg,
          titleColor: colors.text,
          bodyColor: colors.text,
          borderColor: colors.border,
          borderWidth: 1,
          padding: 10,
          cornerRadius: 8,
          titleFont: { family: "'Inter', sans-serif", weight: '600' },
          bodyFont: { family: "'Inter', sans-serif" },
        },
      },
    };

    if (type === 'line' || type === 'bar') {
      base.scales = {
        x: {
          grid: { color: 'transparent' },
          ticks: { color: colors.textMuted, font: { family: "'Inter', sans-serif", size: 11 } },
          border: { display: false },
        },
        y: {
          grid: { color: colors.grid + '20' },
          ticks: { color: colors.textMuted, font: { family: "'Inter', sans-serif", size: 11 } },
          border: { display: false },
          beginAtZero: true,
        },
      };
    }

    if (type === 'doughnut' || type === 'pie') {
      base.plugins.legend.display = true;
      base.plugins.legend.position = 'bottom';
      base.cutout = type === 'doughnut' ? '70%' : 0;
    }

    return base;
  }

  /**
   * Apply theme colors to datasets based on chart type.
   */
  function applyDatasetColors(type, datasets, colors) {
    const palette = chartPalette();
    return datasets.map((ds, i) => {
      const copy = { ...ds };

      if (type === 'line') {
        copy.borderColor = copy.borderColor || palette[i % palette.length];
        copy.backgroundColor = copy.backgroundColor || (copy.borderColor + '20');
        copy.borderWidth = copy.borderWidth || 2;
        copy.pointRadius = copy.pointRadius ?? 0;
        copy.pointHoverRadius = copy.pointHoverRadius ?? 4;
        copy.tension = copy.tension ?? 0.3;
        copy.fill = copy.fill ?? true;
      } else if (type === 'bar') {
        copy.backgroundColor = copy.backgroundColor || palette[i % palette.length] + '80';
        copy.borderColor = copy.borderColor || palette[i % palette.length];
        copy.borderWidth = copy.borderWidth || 1;
        copy.borderRadius = copy.borderRadius ?? 4;
      } else if (type === 'doughnut' || type === 'pie') {
        if (!copy.backgroundColor || !Array.isArray(copy.backgroundColor)) {
          copy.backgroundColor = palette.slice(0, (copy.data || []).length);
        }
        copy.borderWidth = 0;
      }

      return copy;
    });
  }

  /**
   * Alpine.js data component: adminChart
   * @param {Object} config - { type, labels, datasets, options }
   */
  Alpine.data('adminChart', (config) => ({
    chart: null,

    init(canvas) {
      if (typeof Chart === 'undefined') return;

      const colors = themeColors();
      const type = config.type || 'line';
      const datasets = applyDatasetColors(type, config.datasets || [], colors);
      const mergedOptions = {
        ...defaultOptions(type, colors),
        ...(config.options || {}),
      };

      this.chart = new Chart(canvas, {
        type: type,
        data: {
          labels: config.labels || [],
          datasets: datasets,
        },
        options: mergedOptions,
      });

      // Re-render on theme change
      this._themeObserver = new MutationObserver(() => {
        this._updateTheme();
      });
      this._themeObserver.observe(document.documentElement, {
        attributes: true,
        attributeFilter: ['data-theme'],
      });
    },

    _updateTheme() {
      if (!this.chart) return;
      const colors = themeColors();
      const type = this.chart.config.type;

      // Update datasets
      this.chart.data.datasets = applyDatasetColors(
        type,
        this.chart.data.datasets.map(ds => ({
          ...ds,
          borderColor: undefined,
          backgroundColor: undefined,
        })),
        colors
      );

      // Update scales
      if (this.chart.options.scales) {
        if (this.chart.options.scales.x) {
          this.chart.options.scales.x.ticks.color = colors.textMuted;
        }
        if (this.chart.options.scales.y) {
          this.chart.options.scales.y.ticks.color = colors.textMuted;
          this.chart.options.scales.y.grid.color = colors.grid + '20';
        }
      }

      // Update tooltip
      if (this.chart.options.plugins && this.chart.options.plugins.tooltip) {
        this.chart.options.plugins.tooltip.backgroundColor = colors.bg;
        this.chart.options.plugins.tooltip.titleColor = colors.text;
        this.chart.options.plugins.tooltip.bodyColor = colors.text;
        this.chart.options.plugins.tooltip.borderColor = colors.border;
      }

      // Update legend
      if (this.chart.options.plugins && this.chart.options.plugins.legend) {
        this.chart.options.plugins.legend.labels.color = colors.text;
      }

      this.chart.update('none');
    },

    destroy() {
      if (this._themeObserver) this._themeObserver.disconnect();
      if (this.chart) {
        this.chart.destroy();
        this.chart = null;
      }
    },
  }));

  /**
   * Alpine.js data component: animatedCounter
   * Animates a number from 0 to target value.
   * Usage: <span x-data="animatedCounter(1234)" x-text="display"></span>
   */
  Alpine.data('animatedCounter', (target, duration = 1200) => ({
    display: 0,
    target: target || 0,
    init() {
      const start = performance.now();
      const step = (now) => {
        const elapsed = now - start;
        const progress = Math.min(elapsed / duration, 1);
        // ease-out cubic
        const eased = 1 - Math.pow(1 - progress, 3);
        this.display = Math.round(eased * this.target);
        if (progress < 1) requestAnimationFrame(step);
      };
      requestAnimationFrame(step);
    },
  }));
});
