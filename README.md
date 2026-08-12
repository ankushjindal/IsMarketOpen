# Is Market Open?

A fast, native, telemetry-free macOS menu-bar clock for global market sessions.

Is Market Open? answers one question at a glance: is a market's regular session
open, and when is its next open or close? It handles exchange-local time zones,
daylight saving changes, holidays, early closes, partial sessions, and special
sessions without showing prices, news, charts, or portfolio data.

## Markets

- US stocks: NYSE and Nasdaq
- US futures: equity indexes, CBOT rates/agriculture, NYMEX energy, COMEX metals
- India: NSE/BSE stocks, NSE F&O, and MCX
- Crypto: continuous 24/7 schedule
- Reorderable city clocks

The headline for equities and futures uses the product's regular or primary
session. Expanded details separately show extended-hours or Globex activity.

## Privacy and performance

- Native SwiftUI; no Electron or embedded web view
- No account, analytics, telemetry, or advertising
- Market state and countdowns are calculated locally
- Network access is used only to refresh the versioned calendar manifest
- Bundled/cached calendars continue working offline
- Expired calendar coverage is labelled `CALENDAR OUTDATED` instead of guessed

## Build

Requirements: Xcode 16 or later and macOS 14 or later.

```sh
./scripts/run-tests.sh
./scripts/build-app.sh
open build/IsMarketOpen.app
```

The build script produces an ad-hoc-signed local app bundle. Public releases
must be signed with a Developer ID certificate and notarized.

## Calendar data

[`Calendars/markets.json`](Calendars/markets.json) contains normalized session
overrides and official source links. It is bundled with the app and designed to
be updated independently from application releases.

Maintainers should verify each market against its official exchange source.
CME Group schedules require rolling updates because product-specific holiday
hours may be finalized only shortly before a holiday.

## Status semantics

`OPEN` means the configured regular/primary trading session is active. It does
not guarantee that an exchange or broker is operational. Crypto's `OPEN 24/7`
describes its normal schedule, not live venue health.

## License

[MIT](LICENSE)
