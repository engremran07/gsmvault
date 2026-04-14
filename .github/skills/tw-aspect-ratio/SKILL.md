---
name: tw-aspect-ratio
description: "Aspect ratio utilities: video, image containers. Use when: embedding videos, maintaining image aspect ratios, responsive media containers."
---

# Aspect Ratio Utilities

## When to Use

- Embedding responsive videos (YouTube, Vimeo)
- Maintaining consistent image dimensions in grids
- Creating placeholder containers with fixed proportions
- Device screenshot/preview containers

## Rules

1. **Use `aspect-*` utilities** — `aspect-video` (16:9), `aspect-square` (1:1)
2. **Images: use `object-cover` with aspect ratio** — crops to fit
3. **Videos: `aspect-video` wrapper** — responsive 16:9
4. **Combine with `w-full`** — height auto-calculates from width

## Patterns

### Responsive Video Embed

```html
<div class="aspect-video w-full rounded-lg overflow-hidden
            bg-[var(--color-bg-secondary)]">
  <iframe src="https://www.youtube.com/embed/VIDEO_ID"
          class="w-full h-full"
          allow="accelerometer; autoplay; encrypted-media"
          allowfullscreen></iframe>
</div>
```

### Image Card with Fixed Aspect Ratio

```html
<div class="rounded-lg overflow-hidden
            bg-[var(--color-bg-secondary)]">
  <div class="aspect-[4/3] w-full">
    <img src="{{ device.image_url }}" alt="{{ device.name }}"
         class="w-full h-full object-cover"
         loading="lazy">
  </div>
  <div class="p-4">
    <h3 class="text-[var(--color-text-primary)] font-medium">
      {{ device.name }}
    </h3>
  </div>
</div>
```

### Aspect Ratio Reference

| Utility | Ratio | Use Case |
|---------|-------|----------|
| `aspect-square` | 1:1 | Avatars, thumbnails, icons |
| `aspect-video` | 16:9 | Video embeds, widescreen images |
| `aspect-[4/3]` | 4:3 | Device screenshots, photos |
| `aspect-[3/2]` | 3:2 | Photography, landscape images |
| `aspect-[9/16]` | 9:16 | Mobile screenshots, stories |
| `aspect-[2/1]` | 2:1 | Banner images, hero sections |

### Device Preview Grid

```html
<div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
  {% for device in devices %}
  <a href="{{ device.get_absolute_url }}" class="group">
    <div class="aspect-square rounded-lg overflow-hidden
                bg-[var(--color-bg-secondary)]
                ring-1 ring-[var(--color-border)]
                group-hover:ring-[var(--color-accent)]
                transition-all duration-200">
      <img src="{{ device.thumbnail_url }}" alt="{{ device.name }}"
           class="w-full h-full object-contain p-4"
           loading="lazy">
    </div>
    <p class="mt-2 text-sm text-center text-[var(--color-text-primary)]
              group-hover:text-[var(--color-accent)]">
      {{ device.name }}
    </p>
  </a>
  {% endfor %}
</div>
```

### Placeholder / Skeleton with Aspect Ratio

```html
<div class="aspect-video w-full rounded-lg
            bg-[var(--color-bg-secondary)] animate-pulse">
  <!-- Empty — serves as loading skeleton -->
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `padding-bottom: 56.25%` hack | Old technique, not needed | `aspect-video` |
| `height: 0` + `padding-bottom` | Fragile, hard to maintain | Use `aspect-*` |
| Fixed pixel `height` on images | Not responsive | `aspect-*` + `object-cover` |
| `object-fit` without aspect ratio container | Image distortion | Wrap in `aspect-*` container |

## Red Flags

- Padding-bottom percentage hack for aspect ratios
- Video embeds without responsive wrapper
- Fixed-height images in responsive grids
- Distorted images (stretched or squished)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `templates/firmwares/firmware_detail.html` — device images
- `templates/components/_card.html` — card component
