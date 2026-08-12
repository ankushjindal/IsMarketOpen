# Product specification

## Promise

Is Market Open? provides an immediate, holiday-correct, local-time answer for
global market sessions from the macOS menu bar. It serves trading/research,
market-data operations, and release-window coordination.

## Principles

1. Cash equities use regular-session status as the headline.
2. Futures use the complete electronic session as the headline, with regular
   session and maintenance-break context shown separately.
3. All calculations happen locally and opening the popover never waits on I/O.
4. Calendar exceptions override weekly schedules.
5. Unknown or expired calendar data fails honestly.
6. No prices, charts, news, accounts, notifications, or telemetry.

## Calendar precedence

For a local exchange date:

1. A dated exception replaces the normal schedule completely.
2. An exception with zero sessions is a full closure.
3. Exception sessions may represent early closes, evening-only sessions, or
   explicitly announced special sessions.
4. Without an exception, the weekly session rules apply.
5. Time-zone conversion uses IANA identifiers and Foundation's current tzdata.

## Operational limitation

The application reports scheduled market state. It does not monitor outages,
halts, broker availability, data-feed health, or whether it is safe to deploy.
