Set-Location D:\GSMFWs
$ErrorActionPreference = 'Stop'

$agentNames = @(
'n-plus-one-detector','migration-safety-checker','migration-reverse-tester','view-complexity-analyzer','view-god-file-splitter','form-validation-checker','form-csrf-enforcer','signal-safety-checker','signal-async-enforcer','cache-management-auditor','cache-invalidation-checker','transaction-safety-checker','atomic-scope-analyzer','soft-delete-auditor','soft-delete-filter-checker','url-namespace-checker','url-pattern-validator','template-context-auditor','template-variable-checker','management-command-analyzer','command-idempotency-checker','queryset-optimization-checker','select-related-enforcer','error-handling-checker','exception-suppression-detector','logging-auditor','logging-pii-detector','settings-auditor','settings-production-checker','fixture-generator','seed-data-creator','app-boundary-enforcer','cross-import-detector','model-completeness-checker','model-meta-enforcer','celery-task-safety-checker','celery-retry-analyzer','database-index-analyzer','database-query-profiler','middleware-order-checker','middleware-conflict-detector','context-processor-analyzer','templatetag-analyzer','admin-registration-checker','admin-permission-enforcer','serializer-validation-checker','viewset-permission-analyzer','pagination-analyzer','filtering-optimizer','search-indexer',
'htmx-correctness-checker','htmx-csrf-enforcer','htmx-fragment-validator','htmx-loading-indicator-checker','htmx-error-handler-checker','htmx-history-analyzer','htmx-oob-swap-checker','htmx-accessibility-checker','htmx-performance-analyzer','htmx-debounce-checker','alpine-correctness-checker','alpine-store-validator','alpine-cloak-enforcer','alpine-transition-checker','alpine-focus-trap-checker','alpine-keyboard-checker','alpine-error-boundary-checker','alpine-reactivity-checker','alpine-lifecycle-analyzer','alpine-performance-checker','tailwind-consistency-checker','tailwind-token-enforcer','tailwind-responsive-checker','tailwind-dark-mode-checker','tailwind-contrast-checker','tailwind-rtl-checker','tailwind-animation-checker','tailwind-z-index-checker','tailwind-typography-checker','tailwind-print-checker','css-architecture-checker','css-specificity-analyzer','css-unused-detector','css-critical-path-analyzer','css-custom-property-checker','js-safety-checker','js-csp-compliance-checker','js-error-boundary-checker','js-performance-analyzer','js-bundle-size-checker','component-library-enforcer','component-reuse-checker','icon-consistency-checker','font-optimization-checker','image-optimization-checker','image-alt-checker','accessibility-wcag-checker','accessibility-keyboard-checker','accessibility-screen-reader-checker','accessibility-color-contrast-checker',
'wallet-integrity-checker','wallet-balance-reconciler','subscription-enforcement-checker','subscription-tier-validator','affiliate-fraud-detector','affiliate-self-referral-checker','affiliate-commission-calculator','affiliate-payout-validator','escrow-dispute-resolver','gamification-abuse-detector','gamification-cap-enforcer','refund-processor-validator','refund-reversal-checker','download-quota-enforcer','download-token-validator','ad-gate-integrity-checker','ad-reward-validator','revenue-reporting-auditor','revenue-bot-filter','promo-code-auditor','promo-limit-enforcer','order-lifecycle-checker','order-fulfillment-validator','marketplace-fee-calculator','marketplace-seller-verifier','billing-compliance-checker','tax-calculation-validator','bounty-workflow-checker','bounty-approval-enforcer',
'ci-pipeline-optimizer','ci-job-analyzer','ci-cache-optimizer','cd-deployment-checker','cd-rollback-validator','docker-compose-checker','docker-image-optimizer','sentry-integration-checker','sentry-alert-configurator','backup-auditor','backup-restore-tester','performance-profiler','performance-query-counter','performance-response-time-checker','performance-memory-analyzer','dependency-manager-auditor','dependency-cve-scanner','pre-commit-auditor','pre-commit-hook-validator','pyright-config-checker','pyright-error-resolver','coverage-tracker','coverage-branch-analyzer','documentation-keeper','documentation-sync-checker','redis-health-checker','redis-memory-analyzer','postgresql-maintenance-checker','postgresql-index-advisor','celery-health-checker','celery-queue-analyzer',
'jsonld-generator','jsonld-validator','jsonld-blogposting-checker','jsonld-faqpage-generator','jsonld-howto-generator','jsonld-software-generator','jsonld-product-generator','sitemap-auditor','sitemap-completeness-checker','sitemap-xslt-validator','sitemap-index-checker','meta-tag-auditor','meta-tag-completeness-checker','og-image-generator','og-tag-validator','canonical-url-checker','canonical-conflict-resolver','internal-linking-scanner','internal-linking-tfidf-analyzer','internal-linking-anchor-diversifier','internal-linking-broken-repairer','redirect-manager','redirect-chain-detector','redirect-loop-checker','redirect-hitcount-analyzer','content-quality-checker','content-readability-scorer','content-word-count-analyzer','content-keyword-density-checker','blog-publisher','blog-workflow-checker','blog-seo-scorer','blog-meta-generator','forum-moderator','forum-spam-detector','forum-trust-level-evaluator','forum-reaction-analyzer','scraper-approval-checker','scraper-ingestion-validator','distribution-manager','distribution-connector-health-checker',
'full-audit-orchestrator','security-audit-orchestrator','frontend-audit-orchestrator','django-audit-orchestrator','commerce-audit-orchestrator','seo-audit-orchestrator','ads-audit-orchestrator','distribution-audit-orchestrator','performance-audit-orchestrator','accessibility-audit-orchestrator','regression-audit-orchestrator','deployment-orchestrator','release-orchestrator','hotfix-orchestrator','feature-orchestrator','refactor-orchestrator','migration-orchestrator','test-suite-orchestrator','documentation-orchestrator','governance-audit-orchestrator',
'post-impl-checklist-runner','pre-deploy-checklist-runner','pre-commit-gate-runner','ruff-compliance-checker','pyright-compliance-checker','django-check-runner','problems-tab-checker','zero-tolerance-enforcer','code-review-assistant','pr-review-assistant','merge-conflict-resolver','breaking-change-detector','api-compatibility-checker','schema-migration-reviewer','data-loss-preventer','governance-completeness-checker','skill-format-validator','agent-format-validator','rule-format-validator','hook-format-validator',
'firmware-catalog-manager','firmware-variant-analyzer','firmware-scraper-coordinator','firmware-approval-workflow','firmware-download-optimizer','firmware-hash-verifier','device-catalog-manager','device-fingerprint-analyzer','device-trust-scorer','device-behavior-analyzer','gsmarena-sync-coordinator','gsmarena-conflict-resolver','brand-model-validator','brand-logo-checker','storage-quota-manager','storage-gcs-optimizer','notification-dispatcher','notification-template-checker','email-deliverability-checker','email-bounce-handler','webhook-delivery-checker','webhook-retry-manager','i18n-completeness-checker','i18n-rtl-validator','changelog-generator','changelog-semantic-versioner','backup-scheduler','backup-integrity-checker','moderation-queue-manager','moderation-auto-classifier',
'band-aid-detector','band-aid-classifier','band-aid-reversal-coordinator','band-aid-candidate-ledger','fix-hypothesis-tracker','fix-impact-analyzer','root-cause-identifier','mitigation-classifier','guard-retention-checker','fix-closure-validator'
)

$agentDir = '.github/agents'
$created = 0
$skipped = 0

foreach ($name in $agentNames) {
    $path = Join-Path $agentDir "$name.agent.md"
    if (Test-Path $path) {
        $skipped++
        continue
    }

    $title = ($name -replace '-', ' ')
    $desc = "$title specialist. Use when: auditing, validating, and improving $title workflows and safeguards."

    $content = @"
---
name: $name
description: "$desc"
---

# $title

## Role
Focused specialist for $title tasks with read-only analysis by default and remediation guidance when changes are requested.

## Core Checks
- Validate implementation completeness for the target domain
- Detect regressions and anti-patterns
- Recommend concrete, minimal-risk fixes
- Confirm alignment with project governance rules

## Quality Gate
- & .\\.venv\\Scripts\\python.exe -m ruff check . --fix
- & .\\.venv\\Scripts\\python.exe -m ruff format .
- & .\\.venv\\Scripts\\python.exe manage.py check --settings=app.settings_dev
"@

    Set-Content -Path $path -Value $content -Encoding utf8
    $created++
}

Write-Output "created=$created"
Write-Output "skipped=$skipped"
Write-Output "requested=$($agentNames.Count)"
