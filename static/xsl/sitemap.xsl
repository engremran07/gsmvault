<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:sitemap="http://www.sitemaps.org/schemas/sitemap/0.9"
  xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="sitemap image xhtml">

  <xsl:output method="html" indent="yes" encoding="UTF-8"/>

  <!-- ============================================================
       XSLT Sitemap Stylesheet — GSMFWs Enterprise Platform
       Human-readable + bot-compatible XML sitemap rendering.
       3-theme support: dark (default), light, contrast.
       Reads localStorage('theme') to match site preference.
       CSP is exempted for XML responses — inline styles/scripts OK.
       ============================================================ -->

  <xsl:template match="/">
    <html lang="en">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <meta name="robots" content="noindex, nofollow"/>
        <title>
          <xsl:choose>
            <xsl:when test="sitemap:sitemapindex">Sitemap Index — GSMFWs</xsl:when>
            <xsl:otherwise>XML Sitemap — GSMFWs</xsl:otherwise>
          </xsl:choose>
        </title>
        <!-- Theme init: read localStorage before paint to prevent flash -->
        <script>
          (function(){
            var t = 'dark';
            try { t = localStorage.getItem('theme') || 'dark'; } catch(e) {}
            if (t !== 'dark' &amp;&amp; t !== 'light' &amp;&amp; t !== 'contrast') t = 'dark';
            document.documentElement.setAttribute('data-theme', t);
          })();
        </script>
        <style>
          /* ══ Reset ══ */
          *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

          /* ══════════════════════════════════════════════════════════
             Theme tokens — exact match with site CSS custom properties
             Source: static/css/src/_variables.scss + themes/
             ══════════════════════════════════════════════════════════ */

          /* ── Dark (default) ── */
          :root, [data-theme="dark"] {
            --bg: #0f172a; --bg-card: #1e293b; --bg-row-hover: #334155;
            --text: #f1f5f9; --text-muted: #64748b; --text-heading: #f1f5f9;
            --accent: #3b82f6; --accent-hover: #60a5fa; --accent-text: #ffffff;
            --border: #334155; --border-light: #475569;
            --green: #22c55e; --amber: #f59e0b; --red: #ef4444;
            --badge-daily-bg: rgba(34,197,94,.15); --badge-weekly-bg: rgba(59,130,246,.15);
            --badge-monthly-bg: rgba(245,158,11,.15); --badge-yearly-bg: rgba(239,68,68,.15);
            --badge-hourly-bg: rgba(34,197,94,.25); --badge-always-bg: rgba(34,197,94,.3);
            --badge-never-bg: rgba(100,116,139,.2);
            --font-sans: 'Inter', system-ui, sans-serif;
            --font-mono: 'JetBrains Mono', ui-monospace, monospace;
          }

          /* ── Light ── */
          [data-theme="light"] {
            --bg: #ffffff; --bg-card: #ffffff; --bg-row-hover: #f1f5f9;
            --text: #0f172a; --text-muted: #94a3b8; --text-heading: #0f172a;
            --accent: #2563eb; --accent-hover: #1d4ed8; --accent-text: #ffffff;
            --border: #e2e8f0; --border-light: #cbd5e1;
            --green: #16a34a; --amber: #d97706; --red: #dc2626;
            --badge-daily-bg: rgba(22,163,74,.1); --badge-weekly-bg: rgba(37,99,235,.1);
            --badge-monthly-bg: rgba(217,119,6,.1); --badge-yearly-bg: rgba(220,38,38,.1);
            --badge-hourly-bg: rgba(22,163,74,.15); --badge-always-bg: rgba(22,163,74,.2);
            --badge-never-bg: rgba(100,116,139,.1);
          }

          /* ── High Contrast (WCAG AAA) ── */
          [data-theme="contrast"] {
            --bg: #000000; --bg-card: #1a1a1a; --bg-row-hover: #2d2d2d;
            --text: #ffffff; --text-muted: #b0b0b0; --text-heading: #ffffff;
            --accent: #ffff00; --accent-hover: #ffff66; --accent-text: #000000;
            --border: #ffffff; --border-light: #ffffff;
            --green: #00ff00; --amber: #ffff00; --red: #ff0000;
            --badge-daily-bg: rgba(0,255,0,.2); --badge-weekly-bg: rgba(255,255,0,.2);
            --badge-monthly-bg: rgba(255,255,0,.2); --badge-yearly-bg: rgba(255,0,0,.2);
            --badge-hourly-bg: rgba(0,255,0,.3); --badge-always-bg: rgba(0,255,0,.35);
            --badge-never-bg: rgba(176,176,176,.25);
          }

          /* ══ Base ══ */
          body {
            font-family: var(--font-sans);
            background: var(--bg); color: var(--text);
            line-height: 1.6; -webkit-font-smoothing: antialiased;
          }

          /* ══ Layout ══ */
          .wrapper { max-width: 1200px; margin: 0 auto; padding: 2rem 1.5rem; }

          /* ══ Theme Switcher ══ */
          .theme-bar {
            display: flex; justify-content: flex-end; gap: 0.25rem;
            margin-bottom: 1rem;
          }
          .theme-btn {
            padding: 0.25rem 0.75rem; border-radius: 6px; cursor: pointer;
            font-size: 0.6875rem; font-weight: 600; text-transform: uppercase;
            letter-spacing: 0.04em; border: 1px solid var(--border);
            background: var(--bg-card); color: var(--text-muted);
            transition: all 0.15s ease;
          }
          .theme-btn:hover { border-color: var(--accent); color: var(--accent); }
          .theme-btn.active {
            background: var(--accent); color: var(--accent-text);
            border-color: var(--accent);
          }

          /* ══ Header ══ */
          .header {
            background: var(--bg-card); border: 1px solid var(--border);
            border-radius: 12px; padding: 2rem; margin-bottom: 1.5rem;
          }
          .header-top { display: flex; align-items: center; gap: 1rem; margin-bottom: 1rem; }
          .header-icon {
            width: 48px; height: 48px; border-radius: 12px;
            background: var(--accent);
            display: flex; align-items: center; justify-content: center; flex-shrink: 0;
          }
          .header-icon svg { width: 24px; height: 24px; fill: var(--accent-text); }
          .header h1 {
            font-size: 1.5rem; font-weight: 700; color: var(--text-heading);
            letter-spacing: -0.025em;
          }
          .header p { color: var(--text-muted); font-size: 0.875rem; max-width: 64ch; }
          .header a { color: var(--accent); text-decoration: none; }
          .header a:hover { color: var(--accent-hover); text-decoration: underline; }

          /* ══ Stats Bar ══ */
          .stats { display: flex; flex-wrap: wrap; gap: 0.75rem; margin-bottom: 1.5rem; }
          .stat {
            background: var(--bg-card); border: 1px solid var(--border);
            border-radius: 8px; padding: 0.75rem 1.25rem;
            display: flex; align-items: center; gap: 0.5rem;
          }
          .stat-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
          .stat-label {
            font-size: 0.75rem; color: var(--text-muted);
            text-transform: uppercase; letter-spacing: 0.05em;
          }
          .stat-value {
            font-size: 1.125rem; font-weight: 700; color: var(--text-heading);
            font-variant-numeric: tabular-nums;
          }

          /* ══ Table ══ */
          .table-wrap {
            background: var(--bg-card); border: 1px solid var(--border);
            border-radius: 12px; overflow: hidden;
          }
          table { width: 100%; border-collapse: collapse; font-size: 0.8125rem; }
          thead { background: var(--bg-card); }
          th {
            text-align: left; padding: 0.75rem 1rem;
            font-size: 0.6875rem; font-weight: 600; text-transform: uppercase;
            letter-spacing: 0.05em; color: var(--text-muted);
            border-bottom: 1px solid var(--border);
          }
          td {
            padding: 0.625rem 1rem; border-bottom: 1px solid var(--border);
            vertical-align: middle;
          }
          tr:last-child td { border-bottom: none; }
          tr:hover td { background: var(--bg-row-hover); }

          /* ══ Cell styles ══ */
          .url-cell { max-width: 550px; }
          .url-cell a {
            color: var(--accent); text-decoration: none;
            word-break: break-all; font-family: var(--font-mono); font-size: 0.75rem;
          }
          .url-cell a:hover { color: var(--accent-hover); text-decoration: underline; }
          .badge {
            display: inline-block; padding: 0.125rem 0.5rem; border-radius: 9999px;
            font-size: 0.625rem; font-weight: 600; text-transform: uppercase;
            letter-spacing: 0.05em;
          }
          .badge-daily { background: var(--badge-daily-bg); color: var(--green); }
          .badge-weekly { background: var(--badge-weekly-bg); color: var(--accent); }
          .badge-monthly { background: var(--badge-monthly-bg); color: var(--amber); }
          .badge-yearly { background: var(--badge-yearly-bg); color: var(--red); }
          .badge-hourly { background: var(--badge-hourly-bg); color: var(--green); }
          .badge-always { background: var(--badge-always-bg); color: var(--green); }
          .badge-never { background: var(--badge-never-bg); color: var(--text-muted); }
          .priority-bar {
            width: 60px; height: 6px; border-radius: 3px;
            background: var(--border); overflow: hidden; display: inline-block;
            vertical-align: middle;
          }
          .priority-fill { height: 100%; border-radius: 3px; transition: width 0.3s ease; }
          .date {
            color: var(--text-muted); font-family: var(--font-mono);
            font-size: 0.75rem; white-space: nowrap;
          }
          .row-num {
            color: var(--text-muted); font-family: var(--font-mono);
            font-size: 0.6875rem; text-align: center;
          }

          /* ══ Section label ══ */
          .section-label {
            display: inline-block; padding: 0.125rem 0.5rem; border-radius: 4px;
            font-size: 0.625rem; font-weight: 600; text-transform: uppercase;
            letter-spacing: 0.04em; background: var(--badge-weekly-bg); color: var(--accent);
          }

          /* ══ Footer ══ */
          .footer {
            text-align: center; padding: 2rem 1rem; font-size: 0.75rem;
            color: var(--text-muted);
          }
          .footer a { color: var(--accent); text-decoration: none; }
          .footer a:hover { text-decoration: underline; }

          /* ══ Responsive ══ */
          @media (max-width: 768px) {
            .wrapper { padding: 1rem; }
            .header { padding: 1.25rem; }
            .header h1 { font-size: 1.25rem; }
            th, td { padding: 0.5rem 0.625rem; }
            .url-cell { max-width: 260px; }
            .hide-mobile { display: none; }
            .theme-bar { justify-content: center; }
          }
        </style>
      </head>
      <body>
        <div class="wrapper">
          <!-- Theme switcher (matches site's 3-theme system) -->
          <div class="theme-bar">
            <button class="theme-btn" onclick="setTheme('dark')" id="t-dark">Dark</button>
            <button class="theme-btn" onclick="setTheme('light')" id="t-light">Light</button>
            <button class="theme-btn" onclick="setTheme('contrast')" id="t-contrast">Contrast</button>
          </div>
          <!-- Sitemap Index view -->
          <xsl:apply-templates select="sitemap:sitemapindex"/>
          <!-- URL Set view -->
          <xsl:apply-templates select="sitemap:urlset"/>
        </div>
        <footer class="footer">
          <p>Generated by <a href="https://www.sitemaps.org/">Sitemaps.org</a> protocol.
          Powered by the GSMFWs Enterprise Platform.</p>
        </footer>
        <!-- Theme switcher script -->
        <script>
          function setTheme(t) {
            document.documentElement.setAttribute('data-theme', t);
            try { localStorage.setItem('theme', t); } catch(e) {}
            updateBtns(t);
          }
          function updateBtns(t) {
            ['dark','light','contrast'].forEach(function(n) {
              var b = document.getElementById('t-' + n);
              if (b) { b.className = n === t ? 'theme-btn active' : 'theme-btn'; }
            });
          }
          updateBtns(document.documentElement.getAttribute('data-theme') || 'dark');
        </script>
      </body>
    </html>
  </xsl:template>

  <!-- ============================================================
       SITEMAP INDEX (categorized sections)
       ============================================================ -->
  <xsl:template match="sitemap:sitemapindex">
    <header class="header">
      <div class="header-top">
        <div class="header-icon">
          <svg viewBox="0 0 24 24"><path d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"/></svg>
        </div>
        <div>
          <h1>Sitemap Index</h1>
          <p>This index organizes all URLs by content type. Each section contains URLs
          for a specific category — brands, models, blog posts, pages, tags, and more.
          Search engines use these to discover and crawl pages efficiently.</p>
        </div>
      </div>
    </header>

    <div class="stats">
      <div class="stat">
        <div class="stat-dot" style="background: var(--accent);"></div>
        <div>
          <div class="stat-label">Sections</div>
          <div class="stat-value"><xsl:value-of select="count(sitemap:sitemap)"/></div>
        </div>
      </div>
    </div>

    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th style="width: 40px;">#</th>
            <th>Section</th>
            <th>Sitemap URL</th>
            <th class="hide-mobile" style="width: 180px;">Last Modified</th>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select="sitemap:sitemap">
            <xsl:variable name="loc" select="sitemap:loc"/>
            <!-- Extract section name from URL pattern sitemap-{section}.xml -->
            <xsl:variable name="filename" select="substring-after($loc, 'sitemap-')"/>
            <xsl:variable name="section" select="substring-before($filename, '.xml')"/>
            <tr>
              <td class="row-num"><xsl:value-of select="position()"/></td>
              <td>
                <xsl:if test="string-length($section) &gt; 0">
                  <span class="section-label"><xsl:value-of select="$section"/></span>
                </xsl:if>
              </td>
              <td class="url-cell">
                <a href="{sitemap:loc}"><xsl:value-of select="sitemap:loc"/></a>
              </td>
              <td class="hide-mobile date">
                <xsl:if test="sitemap:lastmod">
                  <xsl:value-of select="substring(sitemap:lastmod, 1, 10)"/>
                </xsl:if>
              </td>
            </tr>
          </xsl:for-each>
        </tbody>
      </table>
    </div>
  </xsl:template>

  <!-- ============================================================
       URL SET (individual sitemap section)
       ============================================================ -->
  <xsl:template match="sitemap:urlset">
    <header class="header">
      <div class="header-top">
        <div class="header-icon">
          <svg viewBox="0 0 24 24"><path d="M10 13a5 5 0 007.54.54l3-3a5 5 0 00-7.07-7.07l-1.72 1.71M14 11a5 5 0 00-7.54-.54l-3 3a5 5 0 007.07 7.07l1.71-1.71"/></svg>
        </div>
        <div>
          <h1>XML Sitemap</h1>
          <p>This sitemap contains <strong><xsl:value-of select="count(sitemap:url)"/></strong> URLs.
          Search engines use this file to discover and index pages on this website.
          <a href="/sitemap.xml">&#8592; Back to Sitemap Index</a></p>
        </div>
      </div>
    </header>

    <div class="stats">
      <div class="stat">
        <div class="stat-dot" style="background: var(--accent);"></div>
        <div>
          <div class="stat-label">Total URLs</div>
          <div class="stat-value"><xsl:value-of select="count(sitemap:url)"/></div>
        </div>
      </div>
      <xsl:if test="sitemap:url/sitemap:changefreq">
        <div class="stat">
          <div class="stat-dot" style="background: var(--green);"></div>
          <div>
            <div class="stat-label">Daily</div>
            <div class="stat-value"><xsl:value-of select="count(sitemap:url[sitemap:changefreq='daily'])"/></div>
          </div>
        </div>
        <div class="stat">
          <div class="stat-dot" style="background: var(--amber);"></div>
          <div>
            <div class="stat-label">Weekly</div>
            <div class="stat-value"><xsl:value-of select="count(sitemap:url[sitemap:changefreq='weekly'])"/></div>
          </div>
        </div>
        <div class="stat">
          <div class="stat-dot" style="background: var(--red);"></div>
          <div>
            <div class="stat-label">Monthly</div>
            <div class="stat-value"><xsl:value-of select="count(sitemap:url[sitemap:changefreq='monthly'])"/></div>
          </div>
        </div>
      </xsl:if>
    </div>

    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th style="width: 40px;">#</th>
            <th>URL</th>
            <th class="hide-mobile" style="width: 90px;">Priority</th>
            <th class="hide-mobile" style="width: 90px;">Frequency</th>
            <th class="hide-mobile" style="width: 120px;">Last Modified</th>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select="sitemap:url">
            <tr>
              <td class="row-num"><xsl:value-of select="position()"/></td>
              <td class="url-cell">
                <a href="{sitemap:loc}"><xsl:value-of select="sitemap:loc"/></a>
              </td>
              <td class="hide-mobile">
                <xsl:if test="sitemap:priority">
                  <xsl:variable name="pct" select="sitemap:priority * 100"/>
                  <div class="priority-bar">
                    <div class="priority-fill">
                      <xsl:attribute name="style">
                        width: <xsl:value-of select="$pct"/>%;
                        background: <xsl:choose>
                          <xsl:when test="sitemap:priority &gt;= 0.8">var(--green)</xsl:when>
                          <xsl:when test="sitemap:priority &gt;= 0.5">var(--accent)</xsl:when>
                          <xsl:when test="sitemap:priority &gt;= 0.3">var(--amber)</xsl:when>
                          <xsl:otherwise>var(--red)</xsl:otherwise>
                        </xsl:choose>;
                      </xsl:attribute>
                    </div>
                  </div>
                  <span style="margin-left: 6px; font-size: 0.6875rem; color: var(--text-muted);">
                    <xsl:value-of select="sitemap:priority"/>
                  </span>
                </xsl:if>
              </td>
              <td class="hide-mobile">
                <xsl:if test="sitemap:changefreq">
                  <span>
                    <xsl:attribute name="class">
                      badge badge-<xsl:value-of select="sitemap:changefreq"/>
                    </xsl:attribute>
                    <xsl:value-of select="sitemap:changefreq"/>
                  </span>
                </xsl:if>
              </td>
              <td class="hide-mobile date">
                <xsl:if test="sitemap:lastmod">
                  <xsl:value-of select="substring(sitemap:lastmod, 1, 10)"/>
                </xsl:if>
              </td>
            </tr>
          </xsl:for-each>
        </tbody>
      </table>
    </div>
  </xsl:template>

</xsl:stylesheet>
