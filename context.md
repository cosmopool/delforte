# Delforte — Project Context

> Read this first. It exists so you don't have to re-explore the codebase every prompt.
> Keep it updated when architecture changes.

---

## 1. The app (abstract idea — UI/UX brief)

Delforte is a **mobile quote/estimate builder** for a small security-systems
business (CCTV, alarms, gates). A field professional uses it to assemble a
priced quote for a client and send it as a PDF.

**The vibe.** A polished, modern fintech-style mobile app. Dark navy headers,
a single confident blue accent, white rounded cards floating on a soft
off-white canvas. Generous spacing, large friendly tap targets, monospaced
numbers for money. It should feel calm, premium, and effortless — never
cluttered or "business software."

**Core flow.** Home → start a **New Quote** → a linear, step-by-step wizard:
pick **Client**, add **Services**, add **Equipment**, set **Payment** &
**Warranty**, **Review** the assembled quote, then **Send** (share / export
**PDF**). Each step has a progress bar; you can go back and edit anything.
Catalog data (clients, services, equipment) is reusable and searchable —
search surfaces *all* existing items, and you can create new ones inline.

**Other surfaces.** A Quotes list (drafts + saved), Templates (preset quote
starters), a Catalog manager, and Settings (business info, quote defaults,
PDF look). Recent quotes show on Home.

**Design source of truth:** `DelforteApp.jsx` at the repo root — a React
mockup of every screen. Flutter screens should match it 1:1 (layout, colors,
typography, spacing). **When asked to build/copy a screen, find the matching
component in that file and port it faithfully — do not invent UI.**

**Language:** all UI text goes through a `Localization` interface (see §4);
English is the only implementation so far, Portuguese (pt-BR) is planned.
Money is BRL (`R$ 1.234,56`).

---

## 2. Stack

- **Flutter** (Dart SDK 3.11.1), Material 3. Run via **fvm**:
  `.fvm/flutter_sdk/bin/flutter <cmd>` (plain `flutter`/`fvm` not on PATH).
- **State/data:** plain `QuoteStore` object over **direct SQLite**
  (`sqlite3` package). No Riverpod/Bloc/etc.
- **Navigation:** custom `Router`/`RouterDelegate` with a sealed `AppRoute`
  union (no go_router).
- **PDF:** `pdf` (build doc) + `printing` (on-screen preview + share).
- **Deps of note:** `path_provider`, `sqlite3_flutter_libs`, `characters`.

---

## 3. Layout map (where things live)

```
lib/
  main.dart                  App root: opens store, seeds debug data, hosts Router.
  router/
    app_route_state.dart     sealed AppRoute + QuoteStep enum (the route union).
    app_router.dart          AppRouterDelegate: route -> page (build) + popRoute (back).
  store/
    quote_store.dart         THE data layer. All reads/writes = SQLite queries.
    models.dart              Client, CatalogItem, Unit, QuoteSummary, QuoteLine, CatalogItemType.
    *_data.dart              Singleton settings buffers (business_info, quote_defaults, pdf_settings).
    store_errors.dart        Error codes + ErrorLogBuffer.
  pages/                     One file per screen (home, client_select, services, equipment,
                             review, send, pdf_preview, quotes_list, templates, settings, *_create).
  l10n/
    localization.dart        Abstract `Localization` (all UI strings) + global `strings`.
    english.dart             `English implements Localization` — the English strings.
  pdf/
    quote_pdf.dart           Builds the quote PDF document (matches PdfPreviewScreen in the mockup).
  design_system.dart         Barrel — re-exports all tokens. Import this.
  design_system/             Tokens (colors, type, radius, space, gradients, shadow, stroke) +
    widgets/                 reusable widgets (AppShell, FlowHeader, Panel, LineRow, QuoteCard,
                             PrimaryButton, SearchField, InitialsAvatar, TotalBanner, ...).
assets/fonts/                Bundled Syne / DM Sans / DM Mono TTFs (used by the PDF).
DelforteApp.jsx              The design mockup (source of truth for all UI).
ROADMAP.md                   Checklist of features (done = [x]).
```

---

## 4. Architecture & conventions

**Store is the single source of truth.** `QuoteStore` queries SQLite on every
read and writes straight through, then fires a `StoreNotifier` (e.g.
`quotesNotifier`, `clientsNotifier`) so listening widgets re-query. Pages
rebuild via `ListenableBuilder`/`AnimatedBuilder` on those notifiers. There is
no in-memory cache or ORM — embrace the direct-query simplicity.

- **Drafts are quotes** with `status='draft'`; finalizing flips to `'saved'`
  and stamps the total. Money is stored/handled in **integer cents**.
- A page receives `store` + `router` (and `draftId`/`quoteId`) by constructor.
  Pages never construct the store.

**Navigation.** Add a screen by: (1) add a class to the `AppRoute` union, (2)
add a `build` case + a `popRoute` (back) case in `AppRouterDelegate`, (3) make
some page call `router.goTo(MyRoute(...))`. Routes that can be reached from
multiple places carry where to return (see `PdfPreviewRoute.back`).

**Design system — always reuse, match the mockup.**
- Import `package:delforte/design_system.dart` for tokens.
- Colors: `VigilColors` (`ink` #080F26 navy, `primary` #1E66E1 blue,
  `canvas` #F3F5FB, `surface` white, `textSecondary`/`textMuted`,
  `success`, `border`). Type: `VigilType.title/body/small`.
- Wrap pages in `AppShell`; headers use `FlowHeader`; cards use `Panel`;
  line items use `LineRow`/`LineGroup`; totals use `TotalBanner`. Prefer an
  existing widget in `design_system/widgets/` before writing new layout.
- The mockup palette key (`C` map in `DelforteApp.jsx`) maps directly onto
  `VigilColors`.

**Localization — never hardcode UI text.** Every user-facing string lives on
the `Localization` interface in `lib/l10n/localization.dart` and is read through
the global `strings` (e.g. `strings.saveClient`). Plain strings are getters with
short camelCase keys; strings that interpolate runtime values are methods
(`strings.quoteMeta(s, e)`, `strings.validFor(v)`). To add a string: declare it
on `Localization`, implement it in `english.dart`, then use `strings.x` in the
UI. Swapping `strings` to another `Localization` impl translates the whole app.
Because `strings.x` isn't `const`, widgets holding UI text can't be `const`
(e.g. `FlowHeader.continueLabel` is nullable, resolved at build time). Scope so
far: pages + design-system widgets + `main.dart`; the **PDF** (`quote_pdf.dart`)
still has inline strings.

**Money formatting:** `formatMoney(cents)` / `moneyStringToCents` / `initials`
in `lib/utils.dart`.

**Style:** double-quoted imports, trailing commas, small focused widgets
(often private `_Foo` classes per file). User's stated value: **simplicity &
small code area** — prefer the smallest change that fits existing patterns;
don't add deps or abstractions speculatively.

---

## 5. Build / verify commands

```bash
.fvm/flutter_sdk/bin/flutter analyze lib/          # lint — keep clean
.fvm/flutter_sdk/bin/flutter test                  # unit tests
.fvm/flutter_sdk/bin/flutter pub get               # after pubspec changes
.fvm/flutter_sdk/bin/dart format                   # code style, after everything else working
```

Note: `test/quote_store_test.dart` currently has **2 pre-existing failing
tests** (draft line-count assertions) unrelated to recent work — don't be
alarmed by them.

---

## 6. Gotchas

- **fvm only** — never call bare `flutter`.
- **Debug seed:** `main.dart` seeds sample clients/catalog **only in debug**
  and only when the store is empty.
- **PDF fonts are bundled** (`assets/fonts/`), loaded via `rootBundle` — do
  **not** switch to `PdfGoogleFonts` (network fetch breaks offline).
- The `pdf` package alone cannot *display* a PDF; `printing` provides the
  preview widget and share action.
- Quote IDs are currently the raw SQLite int (`#<id>`); a human-friendly
  quote-number scheme is still on the roadmap.
- Ask before add new packages. Prefer in-house solutions.
