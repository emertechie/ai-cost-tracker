# Plan: macOS menu bar app for GitHub Copilot premium usage (extensible to other providers)

## 1) Scope and UX

### MVP (GitHub Copilot, personal billing)

Menu bar item (right side, near clock) shows:

* A **mini linear progress bar** representing `% of included premium requests consumed`
* When overage begins, also show **billed amount** (e.g. `$4.07`) next to the bar

Clicking the item opens a popover with:

* Included consumed: `X / allowance` + percent
* Billed amount (month-to-date)
* Optional: billed premium requests count (if useful)
* “Resets in …” (monthly reset at **00:00 UTC on the 1st**) ([GitHub Docs][1])
* Last updated timestamp + “Refresh” button

Constraints:

* macOS **13+** only (you’re on 15.x)
* Single account
* “Other providers” = your own API keys (OpenAI/Anthropic/etc.)

---

## 2) Feasibility and data sources

### GitHub Copilot premium request usage (personal)

Use GitHub’s billing usage REST endpoint (works when Copilot is billed directly to your personal account). ([GitHub Docs][2])

Endpoint:

* `GET https://api.github.com/users/{username}/settings/billing/premium_request/usage` ([GitHub Docs][2])

Auth:

* Fine-grained PAT with **User permissions: “Plan” (read)** ([GitHub Docs][2])
* Include headers:

    * `Accept: application/vnd.github+json`
    * `X-GitHub-Api-Version: 2022-11-28`
    * `Authorization: Bearer <token>` ([GitHub Docs][2])

Response model highlights:

* `usageItems[]` contains `grossQuantity`, `discountQuantity`, `netQuantity` and `grossAmount`, `discountAmount`, `netAmount` plus `model`, `product`, `pricePerUnit` etc. ([GitHub Docs][2])

Mapping to UI:

* **Included premium requests consumed** = `Σ discountQuantity`
* **Billed premium requests (money)** = `Σ netAmount`
* (Optional) billed count = `Σ netQuantity`
* Reset timing: premium request counters reset monthly at **00:00 UTC on the 1st** ([GitHub Docs][1])

Allowance (“of 300 included”):

* The GitHub endpoint provides usage but not necessarily the allowance number; make allowance user-configurable (default 300) and optionally provide a plan preset. (GitHub documents plan allowances separately.) ([GitHub Docs][1])

### “Any provider” abstraction reality check

There is **no universal cross-provider usage API**. Build a provider/plugin interface and implement per-vendor backends.

For future providers you named:

* **OpenAI**: usage and cost endpoints exist but are shown with **Admin API key** in docs (org-level). ([OpenAI Developers][3])
* **Anthropic**: Usage & Cost API is part of their **Admin API** and requires an Admin API key; docs also note Admin API constraints (org setup/admin role). ([Claude Developer Platform][4])

Implication:

* Your app should support two modes per provider:

    1. **Native reporting API** (best; requires whatever “admin/billing” credentials the provider mandates)
    2. **Local estimation** based on tokens returned in responses + pricing tables (only works if you route all your calls through something you control; doesn’t help for Copilot IDE usage)

---

## 3) Architecture

### Core domain types

`UsageSnapshot`

* `providerId`
* `period` (year, month; with UTC boundaries)
* `includedConsumed` (Int)
* `includedAllowance` (Int? / user-configured)
* `includedPercent` (Double? computed)
* `billedAmount` (Decimal + currency)
* `billedQuantity` (Int? optional)
* `breakdowns` (optional: by model/product)
* `fetchedAt` (Date)
* `sourcePeriod` (echo of API period if needed)

### Provider interface (extensible)

`UsageProvider`

* `id`, `displayName`
* `capabilities` (supportsIncluded, supportsBilledMoney, supportsBreakdowns, supportsNativeCosts, supportsLocalEstimation)
* `fetchUsage(period) async throws -> UsageSnapshot`
* `validateAuth() async -> Result<Void, Error>`

### Provider implementations

1. `GitHubCopilotProvider` (native reporting API)

* Inputs: `username`, PAT, `includedAllowance` (default 300; editable)
* Calls: GitHub endpoint above with `year`, `month` params
* Aggregation:

    * `includedConsumed = Σ usageItems.discountQuantity`
    * `billedAmount = Σ usageItems.netAmount` (currency assumed USD unless response includes currency elsewhere; treat as USD if absent)
    * `billedQuantity = Σ usageItems.netQuantity` (optional)
    * `breakdowns`: group by `model` (and/or `product`) for popover detail

2. Future: `OpenAIUsageProvider` (native if admin key provided)

* Costs: `GET /v1/organization/costs?start_time=...` ([OpenAI Developers][5])
* Usage: `GET /v1/organization/usage/completions?start_time=...` etc. ([OpenAI Developers][3])
* Auth: admin key per docs
* If admin key not provided: fall back to “local estimation” (only if user chooses and you implement pricing + usage capture)

3. Future: `AnthropicUsageProvider` (native if admin key/org)

* Implement if user has Anthropic org + admin key; otherwise not possible via their Admin API. ([Claude Developer Platform][4])

### Storage & secrets

* **Keychain**: PAT / API keys
* App Support JSON (non-secret):

    * username
    * allowance override
    * refresh interval
    * show/hide billed amount when zero
    * selected provider (for future)

### Refreshing

* Polling timer (e.g. every 15 minutes)
* Manual refresh action
* Persist last snapshot to disk; show stale data if offline

---

## 4) macOS UI plan (SwiftUI, macOS 13+)

### App shell

* SwiftUI app using `MenuBarExtra` (macOS 13+)
* A popover view as the primary UI (no dock icon, optional)

### Menu bar “true mini progress bar”

Use a custom SwiftUI view as the `MenuBarExtra` label:

`MenuBarLabelView`

* fixed width mini bar (e.g. 60–90 px), height ~6 px
* fill = includedPercent (clamped 0–1)
* if `billedAmount > 0`: show `Text("$4.07")` to the right

Implementation approach:

* Pure SwiftUI drawing:

    * background capsule + foreground capsule with `GeometryReader`
* (If you want more native look): `NSViewRepresentable` wrapping `NSProgressIndicator` (bar style), but SwiftUI capsule is usually sufficient and simpler.

### Popover

`UsagePopoverView`

* Top: provider + period (e.g. “Copilot · Feb 2026”)
* Included: numeric + progress
* Billed: amount + optional billedQuantity
* Reset countdown: compute next month boundary at 00:00 UTC ([GitHub Docs][1])
* “Refresh” button + last updated time
* “Settings…” link/button

### Settings window

* Username
* PAT entry (store in Keychain)
* Included allowance (default 300)
* Refresh interval
* Optional: enable notifications at 80/90/100% and on first billed > 0

---

## 5) Implementation phases (deliverable-driven)

### Phase 0 — Verify API + model mapping (spike)

* Implement a small CLI test (or Postman/curl) with fine-grained PAT:

    * call the GitHub endpoint for current month
    * confirm `discountQuantity` increments and `netAmount` appears after allowance
* Capture a couple of real JSON samples to use as fixtures in unit tests. ([GitHub Docs][2])

### Phase 1 — macOS skeleton + UI

* Create SwiftUI macOS app
* Add `MenuBarExtra` with placeholder label and popover
* Implement the mini progress bar view component
* Implement Settings window + Keychain helper (read/write token)

### Phase 2 — GitHub Copilot provider

* Implement `GitHubCopilotProvider`:

    * URLSession request with headers and query params `year`, `month` ([GitHub Docs][2])
    * Codable models for response and `usageItems`
    * Aggregation logic → `UsageSnapshot`
* Add polling + caching:

    * store last snapshot to disk
    * show “stale” indicator when older than X minutes
* Hook provider output into menu label + popover

### Phase 3 — Robustness + polish

* Error handling:

    * invalid token (403)
    * missing data / empty month
* UX:

    * show billed amount only when `> 0` (default)
    * optional notifications:

        * threshold crossing (80/90/100)
        * billed amount becomes > 0
* Add unit tests:

    * parsing + aggregation from fixture JSON
    * month boundary/reset countdown logic

### Phase 4 — Multi-provider foundation (for your own API keys)

* Create provider registry + selection UI (still “single active provider”)
* Add scaffolding providers:

    * OpenAI “native costs/usage” mode requiring admin key per docs ([OpenAI Developers][5])
    * Anthropic “native usage/cost” mode requiring admin key/org per docs ([Claude Developer Platform][4])
* Add “local estimation” framework (optional):

    * define a `UsageEvent` model you can append whenever you make calls via your own code
    * store events locally and compute month-to-date spend using provider pricing tables
    * clearly separate from “native billing” mode

---

## 6) Suggested repo structure

```
/App
  CopilotMeterApp.swift
  MenuBar/MenuBarLabelView.swift
  Popover/UsagePopoverView.swift
  Settings/SettingsView.swift

/Core
  Models/UsageSnapshot.swift
  Providers/UsageProvider.swift
  Providers/ProviderRegistry.swift
  Storage/KeychainStore.swift
  Storage/AppConfigStore.swift
  Storage/SnapshotCache.swift
  Time/Period.swift (UTC month handling)

/Providers
  GitHubCopilot/GitHubCopilotProvider.swift
  GitHubCopilot/GitHubModels.swift
  (future) OpenAI/OpenAIUsageProvider.swift
  (future) Anthropic/AnthropicUsageProvider.swift

/Tests
  GitHubCopilotProviderTests.swift
  Fixtures/*.json
```

---

## 7) Decisions locked in (based on your answers)

* Billing entity: **personal** → use user-level GitHub endpoint ([GitHub Docs][2])
* macOS: **13+**
* Menu bar: **true mini progress bar** (not text-only)
* Single account
* Future providers: **your own API keys**, implemented via provider plugins (native reporting where possible; otherwise optional local estimation)

---

[1]: https://docs.github.com/copilot/how-tos/monitoring-your-copilot-usage-and-entitlements "Monitoring your GitHub Copilot usage and entitlements - GitHub Docs"
[2]: https://docs.github.com/en/rest/billing/usage "Billing usage - GitHub Docs"
[3]: https://developers.openai.com/api/reference/resources/organization/subresources/audit_logs/subresources/usage/methods/get_completions "Completions | OpenAI API Reference"
[4]: https://platform.claude.com/docs/en/build-with-claude/usage-cost-api "Usage and Cost API - Claude API Docs"
[5]: https://developers.openai.com/api/reference/resources/organization/subresources/audit_logs/methods/get_costs "Costs | OpenAI API Reference"
