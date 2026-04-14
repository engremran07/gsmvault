---
name: seo-jsonld-product
description: "JSON-LD Product schema. Use when: adding product structured data to shop/marketplace listings, product rich snippets, e-commerce pages."
---

# JSON-LD Product Schema

## When to Use

- Adding structured data to `apps.shop` product pages
- Marketplace listing rich snippets
- Any page displaying a purchasable item

## Rules

### Schema Structure

```python
# apps/seo/services.py
def build_product_schema(
    name: str,
    description: str,
    price: str,
    currency: str = "USD",
    image: str | None = None,
    brand: str | None = None,
    sku: str | None = None,
    availability: str = "InStock",
    url: str = "",
    rating: float | None = None,
    review_count: int | None = None,
) -> dict:
    """Build JSON-LD Product schema."""
    schema: dict = {
        "@context": "https://schema.org",
        "@type": "Product",
        "name": name,
        "description": description[:200],
        "offers": {
            "@type": "Offer",
            "price": price,
            "priceCurrency": currency,
            "availability": f"https://schema.org/{availability}",
            "url": url,
        },
    }
    if image:
        schema["image"] = image
    if brand:
        schema["brand"] = {"@type": "Brand", "name": brand}
    if sku:
        schema["sku"] = sku
    if rating is not None and review_count:
        schema["aggregateRating"] = {
            "@type": "AggregateRating",
            "ratingValue": str(round(rating, 1)),
            "reviewCount": str(review_count),
        }
    return schema
```

### Availability Values

| Value | Meaning |
|-------|---------|
| `InStock` | Available for purchase |
| `OutOfStock` | Currently unavailable |
| `PreOrder` | Available for pre-order |
| `Discontinued` | No longer available |
| `LimitedAvailability` | Low stock |

### Shop Integration

```python
def build_shop_product_schema(product, site_url: str) -> dict:
    """Build Product schema from shop product model."""
    return build_product_schema(
        name=product.name,
        description=product.description or "",
        price=str(product.price),
        currency="USD",
        image=f"{site_url}{product.image.url}" if product.image else None,
        brand=product.brand_name if hasattr(product, "brand_name") else None,
        sku=product.sku or None,
        url=f"{site_url}/shop/{product.slug}/",
    )
```

## Anti-Patterns

- Product schema on non-product pages — only on actual product/listing pages
- Missing `offers` — Google requires it for Product schema
- Availability not matching actual stock — must be synced

## Red Flags

- `price` is empty or "0" for paid products
- `availability` URL missing `https://schema.org/` prefix
- `description` contains raw HTML tags

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
