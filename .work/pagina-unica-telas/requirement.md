# Telas da página única (pagina-unica-telas)

Slice 1b of `pagina-unica`. The full gathered requirement is `.work/pagina-unica/requirement.md`. Read it for the quoted source lines (S-*), the decisions (D-*) and the confirmed assumptions (A-*), which apply here unless this file says otherwise. This slice builds on slice 1a, `pagina-unica-fundacao`: the store API, the v2 schema, the design system gallery and PDF renderer v1 already exist, and the old wizard runs on top of them. Both slices land on `feat/pagina-unica` and reach `main` together.

## Summary
This slice replaces the adapted wizard with the single quote page:
- the client bottom sheet and the shared add/edit sheet for services and equipment;
- the page header with the total and the PDF button;
- Condições and Observações on the page;
- the PDF screen with Salvar, Compartilhar and ⋮;
- ⋮ on the quote cards;
- draft and saved taps in home and the quotes list;
- the payment-method list in Configurações.

It then deletes the wizard: pages, routes, `QuoteStep` and the `draftId` parameters. Every new component is added to `docs/design-system.html` and to `lib/design_system/` as it is built.

## Specified
From the parent requirement (`.work/pagina-unica/requirement.md`):
- S-5 (new components born here).
- S-10 to S-18.
- S-19 to S-25, UI side.
- S-28.

## Decided
From the parent requirement:
- D-5, the list UI in Configurações and choosing from the list.
- D-7.
- D-10.
- D-14, showing the tag.
- D-15, discarding on leave.
- D-16.
- D-18, the route parameters.

## Assumed
From the parent requirement, all confirmed by the user: A-6, A-7, A-8, A-9, A-10.

## Non-goals
In addition to the parent's:
- **No store or schema changes** beyond what a screen proves missing. Any such change is listed in the manifest with its reason.
- **No changes to PDF renderer v1** (D-19). This slice adds no PDF version.
- **No new tokens** unless the gallery gains them first (S-3).

## Acceptance criteria
IDs match the parent requirement.

### Page and drafts
- AC-5:
  - *Given* the home screen,
  - *when* the person taps "Novo Orçamento",
  - *then* a draft without a client exists, the single quote page opens with the sections Cliente, Serviços, Equipamentos, Condições and Observações, and the PDF button is disabled.
- AC-6:
  - *Given* that draft with no client and no lines,
  - *when* the person leaves the page by back or home,
  - *then* the draft no longer exists, even if Observações were typed, and no notice is shown. (A-8)
- AC-7:
  - *Given* a draft with a client and no lines,
  - *when* the person leaves and reopens it from the list,
  - *then* it is still there and the page opens at the top.
- AC-9:
  - *Given* the page,
  - *when* the person taps Cliente, searches and picks "Residencial Oliveira" in the bottom sheet (or registers a new client there),
  - *then* the page shows that client, and the PDF button enables once a line exists.

### Add and edit sheet
- AC-10:
  - *Given* catalog equipment "Haste de canto",
  - *when* the person types "HASTE" in the sheet opened from Equipamentos' "+",
  - *then* "Haste de canto" is suggested with its unit and price.
- AC-11:
  - *Given* a catalog equipment at R$ 32,00 (`un`),
  - *when* it is picked, the quantity is set to 4 and the price to R$ 30,00, and the person confirms,
  - *then* the page shows the line as 4 un × R$ 30,00 = R$ 120,00, the name and unit cannot be edited in the sheet, and the catalog still says R$ 32,00.
- AC-13:
  - *Given* a service already on the quote,
  - *when* the person picks it again in the sheet,
  - *then* no line is added and the existing line opens in the sheet.
- AC-14:
  - *Given* a service line,
  - *when* the person taps it and changes its description and price,
  - *then* the page shows the new values, and the sheet shows no quantity and no unit for services.
- AC-15:
  - *Given* no match for "placa de advertencia",
  - *when* the person fills in the unit `un` and the price R$ 6,40 in the sheet,
  - *then*:
    - the sheet warns, before confirming, with the exact name "Placa de advertencia";
    - the button reads "Adicionar e salvar no catálogo";
    - after confirming, the line shows "novo no catálogo".
- AC-16:
  - *Given* that quote is saved,
  - *when* any page or PDF shows that line,
  - *then* no "novo no catálogo" tag is shown.
- AC-17:
  - *Given* a line,
  - *when* the person taps it and then "Remover",
  - *then* the line is gone and the page total drops.

### Condições, Observações and payment methods
- AC-21:
  - *Given* a draft,
  - *when* the person taps a Condição and changes it (Pagamento is picked from the payment-method list) and types Observações,
  - *then* the page shows the new values, and Configurações' Padrões are unchanged.
- AC-22:
  - *Given* Configurações,
  - *when* the person adds and removes payment methods,
  - *then* the Pagamento default is picked from that list.
  - With an empty list, Pagamento stays empty. (A-10)

### PDF screen, saving and sharing
- AC-25:
  - *Given* a draft with a client and a line,
  - *when* the person taps PDF,
  - *then* the preview shows, the quote is still a draft, and the screen offers Salvar, Compartilhar and ⋮, with no "Copiar link".
- AC-26:
  - *Given* that preview,
  - *when* the person taps Salvar,
  - *then* the quote is saved, even with a total of R$ 0,00.
- AC-27:
  - *Given* a draft preview,
  - *when* the person taps Compartilhar and cancels the system sheet,
  - *then* the quote is saved. (D-7)

### Lists and the ⋮ menu
- AC-30:
  - *Given* home and the quotes list,
  - *when* the person taps a saved quote,
  - *then* its PDF opens.
  - *When* they tap a draft, the page opens at the top.
  - A draft without a client reads "Sem cliente". (D-16)
- AC-31:
  - *Given* a saved quote,
  - *when* the person picks ⋮ → Editar, on the card or on the PDF screen,
  - *then* a new draft opens on the page with today's date and the original's content, and the original stays saved and unchanged.
- AC-32:
  - *Given* a saved quote or a draft,
  - *when* the person picks ⋮ → Excluir and confirms,
  - *then* it disappears from the lists.
  - Cancelling leaves it.
  - A draft's ⋮ offers only Excluir.

### Wizard removed
- AC-33:
  - *Given* the app,
  - *when* any screen is reached,
  - *then* there is no step bar, no "Revisar" and no wizard route.
  - `QuoteStep` and `QuoteFlowRoute` do not exist, and the Clientes and Catálogo create screens have no `draftId`.

### Failure
- AC-F1:
  - *Given* the database rejects writes,
  - *when* the person confirms a line in the sheet,
  - *then* a SnackBar shows the store's error message, the sheet stays open with the typed values, and the page is unchanged. (D-10)
- AC-F2:
  - *Given* saving fails,
  - *when* the person taps Compartilhar,
  - *then* a SnackBar shows the error, the share sheet does not open, and the quote stays a draft.
- AC-F5:
  - *Given* the share call throws after a successful save,
  - *when* the person taps Compartilhar,
  - *then* a SnackBar shows the failure, and the quote stays saved. (A-6)
- AC-F6:
  - *Given* a quote with an unknown renderer version,
  - *when* its PDF screen opens,
  - *then* an error message is shown instead of the preview, and nothing is written. (A-3)
- AC-F7:
  - *Given* the database rejects writes,
  - *when* the person picks Excluir or Editar,
  - *then* a SnackBar shows the error, and no quote is deleted or created.

## Touched boundaries
- sqlite3 writes from the page, the sheets, ⋮ and Configurações: AC-F1, AC-F7
- sqlite3 write on Salvar / Compartilhar: AC-F2
- printing (preview and `Printing.sharePdf`): AC-F5, AC-F6

**API maturity hint:** `exploratory` for the page UI, until the user has used it on a device. The store calls it makes are settled by 1a.
