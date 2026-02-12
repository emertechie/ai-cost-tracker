# Phase 0: API and Model Mapping Verification

This repo includes a small Phase 0 toolkit to verify:

- GitHub API access for Copilot premium usage
- JSON parsing for `usageItems`
- Aggregation mapping:
  - `includedConsumed = sum(discountQuantity)`
  - `billedAmount = sum(netAmount)`
  - `billedQuantity = sum(netQuantity)`

## Files

- `scripts/fetch_github_usage.sh`: Fetches monthly usage JSON from GitHub API
- `scripts/phase0_verify.swift`: Parses JSON and prints aggregated values
- `scripts/run_phase0.sh`: Runs verifier over fixture files
- `Tests/Fixtures/github-usage-empty.json`: Empty fixture
- `Tests/Fixtures/github-usage-sample.json`: Sample fixture with included + billed usage

## 1) Verify mapping with fixtures

```bash
scripts/run_phase0.sh
```

Expected sample fixture output:

- Included consumed: `300 / 300 (100.00%)`
- Billed amount: `$6.1000`
- Billed premium requests: `110`

## 2) Verify real API access (your account)

Set environment variables:

```bash
export GITHUB_USERNAME="your-github-username"
export GITHUB_TOKEN="your-fine-grained-pat-with-plan-read"
```

Optional period override (defaults to current UTC month):

```bash
export YEAR=2026
export MONTH=2
```

Fetch data:

```bash
scripts/fetch_github_usage.sh
```

Run mapping verifier on fetched file:

```bash
scripts/phase0_verify.swift "Tests/Fixtures/github-usage-live-${YEAR:-$(date -u +%Y)}-${MONTH:-$(date -u +%-m)}.json" 300
```

## 3) Quick validation checklist

- `includedConsumed` increases as you use included premium requests
- `billedAmount` remains `0` before overage and becomes `> 0` after overage
- `billedQuantity` becomes `> 0` after overage
