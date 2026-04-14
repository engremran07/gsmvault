---
name: services-ab-testing
description: "A/B testing patterns: variant assignment, result tracking, statistical significance. Use when: testing UI variations, optimizing conversions, split testing features."
---

# A/B Testing Patterns

## When to Use
- Testing different UI layouts for conversion optimization
- Comparing ad placement strategies
- Testing pricing/tier changes
- Optimizing download flow (ad-gate vs direct)

## Rules
- Variant assignment MUST be deterministic per user — same user always sees same variant
- Store assignments in the database for analysis
- Track conversions per variant with timestamps
- Use hash-based assignment — no randomness (reproducible)
- Minimum sample size before drawing conclusions

## Patterns

### Experiment Model
```python
class Experiment(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField(null=True, blank=True)
    variants = models.JSONField(default=list)  # ["control", "variant_a", "variant_b"]
    traffic_percentage = models.IntegerField(default=100)  # % of users included

    class Meta:
        db_table = "analytics_experiment"
        verbose_name = "A/B Experiment"

class ExperimentAssignment(models.Model):
    experiment = models.ForeignKey(Experiment, on_delete=models.CASCADE, related_name="assignments")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    variant = models.CharField(max_length=50)
    assigned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("experiment", "user")

class ExperimentConversion(models.Model):
    assignment = models.ForeignKey(ExperimentAssignment, on_delete=models.CASCADE)
    conversion_type = models.CharField(max_length=50)  # "click", "download", "purchase"
    converted_at = models.DateTimeField(auto_now_add=True)
    metadata = models.JSONField(default=dict)
```

### Deterministic Variant Assignment
```python
import hashlib

def get_variant(*, experiment_name: str, user_id: int, variants: list[str]) -> str:
    """Deterministic variant assignment based on user+experiment hash."""
    hash_input = f"{experiment_name}:{user_id}".encode()
    hash_value = int(hashlib.md5(hash_input).hexdigest(), 16)  # noqa: S324
    index = hash_value % len(variants)
    return variants[index]

def assign_user_to_experiment(*, experiment: Experiment, user_id: int) -> str:
    """Assign user to experiment variant (idempotent)."""
    assignment, created = ExperimentAssignment.objects.get_or_create(
        experiment=experiment,
        user_id=user_id,
        defaults={"variant": get_variant(
            experiment_name=experiment.name,
            user_id=user_id,
            variants=experiment.variants,
        )},
    )
    return assignment.variant
```

### Tracking Conversions
```python
def track_conversion(
    *, experiment_name: str, user_id: int, conversion_type: str, metadata: dict | None = None
) -> None:
    """Record a conversion event for an experiment."""
    try:
        assignment = ExperimentAssignment.objects.get(
            experiment__name=experiment_name, user_id=user_id
        )
        ExperimentConversion.objects.create(
            assignment=assignment,
            conversion_type=conversion_type,
            metadata=metadata or {},
        )
    except ExperimentAssignment.DoesNotExist:
        pass  # User not in experiment
```

### Using in Views
```python
def download_page(request, firmware_id: int):
    variant = "control"
    if request.user.is_authenticated:
        experiment = Experiment.objects.filter(name="download_flow_v2", is_active=True).first()
        if experiment:
            variant = assign_user_to_experiment(experiment=experiment, user_id=request.user.pk)
    template = f"firmwares/download_{variant}.html"
    return render(request, template, {"firmware_id": firmware_id})
```

### Results Analysis
```python
def get_experiment_results(experiment_name: str) -> dict:
    """Get conversion rates per variant."""
    from django.db.models import Count, Q
    assignments = ExperimentAssignment.objects.filter(experiment__name=experiment_name)
    results = assignments.values("variant").annotate(
        total=Count("pk"),
        conversions=Count("pk", filter=Q(experimentconversion__isnull=False)),
    )
    return {r["variant"]: {"total": r["total"], "conversions": r["conversions"],
            "rate": r["conversions"] / r["total"] if r["total"] else 0} for r in results}
```

## Anti-Patterns
- Random variant assignment — user sees different variants on each visit
- No conversion tracking — can't measure results
- Running experiments without sufficient sample size
- Experiments without end dates — run forever

## Red Flags
- `random.choice()` for variant selection → use deterministic hash
- No `unique_together` on assignment → duplicate assignments
- Experiment without `is_active` flag → can't stop it

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
