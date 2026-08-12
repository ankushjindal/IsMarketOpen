# Is Market Open?

A fast, native, telemetry-free macOS menu-bar clock for global market sessions.

Is Market Open? answers one question at a glance: is a market trading now, and
when is its next open or close? It handles exchange-local time zones,
daylight saving changes, holidays, early closes, partial sessions, and special
sessions without showing prices, news, charts, or portfolio data.

## Markets

- US stocks: NYSE and Nasdaq
- US futures: equity indexes, CBOT rates/agriculture, NYMEX energy, COMEX metals
- India: NSE/BSE stocks, NSE F&O, and MCX
- Crypto: continuous 24/7 schedule
- Reorderable city clocks

Equities use their regular cash session for the headline. Futures use the full
published electronic session; expanded details separately identify Globex,
regular-session activity, and daily maintenance breaks.

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

The build script produces an ad-hoc-signed local app bundle.

## Releases

[Tagged releases](https://github.com/ankushjindal/IsMarketOpen/releases) attach
that same ad-hoc-signed bundle. It is **not** signed with a Developer ID
certificate and **not** notarized, so macOS blocks it on first launch —
right-click the app and choose **Open** once to get past Gatekeeper, or build
from source using the steps above.

Signing with a Developer ID and notarizing is the remaining work before the app
is fit for wider distribution.

## Calendar data

[`Calendars/markets.json`](Calendars/markets.json) contains normalized session
overrides and official source links. It is bundled with the app and designed to
be updated independently from application releases.

Maintainers should verify each market against its official exchange source.
CME Group schedules require rolling updates because product-specific holiday
hours may be finalized only shortly before a holiday.

### Publishing a calendar update

`BundledCalendar.swift` is the editable source and `Calendars/markets.json` is
the generated public feed. To publish corrected holidays or extend verified
coverage without releasing a new app:

```sh
# Edit Sources/IsMarketOpen/Calendar/BundledCalendar.swift first.
./scripts/export-calendar.sh
./scripts/run-tests.sh
git add Sources/IsMarketOpen/Calendar/BundledCalendar.swift Calendars/markets.json
git commit -m "Update market calendars"
git push
```

Apps check the feed on launch at most once every 24 hours. Users can fetch it
immediately with **Settings → Calendars → Refresh calendars**. CI rejects feed
drift, duplicate or unknown markets, invalid sessions and sources, and coverage
shorter than 21 days from the manifest generation date.

## Status semantics

`OPEN` means the configured headline trading session is active. Futures label
that session as `OPEN · GLOBEX` or `OPEN · REGULAR`. It does not guarantee that
an exchange or broker is operational. Crypto's `OPEN 24/7`
describes its normal schedule, not live venue health.

> **Disclaimer:** Is Market Open? is informational only. Calendars can be
> delayed, incomplete, or changed by an exchange. Verify official exchange
> hours before making a trading decision.

## License

[MIT](LICENSE)
