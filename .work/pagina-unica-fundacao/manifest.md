# Manifest — pagina-unica-fundacao

## Files to touch
- `lib/store/quote_store.dart` — the crux of the slice. Everything stays in this one class, with one section per table.
  - `_migrate` becomes the v2 schema in a single block. Below v2 it drops every table and recreates them (S-6, A-5). It seeds the units `un`, `m`, `cx` and `kit` (D-4).
    - `quotes` gains:
      - `client_id` nullable, plus the copied client columns (D-1);
      - `payment`, `warranty`, `validity`, `terms`, `notes`;
      - `renderer_version`;
      - the Preço dos equipamentos columns (`show_unit_price`, `equipment_price_mode`, `closed_total_cents`, `markup_percent`), which part 2 will use (S-7).
    - `quote_lines` gains `name`, `description`, `unit`, `is_new` (S-8, D-14). The UNIQUE `(quote_id, line_type, ref_id)` stays, because a service never repeats and equipment sums.
    - `services` loses `unit_id` (S-27).
    - `quote_defaults` gains `show_unit_price`, default 1 (AC-4).
  - `createDraft()` takes no client and copies the Padrões into the quote.
  - `setDraftClient` copies the client.
  - `addDraftLine` copies name, description, unit and price.
    - For an equipment already on the quote, it sums the quantity up to 9999 and keeps the line's price (D-13).
    - For a service already on the quote, it inserts nothing and returns true (AC-13).
  - `finalizeDraft` requires a client and at least one line (D-8). It clears `is_new` and records the newest renderer version.
  - `deleteDraftIfEmpty` checks "no client and no line" (D-15).
  - Every quote write is refused on a saved quote (AC-29).
  - `_updateCatalog` and `_deleteCatalog` lose their draft side effects (D-2, D-3).
  - `searchCatalog` ignores accents and case (S-19, AC-10). `searchClients` stays as it is (A-7).
  - `_validateBackup` requires `user_version` 2 and logs a dedicated error code (D-11).
  - `addService` and `updateService` lose `unitId`.
- `lib/store/models.dart` — models change in place, with no parallel classes:
  - `QuoteSummary.clientId` becomes `clientName` (the copy; empty when there is no client).
  - `QuoteLine` gains `description`, `unit` and `isNew`.
  - `QuotePdfData` becomes the whole quote document: status, client copy, the four Condições, Observações, renderer version, the Preço dos equipamentos fields and the lines. `QuotePdfLine` gains `description`.
  - `CatalogItem.unitId` stays (0 for services).
  - It also gets the constant `newestPdfRenderer = 1`.
- `lib/store/quote_defaults_data.dart` — `showUnitPrice` field.
- `lib/store/store_errors.dart` — `errBackupTooOld`.
- `lib/pdf/quote_pdf.dart` — the single-page PDF as **renderer v1**:
  - `buildQuotePdf(business, data)` is the single entry point. It runs a `switch` on `data.rendererVersion`: `1` goes to `_buildV1`, and anything else returns `null` without throwing (AC-F6).
  - `_buildV1`:
    - prints Serviços as "Serviço · Valor" with the description under the name;
    - prints Equipamentos as Descrição/Qtd/Un/Preço/Total;
    - takes the Condições from the quote, leaves an empty one out and has no fallback texts (D-9);
    - labels the terms block "Termos";
    - prints Observações last.
- `lib/pages/pdf_preview_page.dart` — calls the new entry point, and shows an error text when it returns `null` (A-3).
- `lib/pages/settings_page.dart` — on import, `errBackupTooOld` shows its own SnackBar (D-11, D-21). The rest is unchanged.
- Wizard adapted to the new API, with the smallest change that compiles and keeps the flow working (D-20). The pages below move from `createDraft(clientId)` / `draftClientId` + `clientById` to `createDraft()` + `setDraftClient` / `quoteClient`, or read `clientName` from the summary:
  - `lib/pages/client_select_page.dart`
  - `lib/pages/client_create_page.dart`
  - `lib/pages/review_page.dart`
  - `lib/pages/send_page.dart`
  - `lib/router/app_router.dart`
  - `lib/pages/home_page.dart`
  - `lib/pages/quotes_list_page.dart`
- The service Unit field goes (S-27, AC-20):
  - `lib/pages/service_create_page.dart`
  - `lib/pages/catalog_page.dart`
  - `lib/design_system/widgets/catalog_item_form_widget.dart`
- `lib/main.dart` — `_seedEmptyStore` stops seeding units and stops passing a unit to services (D-4).
- `lib/design_system/colors.dart` — `paper` #E8EBF2, `blueM` #5499EE and `pin` #F2542D (S-1).
- Localization: add `backupTooOld`, `observations`, `pdfRendererUnknown` and the PDF header words `service` / `pdfValue` ("Serviço · Valor"); `termsConditions` becomes "Termos"; remove `pdfDefaultValidity`, `pdfDefaultWarranty` and `pdfDefaultTerms`. Files:
  - `lib/l10n/localization.dart`
  - `lib/l10n/english.dart`
  - `lib/l10n/portuguese.dart`
- `test/app_test.dart` — the two widget finders fixed after the race (the uppercase FormFieldWidget label, and `scrollUntilVisible` for the lazy settings list).
- `test/quote_store_test.dart` — rewritten for the new rules (D-18), plus the store ACs.

## New files
- `docs/design-system.html` — the Vigil gallery (S-2, AC-2). It contains no Dart and does not count toward the budget. **It is written once, before the candidate race,** and checkpointed, so all three candidates share it and only the Dart is raced.
- `test/design_system_test.dart` — token parity between the HTML `:root` and `VigilColors` (AC-1).
- `test/quote_pdf_test.dart` — the PDF ACs through `buildQuotePdf` (AC-23, 24, 28, F6).
  - Only v1 exists in this slice, so AC-28 is tested with what exists:
    - a saved quote keeps its stored version after `newestPdfRenderer` would change;
    - a draft reports `newestPdfRenderer`;
    - a version the switch does not know goes to the error path.
  - There is no test hook for registering a fake v2. The real two-version test comes with renderer v2 in part 2.
- No new production Dart files.

## Public symbols to add
These are counted as declaration lines added or changed in `lib/`.
- `QuoteStore`:
  - `createDraft()` (signature changed);
  - `quoteClient(quoteId)` → the copied `Client?`;
  - `setDraftLineDescription` (service, AC-14);
  - `addNewCatalogLine` (Item novo: creates the catalog item and the flagged line, AC-15);
  - `setDraftTexts(quoteId, {payment, warranty, validity, terms, notes})` for the Condições and Observações (AC-21);
  - `copyQuote(quoteId)` → the id of the new draft (Editar, AC-31);
  - `addService` and `updateService` (signatures changed);
  - `quotePdfData`, which stays and returns the whole document.
- `models.dart`: `newestPdfRenderer`.
- `store_errors.dart`: `errBackupTooOld`.
- `quote_pdf.dart`: `buildQuotePdf` (signature changed).
- Page and widget signatures changed by the adaptation (`build`, handlers): about 8.

## Reused, not rebuilt
- `_write` / `_fail` / `ErrorLogBuffer` / `latestErrorMessage()` — `lib/store/quote_store.dart:855`, `lib/store/store_errors.dart:34`, used for every new write.
- The `addDraftLine` structure (ON CONFLICT plus the 9999 clamp) — `quote_store.dart:349`.
- `quotePdfData` as a single query, extended with the copied columns — `quote_store.dart:444`.
- `deleteQuote` (Excluir) — `quote_store.dart:526`.
- The `listPaymentMethods` CRUD — `quote_store.dart:633-659` (unchanged in this slice).
- The current PDF layout and palette — `lib/pdf/quote_pdf.dart`, which becomes `_buildV1`. It is not rewritten from scratch.
- The real-temp-SQLite test pattern (`openStore()` + `addTearDown`) — `test/quote_store_test.dart`.

## Budget
added 950 · new files 0 · new public symbols 24

**Why it is above the defaults (300 / 3 / 8):**
- The slice replaces the whole schema and the shape of the quote store API, turns the PDF into v1 and adapts 9 wizard files.
- About 450 of the lines are the store and models, 200 are the PDF and 300 are the adaptations and l10n.
- The symbols count changed signatures, not only new names.
- There are no new production files.

## API
settled
