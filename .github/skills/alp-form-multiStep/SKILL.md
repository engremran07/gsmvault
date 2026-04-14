---
name: alp-form-multiStep
description: "Multi-step form wizard with Alpine state. Use when: registration wizards, checkout flows, multi-page data entry, firmware upload wizards."
---

# Alpine Multi-Step Form Wizard

## When to Use

- Multi-step registration or checkout flows
- Complex data entry split across logical steps
- Firmware upload wizard (select file → metadata → confirm)

## Patterns

### Basic Step Wizard

```html
<div x-data="{
  step: 1,
  totalSteps: 3,
  formData: { name: '', email: '', plan: '' },
  nextStep() { if (this.step < this.totalSteps) this.step++; },
  prevStep() { if (this.step > 1) this.step--; },
  submit() {
    fetch('/api/v1/register/', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRFToken': document.querySelector('[name=csrfmiddlewaretoken]').value,
      },
      body: JSON.stringify(this.formData),
    });
  }
}">
  <!-- Progress bar -->
  <div class="flex gap-2 mb-6">
    <template x-for="i in totalSteps" :key="i">
      <div class="flex-1 h-2 rounded"
           :class="i <= step ? 'bg-[var(--color-accent)]' : 'bg-[var(--color-border)]'">
      </div>
    </template>
  </div>

  <form @submit.prevent="submit()">
    {% csrf_token %}

    <!-- Step 1 -->
    <div x-show="step === 1" x-cloak>
      <h3 class="text-lg font-semibold mb-4">Account Info</h3>
      <input x-model="formData.name" type="text" placeholder="Name" required
             class="w-full mb-3 px-3 py-2 rounded border border-[var(--color-border)]">
      <input x-model="formData.email" type="email" placeholder="Email" required
             class="w-full mb-3 px-3 py-2 rounded border border-[var(--color-border)]">
    </div>

    <!-- Step 2 -->
    <div x-show="step === 2" x-cloak>
      <h3 class="text-lg font-semibold mb-4">Choose Plan</h3>
      <template x-for="plan in ['free', 'pro', 'premium']" :key="plan">
        <label class="block p-3 mb-2 rounded border cursor-pointer"
               :class="formData.plan === plan ? 'border-[var(--color-accent)]' : 'border-[var(--color-border)]'">
          <input type="radio" x-model="formData.plan" :value="plan" class="mr-2">
          <span x-text="plan.charAt(0).toUpperCase() + plan.slice(1)"></span>
        </label>
      </template>
    </div>

    <!-- Step 3: Confirm -->
    <div x-show="step === 3" x-cloak>
      <h3 class="text-lg font-semibold mb-4">Confirm</h3>
      <p>Name: <span x-text="formData.name"></span></p>
      <p>Email: <span x-text="formData.email"></span></p>
      <p>Plan: <span x-text="formData.plan"></span></p>
    </div>

    <!-- Navigation -->
    <div class="flex justify-between mt-6">
      <button type="button" x-show="step > 1" @click="prevStep()"
              class="px-4 py-2 rounded border border-[var(--color-border)]">Back</button>
      <button type="button" x-show="step < totalSteps" @click="nextStep()"
              class="px-4 py-2 rounded bg-[var(--color-accent)] text-[var(--color-accent-text)]">Next</button>
      <button type="submit" x-show="step === totalSteps"
              class="px-4 py-2 rounded bg-green-600 text-white">Submit</button>
    </div>
  </form>
</div>
```

### Step Validation Before Advancing

```html
<div x-data="{
  step: 1,
  errors: {},
  formData: { name: '', email: '' },
  validateStep() {
    this.errors = {};
    if (this.step === 1) {
      if (!this.formData.name) this.errors.name = 'Name is required';
      if (!this.formData.email) this.errors.email = 'Email is required';
    }
    return Object.keys(this.errors).length === 0;
  },
  nextStep() { if (this.validateStep()) this.step++; }
}">
  <div x-show="step === 1">
    <input x-model="formData.name" :class="errors.name ? 'border-red-500' : 'border-[var(--color-border)]'"
           class="w-full px-3 py-2 rounded border">
    <p x-show="errors.name" x-cloak x-text="errors.name" class="text-red-400 text-sm mt-1"></p>
  </div>
  <button @click="nextStep()">Next</button>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| No step validation | User can skip required fields | Validate each step before `nextStep()` |
| `x-if` for steps | Destroys state on step change | Use `x-show` to preserve state |
| Submitting on every step | Multiple server calls | Collect all data, submit on final step |

## Red Flags

- Form wizard that loses data when going back a step
- No progress indicator (user disoriented)
- Missing `x-cloak` on step panels (all steps flash on load)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
