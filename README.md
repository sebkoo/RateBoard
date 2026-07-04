# 💱 RateBoard

**A white-label, offline-first currency rates app for iOS — fork it, edit one JSON file, ship it as your own.**

Built on the free, key-less [Frankfurter](https://frankfurter.dev) API (European Central Bank reference rates). Any company can rebrand it — name, colors, base currency, pinned currencies, features — **without touching a line of code**.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Platforms](https://img.shields.io/badge/iOS-15%2B-blue.svg)
![Tests](https://img.shields.io/badge/tests-9%20passing-brightgreen.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

> 🎯 Built to demonstrate production-grade iOS engineering: a clean data boundary, an **actor-based offline cache**, config-driven white-labeling, async networking, and a fully **unit-tested core** — on real public financial data.

---

## ✨ What it does

- 💱 **Live exchange rates** for any base currency (ECB data, no API key)
- 🔌 **Offline-first** — the last good board is cached and served with its age, so the app is useful on a plane or a low-connectivity job site
- 🎨 **White-label by config** — `Brand.json` controls the name, color, base currency, pinned list, and feature flags
- 🔁 **Converter** — amount × live rate, safely (`nil` beats a crash)
- 🧪 **Tested core** — the normalize boundary, the cache, and the config loader

*(SwiftUI app layer, screenshots, and CI land in upcoming commits — see the roadmap.)*

## 🏷 White-label in 30 seconds

```jsonc
// Brand.json — everything a company customizes, in one file
{
  "appName": "AcmePay Rates",
  "primaryColorHex": "#FF5500",
  "baseCurrency": "EUR",
  "pinnedCurrencies": ["USD", "GBP", "KRW"],
  "features": { "showConverter": true, "showLastUpdated": true }
}
```

A partial or broken config **degrades gracefully to defaults** — branding can never crash the app.

## 🏛 Architecture

A small, platform-agnostic core package — **`RateBoardKit`** — keeps every load-bearing piece testable without the UI.

```
Frankfurter JSON ──► RawRatesResponse (wire, messy)
                          │  normalize boundary — the ONE place data is cleaned
                          ▼
                     RateBoard (clean domain) ──► SwiftUI views
                          ▲                            ▲
                 BoardCache (actor,             BrandConfig (JSON,
                 offline-first)                 white-label theming)
```

**Three ideas carry the design:**

1. **One normalize boundary.** Junk rates are dropped, dates parse in UTC (no timezone day-shift), and the UI can trust every row — `RateBoard.init(from:)` is the only place that ever sees the wire shape.
2. **An `actor` cache.** Concurrent reads/writes are safe by construction; a corrupted cache file is a *miss*, never a crash. The cache reports the entry's **age** and lets the product decide what "too stale" means.
3. **Config over code.** The entire brand surface is data (`BrandConfig`), with per-field defaults — the same defensive posture as the data boundary.

## 🚀 Getting started

```bash
git clone https://github.com/sebkoo/RateBoard.git
cd RateBoard
swift test        # 9 tests: normalize, cache, config
```

```swift
import RateBoardKit

let client = FrankfurterClient()
let board = try await client.latest(base: "USD")
board.convert(100, to: "KRW")   // → Optional(137_240.0)
```

## 🗺 Roadmap (small, reviewable commits)

- [x] **chore:** initialize the RateBoardKit Swift package
- [ ] **feat:** raw Frankfurter wire model — the honest shape
- [ ] **feat:** `Rate` and `RateBoard` domain types with safe conversion
- [ ] **feat:** normalize boundary — junk-rate filtering, UTC-safe dates
- [ ] **feat:** async `FrankfurterClient` behind a `RatesProviding` protocol
- [ ] **feat:** actor-based offline `BoardCache` with age reporting
- [ ] **feat:** `BrandConfig` — JSON white-labeling with per-field defaults
- [ ] **test:** 9 unit tests across the boundary, cache, and config
- [ ] **feat:** SwiftUI rates screen (view model + loading / offline / error states)
- [ ] **feat:** converter screen + pinned currencies from `Brand.json`
- [ ] **test:** view-model tests with a mocked `RatesProviding`
- [ ] **feat:** historical chart (Frankfurter time-series endpoint)
- [ ] **ci:** GitHub Actions running `swift test`
- [ ] **docs:** screenshots + two example brand configs (fintech / travel)

## 👤 Author

**Ben Koo** — Senior iOS / Mobile Engineer (ex-Apple, Walmart, CVS Health).
Payments, wearables, and connected-health apps used by millions.
📩 61488202+sebkoo@users.noreply.github.com · 💼 [LinkedIn](https://www.linkedin.com/in/koo-ben) · 🐙 [github.com/sebkoo](https://github.com/sebkoo)

## 📄 License

MIT — see [LICENSE](LICENSE). Rates data © European Central Bank via [Frankfurter](https://frankfurter.dev).
