/**
 * Ads client-side module — Alpine.js components for anchor, vignette,
 * lazy-loading, refresh, and fill_ad API integration.
 *
 * Loaded via <script defer> in _scripts.html.
 * Components register on `alpine:init` so Alpine picks them up automatically.
 */
document.addEventListener('alpine:init', function () {
  /* ─── Anchor / Sticky Footer Ad ─── */
  Alpine.data('anchorAd', function () {
    return {
      visible: false,
      init: function () {
        var self = this;
        // Show after a short scroll or 3-second delay
        var dismissed = sessionStorage.getItem('anchor_ad_dismissed');
        if (dismissed) return;
        var showTimer = setTimeout(function () { self.show(); }, 3000);
        var scrollHandler = function () {
          if (window.scrollY > 300) {
            self.show();
            window.removeEventListener('scroll', scrollHandler);
            clearTimeout(showTimer);
          }
        };
        window.addEventListener('scroll', scrollHandler, { passive: true });
      },
      show: function () {
        this.visible = true;
      },
      dismiss: function () {
        this.visible = false;
        sessionStorage.setItem('anchor_ad_dismissed', '1');
      }
    };
  });

  /* ─── Vignette / Interstitial Ad ─── */
  Alpine.data('vignetteAd', function () {
    return {
      visible: false,
      countdown: 5,
      pendingUrl: null,
      _timer: null,
      init: function () {
        var self = this;
        // Cooldown: show at most once per 5 minutes
        var COOLDOWN_MS = 5 * 60 * 1000;
        // Intercept internal navigation clicks
        document.addEventListener('click', function (e) {
          var link = e.target.closest('a[href]');
          if (!link) return;
          var href = link.getAttribute('href');
          // Only intercept internal same-origin links
          if (!href || href.startsWith('#') || href.startsWith('javascript:')) return;
          if (link.hasAttribute('download') || link.target === '_blank') return;
          // Check if it's a relative or same-origin link
          try {
            var url = new URL(href, window.location.origin);
            if (url.origin !== window.location.origin) return;
          } catch (_) { return; }
          // Cooldown check
          var lastShown = parseInt(sessionStorage.getItem('vignette_last_shown') || '0', 10);
          if (Date.now() - lastShown < COOLDOWN_MS) return;
          // Session limit: max 3 vignettes per session
          var count = parseInt(sessionStorage.getItem('vignette_count') || '0', 10);
          if (count >= 3) return;
          // Show the vignette and delay navigation
          e.preventDefault();
          self.pendingUrl = href;
          self.openVignette();
        });
      },
      openVignette: function () {
        this.visible = true;
        this.countdown = 5;
        sessionStorage.setItem('vignette_last_shown', String(Date.now()));
        var count = parseInt(sessionStorage.getItem('vignette_count') || '0', 10);
        sessionStorage.setItem('vignette_count', String(count + 1));
        var self = this;
        this._timer = setInterval(function () {
          self.countdown--;
          if (self.countdown <= 0) {
            clearInterval(self._timer);
            self._timer = null;
          }
        }, 1000);
      },
      close: function () {
        if (this.countdown > 0) return; // Can't close yet
        this.visible = false;
        if (this._timer) { clearInterval(this._timer); this._timer = null; }
        // Navigate to the pending URL
        if (this.pendingUrl) {
          window.location.href = this.pendingUrl;
          this.pendingUrl = null;
        }
      }
    };
  });

  /* ─── Lazy-load ad slots via IntersectionObserver ─── */
  function initAdLazyLoad() {
    if (!('IntersectionObserver' in window)) return;
    var slots = document.querySelectorAll('[data-ad-lazy]');
    if (!slots.length) return;
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        var el = entry.target;
        observer.unobserve(el);
        var slotCode = el.getAttribute('data-ad-lazy');
        if (!slotCode) return;
        fillAdSlot(el, slotCode);
      });
    }, { rootMargin: '200px' });
    slots.forEach(function (slot) { observer.observe(slot); });
  }

  /* ─── Client-side ad fill via API ─── */
  function fillAdSlot(el, slotCode) {
    var url = '/ads/api/fill/?placement=' + encodeURIComponent(slotCode) +
              '&page_url=' + encodeURIComponent(window.location.href);
    fetch(url, { credentials: 'same-origin' })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        if (!data.ok || !data.creative) return;
        var creative = data.creative;
        var html = '';
        if (creative.type === 'html' && creative.html) {
          html = creative.html;
        } else if (creative.type === 'script' && creative.html) {
          html = creative.html;
        } else if (creative.type === 'banner' && creative.image_url) {
          var img = '<img src="' + creative.image_url + '" alt="Ad" class="w-full rounded">';
          if (creative.click_url) {
            html = '<a href="' + creative.click_url + '" target="_blank" rel="noopener sponsored">' + img + '</a>';
          } else {
            html = img;
          }
        }
        if (html) {
          el.innerHTML = '<div class="ad-slot ad-slot--' + slotCode + '" data-slot="' + slotCode + '">' + html + '</div>';
        }
      })
      .catch(function () { /* silent fail — ad slots are non-critical */ });
  }

  // Run lazy-load init after DOM ready and after HTMX swaps
  document.addEventListener('DOMContentLoaded', initAdLazyLoad);
  document.addEventListener('htmx:afterSettle', initAdLazyLoad);
});
