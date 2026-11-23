# Fundação da página única (pagina-unica-fundacao)

Slice 1a of `pagina-unica`. The full gathered requirement is `.work/pagina-unica/requirement.md`. Read it for the quoted source lines (S-*), the decisions (D-*) and the confirmed assumptions (A-*), which apply here unless this file says otherwise. Slice 1b is `pagina-unica-telas`. Both slices land on the branch `feat/pagina-unica` and reach `main` together.

## Summary
This slice builds everything below the screens:
- the Vigil design system as tokens plus the committed HTML gallery, with a token-parity test;
- the v2 database, which wipes v1 and seeds the units;
- the reshaped `QuoteStore` API: a draft with no client, client and line copies, per-quote Condições and Observações, the "novo no catálogo" flag, the save rule, Editar's copy and Excluir;
- the single-page PDF as renderer v1 behind a versioned dispatch;
- rejection of v1 backups.

The existing wizard is **adapted** to the new store API, so the app keeps creating, saving and showing quotes until slice 1b replaces it (D-20). Everything is verified through the store's public API and the PDF entry point, not through new screens.

## Specified
From the parent requirement (`.work/pagina-unica/requirement.md`):
- S-1 to S-8.
- S-9.
- S-11, store side only (a preview does not save; saving is explicit).
- S-14, the store operations for Editar's copy and Excluir.
- S-19, the catalog search in the store.
- S-20 to S-25, store side.
- S-26 (the PDF).
- S-27 (services lose Unit, in the store and in the Catálogo service form).

## Decided
From the parent requirement:
- D-1 to D-4.
- D-5, store side only. The CRUD already exists, and the list UI is in 1b.
- D-6.
- D-8, D-9.
- D-11, including its SnackBar in Configurações.
- D-12 to D-15.
- D-17.
- D-18, the test rewrites only. The route parameters go in 1b.
- D-19.
- **D-20 Adapt the wizard:** slice 1a adapts the wizard pages (client, services, equipment, review, send) and the Catálogo create pages to the new store API, so the old flow keeps working end to end. These adaptations are temporary, because 1b deletes the wizard. They should be the smallest change that compiles and keeps the flow usable.
  - *Rejected:* removing the wizard in 1a and leaving "Novo Orçamento" disabled between the slices.
  - *Source:* the user's choice.
- **D-21 Backup message lives in 1a:** the D-11 message for an old backup is shown here. It is one string and one branch in the existing settings import handler, and this slice owns the backup boundary.


## Assumed
From the parent requirement, all confirmed by the user: A-1, A-3, A-4, A-5, A-9, A-10.

## Non-goals
In addition to the parent's:
- **No new screens:** no page, bottom sheet, ⋮ menu, "Sem cliente" label, payment-method list UI, PDF "Salvar" button or draft-discard-on-leave wiring. All of these belong to 1b.
- **No new components** in the gallery beyond the existing widgets. New components are born in 1b.
- **No removal of the wizard,** its routes or their `draftId` parameters (1b).
- **No polish of the adapted wizard** beyond what the new API forces.

## Acceptance criteria
IDs match the parent's where the behaviour is the same, reworded to the store API. IDs starting with `AC-1a-` are new.

### Design system
- AC-1:
  - *Given* `docs/design-system.html` and `lib/design_system/`,
  - *when* the parity test runs,
  - *then* every colour token in the HTML `:root` has a Dart constant with the same value, including `paper` #E8EBF2, `blueM` #5499EE and `pin` #F2542D, and the test fails if either side changes alone.
- AC-2:
  - *Given* the gallery is opened offline,
  - *when* it loads,
  - *then* it shows the foundations (colours, type, spacing, radii, shadows), every existing component with its states and the current app screens, using fonts from `assets/fonts` only.
  - Titles use DM Sans and the radii are today's tokens (D-6).

### Database
- AC-3:
  - *Given* a database file at `user_version` 1 that holds clients and quotes,
  - *when* the store opens it,
  - *then* it is at `user_version` 2, every user table is empty, and the units `un`, `m`, `cx` and `kit` exist.
- AC-4:
  - *Given* a fresh database,
  - *when* the store opens it,
  - *then* the Configurações default for "Valor unitário no PDF" is on.

### Drafts and copies
- AC-101:
  - *Given* Padrões with payment "PIX", warranty "90 dias", validity "30 dias" and terms "T",
  - *when* a draft is created without a client and the Padrões are then changed,
  - *then* the draft has no client, its Condições read PIX, 90 dias, 30 dias and T, its Observações are empty, and its Preço dos equipamentos fields hold their defaults (mode Soma dos itens, unit price shown as set in Configurações). (AC-8)
- AC-102:
  - *Given* a draft with no client and no lines but with Observações typed,
  - *when* the empty-draft discard runs,
  - *then* the draft no longer exists.
  - *Given* a draft with a client and no lines, the discard keeps it. (D-15, AC-6, AC-7)
- AC-9:
  - *Given* a draft,
  - *when* client "Residencial Oliveira" is set on it and that client's address is later edited (or the client is deleted),
  - *then* the draft and its PDF data still show the client as it was when set.
- AC-21:
  - *Given* a draft,
  - *when* its Garantia, Validade, Termos, Observações and Pagamento (text taken from a payment method) are changed,
  - *then* only that quote changes, the Padrões are unchanged, and renaming or deleting the payment method does not change the quote's Pagamento.

### Lines and catalog
- AC-10:
  - *Given* catalog equipment "Haste de canto" and "Fio de aço inox",
  - *when* the catalog is searched for "HASTE" and for "aco",
  - *then* "Haste de canto" and "Fio de aço inox" are returned respectively.
- AC-11:
  - *Given* a catalog equipment at R$ 32,00 with unit `un`,
  - *when* it is added to a draft with quantity 4 and the line's price is then set to R$ 30,00,
  - *then* the line holds its own name, unit `un` and R$ 30,00 × 4 = R$ 120,00, and the catalog still says R$ 32,00.
- AC-12:
  - *Given* that line,
  - *when* the same equipment is added again with quantity 9998,
  - *then* there is one line with quantity 9999 at R$ 30,00. (D-13)
- AC-13:
  - *Given* a draft that already has service S,
  - *when* S is added again,
  - *then* no line is inserted and the store identifies the existing line, so the UI can open it.
- AC-14:
  - *Given* a service line,
  - *when* its description and price are changed on the quote,
  - *then* the line has the new values, the catalog service is unchanged, and the line has quantity 1 and no unit.
- AC-15:
  - *Given* no catalog equipment named "placa de advertencia",
  - *when* it is confirmed as an Item novo with unit `un` and price R$ 6,40,
  - *then* the catalog gains "Placa de advertencia" (`un`, R$ 6,40), and the new draft line points to it and is flagged "novo no catálogo".
- AC-16:
  - *Given* that draft is saved,
  - *when* its lines are read, or another quote adds the same item,
  - *then* no line carries the "novo no catálogo" flag.
- AC-17:
  - *Given* that flagged line,
  - *when* it is removed,
  - *then* the quote total drops by its subtotal and the catalog item stays.
- AC-18:
  - *Given* a draft line copied from catalog item X,
  - *when* X's name and price are edited,
  - *then* the line keeps its name and price.
- AC-19:
  - *Given* a draft line copied from catalog item X,
  - *when* X is deleted,
  - *then* the line remains with its copy, and the PDF data includes it.
- AC-20:
  - *Given* the Catálogo service create and edit forms,
  - *when* they are shown,
  - *then* they have no Unit field, and stored services have no unit.

### PDF
- AC-23:
  - *Given* a quote with a service, two equipment lines, all four Condições and Observações,
  - *when* the PDF entry point renders it,
  - *then*:
    - Serviços prints as "Serviço · Valor" with the description under the name;
    - Equipamentos prints Descrição/Qtd/Un/Preço/Total;
    - the terms block is labelled "Termos";
    - the Condições come from the quote's copy;
    - Observações is the last section.
- AC-24:
  - *Given* a quote whose Garantia and Termos are empty,
  - *when* it is rendered,
  - *then* neither appears and no fallback text is printed. (D-9)
- AC-28:
  - *Given* a quote saved with renderer version 1,
  - *when* a newer renderer version is registered and both that quote and a draft are rendered,
  - *then* the saved quote is drawn by v1 and the draft by the newest version. (D-12, D-19)

### Saving, copy and delete
- AC-25:
  - *Given* a draft with a client and a line,
  - *when* its PDF is rendered,
  - *then* it is still a draft.
- AC-26:
  - *Given* a draft with a client and one line priced R$ 0,00,
  - *when* it is saved,
  - *then* it is saved with total R$ 0,00 recorded and the newest renderer version stored.
  - Saving a draft without a client, or without lines, is refused. (D-8)
- AC-29:
  - *Given* a saved quote,
  - *when* any store write targets its client, lines, Condições or Observações,
  - *then* the write is refused and nothing changes.
- AC-31:
  - *Given* a saved quote,
  - *when* it is copied (Editar),
  - *then* a new draft exists, created today with the newest renderer version, holding the same client copy, lines (no "novo" flags), Condições, Observações and Preço dos equipamentos fields.
  - The original is unchanged, and later writes to the copy do not touch it.
- AC-32:
  - *Given* a saved quote or a draft,
  - *when* it is deleted,
  - *then* the quote and its lines are gone.

### Wizard still works
- AC-103:
  - *Given* the adapted wizard,
  - *when* a client is picked, a service and an equipment are added, the quote is saved in Revisar and its PDF is opened,
  - *then* the PDF shows that client and those lines, and the quote is listed as Salvo. (D-20)

### Failure
- AC-F1:
  - *Given* the database rejects writes,
  - *when* a line is added, a client set, a Condição changed or a draft saved,
  - *then* the call returns failure, `latestErrorMessage()` explains it, and the quote is unchanged.
- AC-F3:
  - *Given* a backup file at `user_version` 1,
  - *when* it is imported,
  - *then* the import is refused with its own error, the current data is unchanged, and Configurações shows the "backup from an older version" SnackBar. (D-11)
- AC-F4:
  - *Given* opening or recreating the database fails,
  - *when* the store opens,
  - *then* `open()` returns false, and the app shows the existing error screen with "Tentar de novo".
- AC-F6:
  - *Given* a quote whose stored renderer version this build does not know,
  - *when* the PDF entry point is asked to render it,
  - *then* it reports an error instead of throwing, and nothing is written. (A-3)
- AC-F7:
  - *Given* the database rejects writes,
  - *when* a quote is copied or deleted,
  - *then* the call returns failure, and no quote is created or removed.

## Touched boundaries
- sqlite3 open and wipe for v < 2: AC-F4
- sqlite3 writes (drafts, lines, copies, Item novo, save, copy, delete): AC-F1, AC-F7
- backup import (`file_picker` + sqlite): AC-F3
- printing / pdf (render entry point): AC-F6

**API maturity hint:** `settled`. The store's shape is dictated by the ADRs and these ACs, and it is exercised end to end by store tests.
