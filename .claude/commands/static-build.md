# /static-build â€” Build and collect static assets

Compile SCSS, minify JS, update vendor libraries, and run collectstatic for deployment readiness.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Compile SCSS

- [ ] Compile main SCSS: `tailwindcss -i static/css/src/main.scss -o static/css/dist/main.css`

- [ ] For production (minified): `tailwindcss -i static/css/src/main.scss -o static/css/dist/main.css --minify`

- [ ] Verify `static/css/dist/main.css` is generated and non-empty

### Step 2: Check Vendor Libraries

- [ ] Verify local fallback copies exist in `static/vendor/`

- [ ] Check versions: Tailwind CSS v4, Alpine.js v3, HTMX v2, Lucide Icons v0.460+

- [ ] Confirm CDN fallback chain: jsDelivr â†’ cdnjs â†’ unpkg â†’ local vendor

### Step 3: Validate JS Modules

- [ ] Check `static/js/src/` for syntax errors

- [ ] Verify theme-switcher, ajax, notifications, alpine-components are present

- [ ] No console.log statements in production JS (only console.error/warn for real errors)

### Step 4: Collect Static Files

- [ ] Run: `& .\.venv\Scripts\python.exe manage.py collectstatic --noinput --settings=app.settings_dev`

- [ ] Verify collected files count

### Step 5: Check Font Assets

- [ ] Verify WOFF2 fonts present: Inter, JetBrains Mono in `static/fonts/`

- [ ] Check font-face declarations in SCSS reference correct paths

### Step 6: Validate

- [ ] Open dev server and verify styles load: `& .\.venv\Scripts\python.exe manage.py runserver --settings=app.settings_dev`

- [ ] Check browser DevTools for 404s on static files

- [ ] Verify all three themes render correctly
