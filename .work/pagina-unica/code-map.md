# Code map — pagina-unica

## Store (`lib/store/`)

The `QuoteStore` (`quote_store.dart`, 1116 lines) is the only persistence layer. It runs SQLite directly through `sqlite3`.
- Each table has its own `StoreNotifier`.
- Writes go through `_write(notifier, action)`.
- On failure, writes go through `_fail(code, msg)`, which appends to the `ErrorLogBuffer` (`store_errors.dart`).
- Methods return `bool` or a value, and never throw. The UI reads `latestErrorMessage()`.

### Schema
- The schema is created in `_migrate` (:962-1049), as a single `user_version = 1` block.
- `quotes`:
  - `client_id` is `NOT NULL`.
  - `status` is `'draft'` or `'saved'`.
  - There are no columns for conditions or notes.
- `quote_lines`:
  - Columns are `quote_id, line_type, ref_id, quantity, unit_price_cents, subtotal_cents`.
  - It has a UNIQUE index on `(quote_id, line_type, ref_id)`.
  - It does **not** copy name, description or unit. These are resolved by JOIN in `listQuoteLines` (:416) and `quotePdfData` (:444).
- `services` has a `unit_id` column (to be removed). `equipments` also has `unit_id`.
- `quote_defaults` is a single row (`payment_method, validity, warranty, terms`), mirrored in `QuoteDefaultsData`.
- The `payment_methods` table already has CRUD (:633-659) and tests, but **no UI**.

### Behaviour that conflicts with the requirement
- `_updateCatalog` (:889) propagates the new catalog price to the lines of open drafts. This contradicts ADR 0001 and the glossary ("mudanças no catálogo não alteram"). **It goes.**
- `_deleteCatalog` (:913) deletes the matching lines from open drafts.
- `addDraftLine` (:349) always takes the catalog price, and on conflict it adds the quantity and **resets** `unit_price_cents` to the catalog price.
- `finalizeDraft` (:512) refuses to save a quote with no client or with `total <= 0` (`errQuoteEmpty`).
- `deleteDraftIfEmpty` (:536) only counts lines. The new rule is "sem cliente e sem linha".
- `searchCatalog` and `searchClients` use `lower() LIKE`. That handles ASCII only, so they are **not** accent-insensitive.
- `_validateBackup` (:925) accepts `user_version >= 1`. Version 2 has to raise that minimum.

### Models and settings
- `models.dart`:
  - `QuoteSummary.clientId` is a non-null `int`.
  - `QuoteLine` and `QuotePdfLine` are flat value classes.
  - `CatalogItemType {equipment, service}`; its index is persisted.
- Units are seeded **only in debug** (`main.dart:_seedEmptyStore`, which adds h, un, m). In release the `units` table starts empty and `UnitDropdownWidget` shows "noUnits" disabled.

## Routing (`lib/router/`)
- `AppRouterDelegate` is a `switch` over the sealed `AppRoute`, with no navigation stack.
- `popRoute` decides where the back gesture goes. Today `QuoteFlowRoute` → client step → home calls `deleteDraftIfEmpty`.
- Wizard-only pieces to delete:
  - `QuoteFlowRoute`, `QuoteStep` and its extension, `_buildQuoteFlow`;
  - the `draftId` parameters of `ClientCreateRoute`, `ServiceCreateRoute` and `EquipmentCreateRoute`, which then only serve the catalog and the clients manager.
- `PdfPreviewRoute(quoteId, back:)` stays.

## Pages (`lib/pages/`)

### Wizard only (to delete)
`client_select_page`, `services_page`, `equipment_page`, `review_page` (holds the only call to `finalizeDraft`, :117), and `send_page` (WhatsApp and copy link are not wired).

### Shared pages that stay
- **`client_create_page`**: the `back:` parameter. Without `back` it attaches the client to a draft. That part goes, because the client is now chosen in a bottom sheet.
- **`service_create_page` / `equipment_create_page`**: used by the catalog. The service page drops its Unit field. The `draftId` path goes.
- **`catalog_page`**: tabs, search, inline `_CatalogEditCard` with a unit dropdown for both types (the service one goes), delete via `showDialog`.
- **`clients_page`**: unchanged.
- **`home_page`**:
  - `_NewQuoteCard` (:35) currently goes to the client step and will create the draft and open the page.
  - Recent quotes: a draft opens the services step, a saved quote opens the PDF.
- **`quotes_list_page`**: saved quotes have `onTap: null` (:70-74); drafts open the services step. The name filter runs in Dart.
- **`pdf_preview_page`**:
  - Builds the PDF from `store.businessInfo`, `store.quoteDefaults` (global) and `quotePdfData`.
  - The "Compartilhar" button calls `Printing.sharePdf` (:27-30).
  - There is no "Salvar" button and no ⋮ menu.
- **`settings_page`** (859 lines):
  - Padrões are 4 free-text fields (`_FieldRow`). Payment is free text, with no list.
  - `_FooterPreview` mirrors the Padrões.
  - Backup export and import go through `FilePicker`. Any failure shows only a generic SnackBar (`backupImportFailed` / `backupExportFailed`).

## PDF (`lib/pdf/quote_pdf.dart`, 500 lines)
- `buildQuotePdf(BusinessInfoData, QuoteDefaultsData, QuotePdfData, quoteId)` (:46).
- **Tables:**
  - `_linesSection` (:288) renders services **and** equipment the same way: Descrição/Qtd/Un/Preço/Total, then a subtotal.
  - Services must become "Serviço · Valor", with the description under the name. `QuotePdfLine` has no description today.
- **Conditions:** all come from the global `QuoteDefaultsData`, each with a fallback:
  - validity falls back to `pdfDefaultValidity` (:70) and warranty to `pdfDefaultWarranty` (:73);
  - payment falls back to "—" (:245);
  - terms fall back to `pdfDefaultTerms` (:410), under the label `termsConditions` = "Termos e Condições";
  - the footer repeats payment and warranty (:439-440).
- There are no Observações.
- The palette is hard-coded in the file (:20-28) and does not use `VigilColors`.

## Design system (`lib/design_system/`)
- **Tokens:**
  - `VigilColors` (colors.dart);
  - radius (chip 6, input 14, card 16, feature 20, appFrame 28);
  - space (4–24) and `shadow.primaryLift`;
  - stroke 1.5;
  - gradients;
  - `VigilType` (DM Sans and DM Mono only);
  - `VigilTheme.light()`.
- **Primitives:** VigilSurface, VigilPill, VigilIconBox. Barrel file: `lib/design_system.dart`.
- **Widgets that can be reused:** FlowHeader/HeaderIconButton/HeaderActionButton (generic header, minus the step bar), SearchField (debounced), FormFieldWidget, FormSectionDivider, PrimaryButton, SecondaryButton, AddCard, InitialsAvatar, QuoteCard (gains the ⋮), UnitDropdownWidget, DestructiveIconButton, EmptyPanel, ManagerHeader, CatalogItemForm.
- **Wizard only:** QuoteCatalogStep, CatalogCard (its only user is QuoteCatalogStep), ReadyCard, TotalBanner, Panel, LineGroup/LineRow/DraftLineView. The step bar inside FlowHeader is wizard only too.
- **Not used anywhere in `lib/`:** `showModalBottomSheet` and `PopupMenu`. Only `showDialog` is used.
- **`DelforteApp.jsx` (source for the DS):**
  - Its colors match `VigilColors`.
  - Differences from Flutter:
    - The JSX uses **Syne** for display text. `Syne-ExtraBold.ttf` is in `assets/fonts` but not declared in `pubspec.yaml`, and `VigilType.title` uses DM Sans.
    - Radii 10, 11, 12 and 13 have no Flutter token.
    - The JSX phone frame radius is 46.
    - The PDF palette (#0A0F2C, #2A3050, #5499EE, #E8EBF2) exists only in quote_pdf.
  - The three new colours in the requirement (paper #E8EBF2, blueM #5499EE, pin #F2542D) come partly from that PDF palette.

## Localization (`lib/l10n/`)
- `abstract class Localization` holds about 161 `late final String` fields grouped by `// Section` comments, plus composed methods.
- `English` and `Portuguese` implement it with `@override String x = "…"`.
- There is a global `strings = Portuguese()`.
- The wizard sections (Client select, Services, Equipment, Review, Send) lose their keys. New keys are needed for the page, the bottom sheets, the ⋮ menu, Observações and Termos.

## Tests (`test/`)
- There is a single file, `quote_store_test.dart` (405 lines). It runs at store level against a real SQLite file in a temp directory: `openStore()` builds `QuoteStore(databasePath:)` with `addTearDown(dispose)`.
- No widget tests exist.
- These tests encode behaviour that changes:
  - catalog edits propagating to drafts;
  - `finalizeDraft` refusing an empty quote;
  - `deleteDraftIfEmpty`;
  - restoring a backup at version 1.
- The 15 tests pass today.

## I/O boundaries touched
1. **sqlite3:**
   - open plus the wipe-and-recreate when `user_version < 2`;
   - every write on the page (lines, client, conditions, notes, save, copy, delete);
   - creating an Item novo in the catalog.
2. **Backup import** (`file_picker` + sqlite): rejects files with version < 2.
3. **printing:** PDF preview and `Printing.sharePdf` (the system share sheet).
4. **dart:io / path_provider:** opening the database file (unchanged).

## Reuse, don't rebuild
- `_write`/`_fail`/`ErrorLogBuffer` and `latestErrorMessage()` for every new write.
- The structure of `addDraftLine` (ON CONFLICT plus the 9999 clamp) for adding equipment.
- `quotePdfData`, a single query, extended with the copied columns.
- `searchClients` and the `client_create_page` form inside the client bottom sheet.
- `formatMoney`/`moneyStringToCents` (catalog_item_form) for prices.
- `UnitDropdownWidget` for the unit of an Item novo of type equipment.
- The `listPaymentMethods` CRUD already in the store.
- `deleteQuote` (:526), which exists without UI, for the Excluir action.
