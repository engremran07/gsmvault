---
name: services-pdf-generation
description: "PDF generation with reportlab/weasyprint. Use when: generating invoices, receipts, reports, tickets, or any printable document from Django data."
---

# PDF Generation Patterns

## When to Use
- Generating invoices or receipts for wallet transactions
- Creating downloadable reports (analytics, audit logs)
- Producing firmware certificates or verification reports
- Export-to-PDF for any model data

## Rules
- Generate PDFs in service functions — never in views
- Use Celery for large/slow PDF generation
- Stream PDFs with `FileResponse` — don't buffer entire file in memory
- Cache generated PDFs if content is static (e.g., monthly reports)
- Sanitize all user-supplied content before embedding in PDFs

## Patterns

### ReportLab — Simple PDF
```python
import io
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table
from reportlab.lib.styles import getSampleStyleSheet

def generate_invoice_pdf(*, order_id: int) -> io.BytesIO:
    """Generate invoice PDF for an order."""
    from apps.shop.models import Order
    order = Order.objects.select_related("user").prefetch_related("items").get(pk=order_id)

    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4)
    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph(f"Invoice #{order.pk}", styles["Title"]))
    elements.append(Spacer(1, 1 * cm))
    elements.append(Paragraph(f"Customer: {order.user.get_full_name()}", styles["Normal"]))
    elements.append(Spacer(1, 0.5 * cm))

    # Items table
    data = [["Item", "Qty", "Price"]]
    for item in order.items.all():  # type: ignore[attr-defined]
        data.append([item.product.name, str(item.quantity), f"${item.price}"])
    data.append(["", "Total:", f"${order.total}"])

    table = Table(data, colWidths=[10 * cm, 3 * cm, 3 * cm])
    elements.append(table)

    doc.build(elements)
    buffer.seek(0)
    return buffer
```

### Serving PDF in View
```python
from django.http import FileResponse

def download_invoice(request, order_id: int):
    """View that serves generated PDF."""
    from . import services
    pdf_buffer = services.generate_invoice_pdf(order_id=order_id)
    return FileResponse(
        pdf_buffer,
        as_attachment=True,
        filename=f"invoice_{order_id}.pdf",
        content_type="application/pdf",
    )
```

### WeasyPrint — HTML to PDF
```python
from django.template.loader import render_to_string
import weasyprint  # type: ignore[import-untyped]

def generate_report_pdf(*, report_data: dict) -> bytes:
    """Generate PDF from HTML template using WeasyPrint."""
    html_string = render_to_string("reports/monthly_report.html", report_data)
    pdf_bytes = weasyprint.HTML(string=html_string).write_pdf()
    return pdf_bytes
```

### Async PDF Generation via Celery
```python
# apps/analytics/tasks.py
from celery import shared_task

@shared_task
def generate_monthly_report(month: int, year: int) -> str:
    """Generate monthly report PDF asynchronously."""
    from . import services
    report_data = services.compile_monthly_data(month=month, year=year)
    pdf_bytes = services.generate_report_pdf(report_data=report_data)
    # Store to file storage
    path = f"reports/{year}/{month:02d}/monthly_report.pdf"
    default_storage.save(path, ContentFile(pdf_bytes))
    return path
```

## Anti-Patterns
- Generating PDFs synchronously for large reports — use Celery
- Embedding unsanitized user content in PDFs — XSS via PDF injection
- Buffering entire PDF in memory for large files — use streaming
- Hardcoding styles instead of using templates

## Red Flags
- PDF generation in view function instead of service
- No size limit on generated PDFs
- User-supplied HTML injected directly into PDF without sanitization

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
