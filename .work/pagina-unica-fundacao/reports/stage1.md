# Stage 1 — pagina-unica-fundacao

## AC-to-test map (ac-map.sh)

Every AC is covered: none uncovered, none unknown. Test files: test/app_test.dart, test/design_system_test.dart, test/quote_pdf_test.dart, test/quote_store_test.dart.

| AC | Test(s) |
|---|---|
| AC-1 | test/design_system_test.dart:25 |
| AC-2 | test/design_system_test.dart:53 |
| AC-3 | test/quote_store_test.dart:96 |
| AC-4 | test/quote_store_test.dart:115 |
| AC-101 | test/quote_store_test.dart:148 |
| AC-102 | test/quote_store_test.dart:176 |
| AC-9 | test/quote_store_test.dart:199 |
| AC-21 | test/quote_store_test.dart:248 |
| AC-10 | test/quote_store_test.dart:296 |
| AC-11, AC-12 | test/quote_store_test.dart:313 |
| AC-13, AC-14 | test/quote_store_test.dart:367 |
| AC-15, AC-16, AC-17 | test/quote_store_test.dart:414 |
| AC-18 | test/quote_store_test.dart:489 |
| AC-19 | test/quote_store_test.dart:489; test/quote_pdf_test.dart:234 |
| AC-20 | test/quote_store_test.dart:532; test/app_test.dart:60 |
| AC-23 | test/quote_pdf_test.dart:121 |
| AC-24 | test/quote_pdf_test.dart:194 |
| AC-25 | test/quote_pdf_test.dart:220 |
| AC-26 | test/quote_store_test.dart:546 |
| AC-28, AC-F6 | test/quote_pdf_test.dart:249 |
| AC-29 | test/quote_store_test.dart:586 |
| AC-31 | test/quote_store_test.dart:632 |
| AC-32 | test/quote_store_test.dart:705 |
| AC-103 | test/app_test.dart:92 |
| AC-F1 | test/quote_store_test.dart:911 |
| AC-F3 | test/quote_store_test.dart:881; test/app_test.dart:148 |
| AC-F4 | test/quote_store_test.dart:981; test/app_test.dart:198 |
| AC-F7 | test/quote_store_test.dart:949 |

## Candidate spread

Not run here: this stage resumed after apply, so the per-candidate numbers aren't available.

## Winner

No earlier stage-1 report existed. The checkpoint commit 36aff71 records that candidate 2 was adopted.

## Minimality review

I found no minimality violations, so I'm accepting the diff. budget.sh exited 0 and reported: 505 lines added (limit 950), 0 new files, 17 new public symbols (limit 24), nothing exceeded.

- **Out-of-manifest:** none. Every file and new public symbol in lib/ is approved in manifest.md: createDraft(), quoteClient, setDraftTexts, setDraftLineDescription, addNewCatalogLine, copyQuote, the changed addService/updateService, newestPdfRenderer, errBackupTooOld, buildQuotePdf(business, data), and the l10n keys. test/app_test.dart is new since the base, but the manifest lists it under files to touch.
- **Duplication:** none found. I searched lib/ for an existing accent-folding or normalising helper and found none, so _fold is not a reimplementation. The new code reuses the pieces code-map.md lists as reusable: _write/_fail, the ON CONFLICT and 9999 clamp, lastCatalogId, deleteQuote, the old PDF layout as _buildV1, and the documented errors.codeAt(count - 1) pattern in settings_page.
- **Over-abstraction:** none. quoteClient only forwards to quotePdfData(id).client, but the manifest names it and three wizard pages call it. _writeDraft is a real shared guard used by about 9 writes (it enforces AC-29). The diff also removes surface: the alsoNotify parameter of _write, the _Line class in the PDF, the two _clientNameById helpers, and draftClientId.
- **Unused surface:** none. Tests only ever call addNewCatalogLine with equipment and an empty description. The type and description parameters still stand, because the parent requirement says one sheet adds both services and equipment (S-18, S-20). The Preço dos equipamentos fields on QuotePdfData are required by AC-101 and AC-31, and tests read them.
- **Small things I chose not to flag:**
  - _addCatalog and _updateCatalog each gained a separate SQL branch for services (about 16 lines). It is forced by dropping services.unit_id, and a conditional column list would save only a few lines.
  - `return await` in the backup export is a one-line fix that lets the try/catch catch read errors.

A competent engineer who had read the ACs would not have written meaningfully less.

## Flagged but not fixed

Nothing. The reviewer flagged no violations.
