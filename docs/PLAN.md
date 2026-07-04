# RateBoard — Project Plan

A short planning doc written before the code — the way I'd start a real feature.

## 1. Problem & positioning

Companies in payments, travel, e-commerce, and banking all end up needing the same small app: *show our customers live exchange rates, in our brand, and don't break offline.* Building it from scratch every time is waste. RateBoard is that app as a **white-label template**: fork, edit one JSON file, ship.

It's also a deliberate engineering showcase: the patterns here (single normalize boundary, actor-based offline cache, config-over-code) are the ones I use on production apps at scale.

## 2. Users & scope

- **Direct user:** anyone who wants trustworthy exchange rates, including offline.
- **Real customer:** an engineering team that wants a branded rates feature without building the plumbing.
- **MVP:** latest rates for a base currency → offline cache with age → converter → brand config. 
- **Out of scope (v1):** accounts, alerts, push, widgets. (Roadmap, not MVP.)

## 3. Data source research

- **Frankfurter** — https://frankfurter.dev — free, **no API key**, no meaningful rate limits for an app of this size; data = European Central Bank reference rates, updated on ECB business days.
- Endpoint: `GET https://api.frankfurter.dev/v1/latest?base=USD`
- Shape: `{"amount":1.0,"base":"USD","date":"2026-07-03","rates":{"EUR":0.91,...}}`
- Realities to handle: plain `yyyy-MM-dd` dates (timezone-shift risk), a rates map that can be missing/empty, and values that should be validated before display. Exactly why the normalize boundary exists.
- Alternatives considered: exchangerate.host (key required now), openexchangerates (key + quota) — Frankfurter wins on zero-friction reproducibility for anyone cloning the repo.

## 4. Domain model

| Raw (`RawRatesResponse`, wire) | Clean (`RateBoard`, app) |
| --- | --- |
| `base: String?` | `base: String` (guaranteed, uppercased) |
| `date: String?` ("2026-07-03") | `date: Date` (parsed in UTC; falls back to now) |
| `rates: [String: Double]?` | `rates: [Rate]` (validated, sorted, non-empty) |

`RateBoard.init(from:)` returns `nil` when nothing is usable → the caller falls back to `BoardCache`.

## 5. Architecture decisions

- **`RateBoardKit` package** keeps models, boundary, client, cache, and config testable without a simulator.
- **`RatesProviding` protocol** so view models are tested against a mock — no network in tests.
- **`BoardCache` as an `actor`** — modern Swift concurrency instead of locks; corrupted file = cache miss, never a crash; staleness is a *product* decision, so the cache exposes `age` instead of hiding a TTL.
- **`BrandConfig` with per-field defaults** — a broken brand file can only ever downgrade the experience, not take it down.

## 6. Milestones (one small commit each)

1. **Core package + tests** ✅ *(this commit — 9 tests passing)*
2. SwiftUI rates screen (view model, loading / offline / error states)
3. Converter + pinned currencies
4. View-model tests (mocked provider)
5. Historical chart (time-series endpoint)
6. CI (GitHub Actions → `swift test`)
7. Screenshots + example brand configs

## 7. Tradeoffs

- **Config over code** for branding: less flexible than a full theme engine, but 10× easier for a fork-and-ship customer — the right MVP tradeoff.
- **File-backed JSON cache** over Core Data/SQLite: one board is tiny; the simplest durable store wins. The `actor` boundary means the storage engine can change later without touching callers.
- **No API key** keeps the project trivially runnable by any reviewer — reproducibility is a feature.
