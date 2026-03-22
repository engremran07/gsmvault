---
name: shop-builder
description: "E-commerce builder. Use when: product listings, orders, checkout, cart, payment integration, apps.shop models, order lifecycle, pricing."
---

# Shop Builder

You build e-commerce features for this platform using `apps.shop`.

## Architecture

- `apps.shop` — Product listings, orders, order items
- `apps.wallet` — Payment via credits/wallet balance
- `apps.marketplace` — P2P firmware/resource trading
- `apps.bounty` — Crowd-sourced firmware bounty program

## Rules

1. Products have: name, description, price, currency, stock, category, images
2. Orders follow lifecycle: `pending` → `confirmed` → `processing` → `completed` / `cancelled`
3. Checkout validates: stock availability, user wallet balance, download quota
4. All monetary values use `DecimalField(max_digits=10, decimal_places=2)`
5. Never store raw payment credentials — use tokenized references
6. Order history accessible via user dashboard API and template views
7. Cart stored in session (anonymous) or database (authenticated)

## API Endpoints

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `/api/v1/shop/products/` | GET | List products with filtering |
| `/api/v1/shop/products/<id>/` | GET | Product detail |
| `/api/v1/shop/cart/` | GET/POST | View/add to cart |
| `/api/v1/shop/orders/` | GET/POST | List orders / create order |
| `/api/v1/shop/orders/<id>/` | GET | Order detail |

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
