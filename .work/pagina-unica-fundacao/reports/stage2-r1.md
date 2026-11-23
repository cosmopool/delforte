# Stage 2, round 1: pagina-unica-fundacao

Base ref: d3fed83bca0e11b6941cc10e7726676686b7e7dc. Five findings came out of the hunt. None was refuted, all five reproduced through the real app or the public store API, and every reproduction failed to compile on the base, so `base-check.sh` attributes all of them to this feature. Decisions follow `workflow.fix_matrix` (`small_fix_lines` = 5).

## Summary table

| # | Title | Lens | AC | Refuted | Chance | Criticality | Silent | Est. lines | Repro | Base check | Decision |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Orphaned draft line after catalog delete: counted in the total, but no card on the wizard step | correctness | AC-19 | no | rare | minor | no | 8 | reproduced (`repro_r1_1`) | feature (does not compile on base) | report |
| 2 | Enviar, then back, then "Looks good" again fails with "Quote is not a draft" | correctness | AC-103 / D-20 | no | occasional | major | no | 2 | reproduced (`repro_r1_2`) | feature (does not compile on base) | fix |
| 3 | Client step preselects a deleted client, then Continuar fails with a raw SQLite NOT NULL error | correctness | AC-9 | no | rare | major | no | 3 | reproduced (`repro_r1_3`) | feature (does not compile on base) | fix (fix-small) |
| 4 | Compound writes are not atomic (copyQuote, deleteQuote, finalizeDraft, addNewCatalogLine) | persistence | AC-F7 | no | rare | critical | no | 6 | reproduced for copy and delete (`repro_r1_4`) | feature (does not compile on base) | fix |
| 5 | Same as #3, raised by the state lens (also reachable through Revisar's edit-client button) | state | AC-9 | no | rare | major | no | 2 | reproduced (`repro_r1_5`) | feature (does not compile on base) | fix (fix-small), together with #3 |

## Findings

### 1. Orphaned draft line on the wizard catalog step (report)

`lib/design_system/widgets/quote_catalog_step_widget.dart:64-68` builds its cards from `catalogById(refId)` and drops nulls with `whereType<CatalogItem>`. This diff removed the draft-line cleanup from `_deleteCatalog` (quote_store.dart:1031). So after a catalog item is deleted, a draft line that uses it still counts in the header total, but it has no card and no -/+ control, and Revisar's edit button only leads back to that step.

**Refutation.** The finding survived, but only in part. AC-19 requires the line to stay in the saved quote and its PDF, so the claim that the R$ value is unwanted does not hold. What remains is a UI gap in the temporary wizard, which slice 1b deletes (D-20). Revisar still shows the line under its own name. The AC-18 rename point is cosmetic, because the price, Revisar and the PDF all use the line's own copy.

**Reproduction.** Reproduced through the real router and SQLite. The test used a service instead of equipment because the equipment card overflows under the test font. The header shows R$ 28,00, and the assertion for the line's card fails with "Found 0 widgets".

**Decision.** rare × minor gives **report**. No code change.

### 2. Back from Enviar, then "Looks good" again (fix)

`finalizeDraft` now writes through `_writeDraft`, which refuses non-draft quotes (quote_store.dart:962). The back button on Enviar (send_page.dart:39-40) returns to Revisar, which still enables "Looks good". Pressing it again shows the raw SnackBar "Quote is not a draft" and does not navigate. On the base, `finalizeDraft` used plain `_write` and this path worked. That breaks D-20, which says the old flow keeps working end to end.

**Refutation.** Not refuted. No router guard and no status check upstream prevents it. No data is lost.

**Reproduction.** Reproduced through the full wizard path. The test fails at line 71 because the SnackBar is on screen.

**Decision.** occasional × major gives **fix**. Suggested fix, about 2 lines in `ReviewPage._saveAndContinue`: skip `finalizeDraft` when the quote is no longer a draft, then navigate to Enviar.

### 3 and 5. Deleted client preselected on the client step (fix, one change)

These are two reports of the same defect, from the correctness and state lenses. The draft keeps its client copy (AC-9), and `quotes.client_id` has no foreign key. `ClientSelectPage.initState` (client_select_page.dart:34) preselects that id, which enables Continuar. `_continue` (line 93) always calls `setDraftClient`, whose row-value `UPDATE ... = (SELECT ... FROM clients WHERE id = ?)` writes NULLs when no client row matches. The user then sees `SqliteException(1299): NOT NULL constraint failed: quotes.client_name` and stays on the step. The step is reachable from the services back button and from Revisar's edit-client button. On the base, the client came from a LEFT JOIN, so nothing was preselected and Continue started disabled.

**Refutation.** Not refuted. The SQL behaviour was confirmed in sqlite3.

**Reproduction.** Both repros (`repro_r1_3`, `repro_r1_5`) drive the real UI and show the raw SnackBar.

**Decision.** rare × major gives **fix-small**: the estimate is 2-3 lines, within the 5-line limit. One change fixes both findings: in `_continue`, skip `setDraftClient` when `clientId` equals the draft's current `quoteClient(existing)?.id`.

### 4. Compound writes are not atomic (fix)

`_write` (quote_store.dart:944) runs its action without BEGIN/COMMIT. When the second statement fails (SQLITE_FULL or an I/O error), the result depends on the call:
- `copyQuote` leaves an orphan draft that has a client and no lines.
- `deleteQuote` leaves a saved quote with 0 lines.
- `finalizeDraft` leaves `is_new` cleared on a quote that is still a draft.
- `addNewCatalogLine` leaves a stray catalog item.

This breaks AC-F7, ADR 0002 and the compound-write rule in `rules.mr-review` (Agente 2).

**Refutation.** Not refuted. The only real trigger is a disk-full or I/O failure between two statements, so the chance is rare, but the outcome is data corruption. The existing AC-F7 test locks the database before the first statement, so it never exercises a failure partway through.

**Reproduction.** Reproduced for copy and delete with public store calls. The failure is injected at the SQLite boundary by a RAISE(ABORT) trigger added from a second connection. Results:
- copy: `copy=0`, and the list gains `2:draft:Residencial Oliveira:0`.
- delete: `deleted=false`, and the quote becomes `1:saved:...:0`.

finalizeDraft and addNewCatalogLine were not reproduced.

**Base check.** The repro does not compile on the base, so the verdict is feature. The refuter noted that `deleteQuote` is byte-identical on the base, so that half is pre-existing in substance. It is still fixed here, because one transaction in `_write` closes both halves.

**Decision.** rare × critical gives **fix**. Suggested fix, about 6 lines: BEGIN/COMMIT around `action(db)` in `_write`, plus ROLLBACK in the catch. Move the steps of `addNewCatalogLine` into a single `_write`.

## Fix set for this round

Findings 2, 3+5 and 4 are marked for fixing. They touch three files: review_page.dart, client_select_page.dart and quote_store.dart. No file collects `cluster_size` or more of them, and together they add about 11 lines. Whether this crosses the budget is for `budget.sh` to decide in the design-check step. Finding 1 is reported only. No pre-existing follow-ups were found, because every base check returned feature.
