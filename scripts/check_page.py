"""Quick diagnostic: verify CSP nonces, script order, and page rendering."""

import re
import sys

import requests


def main():
    try:
        r = requests.get("http://127.0.0.1:8000/", timeout=5)
    except Exception as e:
        print(f"Error: {e}")
        print("Is the dev server running on port 8000?")
        sys.exit(1)

    print(f"Status: {r.status_code}")
    print()

    # CSP header
    csp = r.headers.get("Content-Security-Policy", "NOT SET")
    print(f"CSP: {csp[:500]}")
    print()

    # Nonce consistency
    nonce_pattern = r"nonce-([A-Za-z0-9_-]+)"
    nonces_csp = set(re.findall(nonce_pattern, csp))
    nonces_html = set(re.findall(r'nonce="([A-Za-z0-9_-]+)"', r.text))
    print(f"Nonces in CSP: {nonces_csp}")
    print(f"Nonces in HTML: {nonces_html}")
    print(f"Match: {nonces_csp == nonces_html}")
    print()

    # Script presence
    for name in [
        "alpinejs",
        "tailwindcss/browser",
        "notifications.js",
        "theme-switcher.js",
        "htmx.org",
        "lucide",
    ]:
        found = name in r.text
        print(f"  {name}: {'FOUND' if found else 'MISSING'}")

    # Script order - find the ACTUAL script tags, not just mentions
    # Find all <script> tags with their src
    script_tags = re.findall(r'<script[^>]*src="([^"]*)"[^>]*>', r.text)
    print()
    print("--- Script tags in order ---")
    for i, src in enumerate(script_tags):
        short = src.split("/")[-1][:60]
        pos = r.text.find(f'src="{src}"')
        defer_tag = "defer" in r.text[max(0, pos - 100) : pos + len(src) + 100]
        print(f"  {i}: [{pos:5d}] {'(defer)' if defer_tag else '       '} {short}")

    # Check if Alpine CDN is after stores
    alpine_cdn_pos = r.text.find('alpinejs@3/dist/cdn.min.js"')
    notify_script_pos = r.text.find('notifications.js"')
    theme_script_pos = r.text.find('theme-switcher.js"')
    print()
    print(f"Alpine CDN tag at: {alpine_cdn_pos}")
    print(f"theme-switcher tag at: {theme_script_pos}")
    print(f"notifications tag at: {notify_script_pos}")
    if alpine_cdn_pos > 0 and notify_script_pos > 0 and theme_script_pos > 0:
        if theme_script_pos < alpine_cdn_pos and notify_script_pos < alpine_cdn_pos:
            print("ORDER: CORRECT (stores before Alpine CDN)")
        else:
            print("ORDER: WRONG (Alpine CDN before stores!)")
    else:
        print("ORDER: Cannot determine")

    # Check for fullscreen overlays
    print()
    print("--- Overlay elements in HTML ---")
    # Check for elements with fixed inset-0 that are NOT cloaked
    overlay_pattern = r'<div[^>]*class="[^"]*fixed[^"]*inset-0[^"]*"[^>]*>'
    overlays = re.findall(overlay_pattern, r.text)
    for o in overlays:
        has_cloak = "x-cloak" in o
        print(f"  {'[CLOAKED]' if has_cloak else '[VISIBLE]'} {o[:200]}")

    # Check for confirm dialog
    if "$store.confirm" in r.text:
        print("\n$store.confirm references found")
    if "$store.notify" in r.text:
        print("$store.notify references found")

    # Check for visible loading bars / progress bars
    toast_prog_count = r.text.count("toast-progress")
    print(f"\ntoast-progress occurrences: {toast_prog_count}")

    # Check if there are SERVER-RENDERED toasts (from Django messages)
    server_toast_count = r.text.count("show: true, progress: 100")
    print(f"Server-rendered toasts (Django messages): {server_toast_count}")

    # Check the area between toast-container and template x-for
    idx = r.text.find("toast-container")
    if idx > 0:
        area = r.text[idx : idx + 500]
        template_idx = area.find("template x-for")
        between = area[:template_idx].strip() if template_idx > 0 else area.strip()
        # Count lines
        lines = [line.strip() for line in between.split("\n") if line.strip()]
        print(f"\nBetween toast-container and template x-for: {len(lines)} lines")
        if server_toast_count == 0:
            print(
                "  => NO server-rendered Django messages. The toast-progress is only in Alpine template."
            )

    # Print the raw HTML around the confirm dialog area
    print()
    confirm_idx = r.text.find("_confirm_dialog")
    if confirm_idx == -1:
        confirm_idx = r.text.find("store.confirm.open")
    if confirm_idx > 0:
        print(f"--- Around confirm dialog (pos {confirm_idx}) ---")
    else:
        print("Confirm dialog not found in HTML")

    # Print the last bit of the body (scripts area)
    body_end = r.text.rfind("</body>")
    if body_end > 0:
        scripts_area = r.text[max(0, body_end - 3000) : body_end]
        print()
        print("--- Last 3000 chars before </body> ---")
        print(scripts_area)


if __name__ == "__main__":
    main()
