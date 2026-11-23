# Design system e orçamento em página única (pagina-unica)

> Split on 2026-11-23 into two pipeline runs: `pagina-unica-fundacao` (1a) and `pagina-unica-telas` (1b). This file stays as the full record they both refer to.

## Summary
The 5-step wizard is replaced by one quote page that is filled in top to bottom, in the same order the PDF prints. The client is picked in a bottom sheet. Services and equipment are added and edited in one shared bottom sheet that searches the catalog without regard to accents and creates an Item novo in the catalog when nothing matches. Each quote keeps its own copy of everything it shows: client, lines, Condições and Observações. A quote is either Rascunho or Salvo. A saved quote never changes. Editar makes a fresh draft copy, and the PDF of a saved quote is always drawn by the PDF renderer version that was current when it was saved. The design system becomes a committed HTML gallery mirrored in `lib/design_system/`, with a token-parity test between the two. The database starts over at `user_version` 2, and that schema already holds the columns part 2 needs.

## Specified
- **S-1 Design system name and colours:** "O nome continua Vigil, com a identidade visual de hoje. Entram três cores novas: `paper` #E8EBF2, `blueM` #5499EE e `pin` #F2542D."
- **S-2 Gallery file:**
  - "A galeria é o arquivo `docs/design-system.html`, que vai para o repositório."
  - "As fontes vêm de `assets/fonts`, sem CDN."
- **S-3 HTML wins:** "O HTML manda … Um teste compara os tokens do `:root` do HTML com as constantes Dart e falha quando são diferentes."
- **S-4 Starting point:** "O ponto de partida é o `DelforteApp.jsx` … não vai para o repositório e, depois que o design system existir, não é mais citado."
- **S-5 Order of components:** "Primeiro entram as fundações e os componentes que já existem. Os componentes novos nascem conforme a página única precisa deles."
- **S-6 Fresh database:**
  - "O schema é novo, `user_version` 2 … Ao abrir um banco com versão menor que 2, o app apaga tudo e recria do zero."
  - "Backups antigos deixam de ser aceitos na importação."
- **S-7 Schema born complete:**
  - "O schema já nasce completo, com tudo o que a parte 2 vai usar": Condições, Observações, and the Preço dos equipamentos fields (whether the unit price shows in the PDF, the mode, the closed total and the percentage);
  - the default for "Valor unitário no PDF" in Configurações, set to on.
- **S-8 Line copies:** "A linha do orçamento guarda a própria cópia de nome, descrição, unidade e preço, mais a referência ao item do catálogo."
- **S-9 States:** "Só existem dois: Rascunho e Salvo."
- **S-10 Draft lifecycle:**
  - The draft "Nasce ao tocar em 'Novo Orçamento', ainda sem cliente."
  - "É descartado se a pessoa sair dele sem cliente e sem nenhuma linha."
  - "Ao reabrir, a página abre no topo."
- **S-11 PDF of a draft:**
  - "Tocar em 'PDF' num rascunho mostra a prévia sem salvar."
  - "Tocar em Salvar ou em Compartilhar na tela do PDF salva o orçamento."
- **S-12 PDF screen:** "Tem o botão Compartilhar, que abre a folha de compartilhamento do sistema. Não tem 'Copiar link'."
- **S-13 List taps:** "Tocar num orçamento salvo abre o PDF dele. Tocar num rascunho abre a página do orçamento."
- **S-14 ⋮ menu:**
  - On a saved quote: Editar, which makes a "cópia completa de todos os dados … A data é a de hoje e não há ligação com o original", and Excluir, which "pede confirmação".
  - On a draft: Excluir only.
- **S-15 Page sections:** "Cliente, Serviços, Equipamentos, Condições, Observações."
- **S-16 Page header:**
  - "sem barra de etapas e sem botão 'Revisar'";
  - "o total do orçamento e o botão 'PDF'";
  - "só fica ativo quando há cliente e pelo menos uma linha".
- **S-17 Client picker:**
  - "É escolhido numa folha inferior, com a busca e o cadastro de cliente que existem hoje."
  - "A tela Clientes … continua como está."
- **S-18 One sheet for both:**
  - "Cada seção tem o seu '+', e os dois abrem a mesma folha inferior."
  - "Tocar na linha abre a folha preenchida, com 'Remover'."
- **S-19 Search:** "A busca ignora acento e maiúsculas e encontra o texto em qualquer parte do nome."
- **S-20 Item novo:**
  - The sheet warns with the exact name before saving, and the button reads "Adicionar e salvar no catálogo".
  - The name is saved "como foi digitado, só com a primeira letra maiúscula".
  - "A unidade e o preço digitados também vão para o catálogo."
  - The line shows a "novo no catálogo" tag "até o orçamento ser salvo".
- **S-21 Catalog line:**
  - "Nome e unidade ficam travados."
  - "O preço pode mudar só neste orçamento. No serviço, a descrição também."
  - "O catálogo não muda."
- **S-22 Service:**
  - "A quantidade é sempre 1 e não há unidade."
  - "Escolher um serviço que já está no orçamento abre a linha que já existe."
- **S-23 Equipment:**
  - "quantidade inteira de 1 a 9999";
  - "Escolher um equipamento que já está no orçamento soma a quantidade na linha existente, com limite de 9999."
- **S-24 Condições:**
  - "Pagamento, Garantia, Validade e Termos."
  - "Ao nascer, o orçamento recebe uma cópia dos Padrões."
  - "O Pagamento é escolhido da lista de formas de pagamento e fica guardado como texto copiado."
  - "Termos é texto livre."
  - "'Termos e Condições' passa a ser 'Termos', no app e no PDF."
- **S-25 Observações:** "É um campo único de texto livre, só deste orçamento. Começa vazio."
- **S-26 PDF changes:**
  - Serviços prints as "Serviço · Valor", with the description under the name.
  - The Condições come "da cópia guardada no orçamento".
  - "As Observações saem por último."
  - The Equipamentos table stays as it is today.
- **S-27 Catalog screens:** "O Catálogo mantém as telas próprias de cadastro … O cadastro de serviço perde o campo Unidade."
- **S-28 What goes:** "O assistente em etapas e tudo o que só ele usa."

## Decided
- **D-1 Client copy:** choosing a client copies its name, phone, e-mail, address and city into the quote, and the quote also keeps the client id as a reference. Editing or deleting the client later does not change any quote, draft or saved.
  - *Rejected:* copying only on save (it needs two read paths); keeping the reference only (that would break ADR 0002).
  - *Why:* this is the same pattern ADR 0001 sets for lines.
- **D-2 Deleting a catalog item:** the matching lines stay in drafts with their own copy. The behaviour at `quote_store.dart:913` that removes them goes.
  - *Rejected:* removing those lines from drafts.
  - *Why:* a quote is a document of its own.
- **D-3 Catalog edits:** editing a catalog item never changes any quote line. The price sync into drafts at `quote_store.dart:904-909` goes.
  - *Why:* S-8, ADR 0001 and the glossary.
- **D-4 Seeded units:** the v2 schema seeds the units `un`, `m`, `cx` and `kit`, and others can be registered as today. The debug-only seed in `main.dart` stops seeding units and stops passing a unit to services.
  - *Rejected:* allowing an equipment line without a unit; registering a unit from inside the sheet.
  - *Why:* in release the units table starts empty, so an Item novo of type equipment would have no unit to choose.
- **D-5 Payment methods list:** Configurações gains a list of payment methods (add and remove), backed by the existing `payment_methods` CRUD. The Pagamento default and each quote's Pagamento are picked from that list and stored as a text copy.
  - *Rejected:* also allowing free text in the quote; dropping the list.
- **D-6 Visual identity (DS):** where `DelforteApp.jsx` and today's Flutter code disagree, the current Flutter wins. Titles stay in DM Sans, with no Syne, and the radius tokens stay as they are. The JSX contributes the component and screen shapes plus the three new colours.
  - *Rejected:* letting the JSX win; using Syne in titles while keeping today's radii.
- **D-7 Share order:** Compartilhar saves first and then opens the share sheet.
  - If the person cancels the share sheet, the quote stays saved.
  - If saving fails, the share sheet does not open.
  - *Rejected:* saving only after a confirmed share.
- **D-8 Saving a zero total:** saving needs only a client and at least one line, the same condition that enables PDF. A total of R$ 0,00 is allowed, which replaces the `errQuoteEmpty` rule on total.
  - *Rejected:* blocking a zero total.
  - *Why:* part 2 creates R$ 0,00 items "sem preço" and must not block the PDF.
- **D-9 Empty conditions:** an empty Condição is left out of the PDF. The built-in fallback texts `pdfDefaultValidity`, `pdfDefaultWarranty`, `pdfDefaultTerms` and the payment "—" are removed.
  - *Rejected:* seeding those texts as Padrões; keeping the fallbacks in the PDF.
  - *Why:* what the person sees on the page is what the client gets.
- **D-10 Write failures:** a failed write on the page or in a sheet shows a SnackBar with `latestErrorMessage()`, the same convention as today. The open sheet stays open with what was typed, and the page does not change.
  - *Rejected:* translated per-code messages.
- **D-11 Old backups:** importing a backup with `user_version` < 2 shows its own SnackBar saying the backup comes from an older version of the app and cannot be imported. The current database is left untouched.
  - *Rejected:* reusing the generic `backupImportFailed`.
- **D-12 Versioned PDF renderer:** the PDF renderer is versioned.
  - Each time a quote's PDF is generated, the quote records the newest renderer version.
  - Viewing a PDF is a single entry point that dispatches to the renderer version stored on that quote.
  - A saved quote keeps the version it was saved with, so later layout changes never alter it.
  - A draft always records, and therefore renders with, the newest version.
  - Editar's copy is a new draft, so it uses the newest version.
  - *Rejected:* "segue as Configurações" with no versioning; storing the PDF bytes; freezing the company data.
  - *Source:* the user's answer, "o visualizador de pdf deve ser versionado … a função de visualizar é somente uma api que redireciona para a versão do visualizador que está salva no pdf".
- **D-13 Repeated equipment price:** when a chosen equipment is already in the quote, its quantity is added to the existing line, which keeps **its own** unit price. The current `addDraftLine` resets the price to the catalog price on conflict.
  - *Why:* S-21 says the price can change only in this quote, and that change must survive.
- **D-14 "novo no catálogo" tag:**
  - The tag is a flag on the line that created the item. Saving the quote clears it.
  - Another quote that picks the same item from the catalog does not show the tag.
  - Removing the line, or discarding or deleting the draft, leaves the item in the catalog, because it was saved when it was confirmed (S-20).
- **D-15 When a draft is discarded:** the S-10 rule runs when the person leaves the page, by back or home. It looks only at the client and the lines. Condições copied from the Padrões, or Observações typed into an otherwise empty draft, do not keep it alive.
- **D-16 Draft card without a client:** in the lists and on home, a draft without a client shows "Sem cliente" in place of the client name.
- **D-17 Contents of Editar's copy:**
  - The copy brings the client copy, every line with its copies (the tags cleared), the Condições, the Observações and the Preço dos equipamentos fields.
  - It does **not** bring the status (it is a draft) or the creation date (today).
  - Its renderer version is the newest (D-12).
- **D-18 Wizard leftovers:** the `draftId` parameters of `ClientCreateRoute`, `ServiceCreateRoute` and `EquipmentCreateRoute` go. These screens are reached only from Clientes and Catálogo. The existing tests that encode the replaced behaviour are rewritten:
  - draft price sync;
  - the empty-total refusal in `finalizeDraft`;
  - restoring a v1 backup.

- **D-19 Every PDF change is a new renderer version:**
  - Any change to what the PDF shows or how it is drawn creates a new renderer version, even before release. That includes layout, columns, labels, sections, order, fonts and fixed colours.
  - Existing versions are never edited, fixed or refactored.
  - The app must always show an old PDF as it was created.
  - In this part, the single-page PDF is renderer v1. The layout the app has today is not versioned, because the v2 schema starts empty and no quote refers to it.
  - Part 2's equipment-table changes will be a new version (v2).
  - *Rejected:* A-2, which edited v1 in place until release.
  - *Source:* the user ("cada alteração no pdf é para gerar uma versão nova do visualizador; o app deve visualizar os pdf antigos como eles foram criados"). Recorded in `docs/adr/0003-visualizador-de-pdf-versionado.md`.

## Assumed
All assumptions A-1 to A-10 were confirmed by the user on 2026-11-23 and now have the same standing as decisions.

- **A-1 Company data stays live:** a saved quote's header (company data, logo, accent colour) follows the current Configurações even though the renderer version is frozen. Only the layout code is versioned (D-12).
  - *Blast radius:* reopening an old saved quote shows the new logo or address. Freezing it later would need a company-data copy on each quote, which is one more schema change.
  - *Confirm with:* the user/PO.
- **A-2 Withdrawn (2026-11-23):** this assumption is replaced by D-19. Part 2 does **not** edit v1 in place.
- **A-3 Unknown renderer version:** a quote whose stored renderer version this build does not know (for example, imported from a newer app's backup) opens the PDF screen with an error message instead of crashing, and nothing is written.
  - *Blast radius:* low, because backups between versions are rare.
  - *Confirm with:* the user/PO.
- **A-4 Wipe or open failure:** if wiping and recreating a version < 2 database fails, the app shows the existing database error screen with "Tentar de novo" (`main.dart`). No new screen.
  - *Blast radius:* low.
  - *Confirm with:* the user/PO.
- **A-5 Silent reset:** the wipe of a version < 2 database is silent, with no notice, because nobody has used the app yet (from the grilling).
  - *Blast radius:* someone with real v1 data would lose it without warning.
  - *Confirm with:* the user/PO.
- **A-6 Preview failure:** if PDF rendering or the share call throws, the PDF screen shows a SnackBar and the quote state is unchanged. A share failure after a successful save leaves the quote saved (D-7).
  - *Blast radius:* low.
  - *Confirm with:* the user/PO.
- **A-7 Search scope:** the accent-insensitive search (S-19) applies to the catalog search in the add sheet. Client search keeps today's behaviour, with no accent folding, because S-17 says it is reused "como existe hoje".
  - *Blast radius:* "joao" will not find "João" in the client sheet.
  - *Confirm with:* the user/PO.
- **A-8 Discard is invisible:** discarding an empty draft is silent: no toast and no confirmation.
  - *Blast radius:* low.
  - *Confirm with:* the user/PO.
- **A-9 Excluir is permanent:** Excluir deletes the quote and its lines for good, with no trash, after a confirmation dialog.
  - *Blast radius:* there is no undo.
  - *Confirm with:* the user/PO.
- **A-10 Payment list from scratch:** the payment-method list is seeded empty, so the person registers their own. If the list is empty, Pagamento in the quote can only stay empty, and it is then left out of the PDF (D-9).
  - *Blast radius:* there are no payment conditions until a method is registered.
  - *Confirm with:* the user/PO.

## Non-goals
- **Part 2:**
  - The UI and the PDF effect of Preço dos equipamentos (the unit-price toggle, Soma/Total fechado/+%). Only their columns exist, at their defaults, and Editar copies them.
  - The `qtd [unidade] nome` reader and the chip with "Desfazer".
  - Detecting materials in the service description.
- **Out of the product:**
  - the DLF quote number;
  - decimal quantities;
  - merging catalog items;
  - a "compartilhado" state, versions of a quote, or any link between a copy and its original.
- **Not built in this part:**
  - "Copiar link" and the WhatsApp button;
  - any migration of data from v1, including v1 backups;
  - remembering the scroll position of a draft.
- **No changes to:**
  - the Clientes manager screen;
  - the Catálogo screens, apart from removing the service Unit field and the draft hooks;
  - the Templates screen.
- **No freezing:** company data, logo and accent colour in saved quotes (A-1); storing PDF bytes.
- **Search:** no accent folding in the client search or the quotes-list filter (A-7).
- **Design system:** no Syne font, no new radius tokens, no dark theme. The gallery is a static HTML file, with no build step and no CDN.
- **Tests:** no widget-level golden or screenshot tests of the gallery. The parity test checks tokens only.

## Acceptance criteria

### Design system
- **AC-1:**
  - *Given* `docs/design-system.html` and `lib/design_system/`,
  - *when* the parity test runs,
  - *then* every colour token in the HTML `:root` has a Dart constant with the same value, including `paper` #E8EBF2, `blueM` #5499EE and `pin` #F2542D, and the test fails if either side changes alone.
- **AC-2:**
  - *Given* the gallery is opened in a browser offline,
  - *when* it loads,
  - *then* it shows the foundations (colours, type, spacing, radii, shadows), every component with its states and the app screens, using fonts from `assets/fonts` only.

### Database
- **AC-3:**
  - *Given* a database file with `user_version` 1 containing clients and quotes,
  - *when* the store opens it,
  - *then* the database is at `user_version` 2, every table is empty except the seeded rows, and the units `un`, `m`, `cx` and `kit` exist.
- **AC-4:**
  - *Given* a fresh database,
  - *when* the store opens it,
  - *then* Configurações report "Valor unitário no PDF" as on.

### Drafts and the page
- **AC-5:**
  - *Given* the home screen,
  - *when* the person taps "Novo Orçamento",
  - *then* a draft without a client exists, the single quote page opens, and the PDF button is disabled.
- **AC-6:**
  - *Given* that new draft with no client and no lines,
  - *when* the person leaves the page,
  - *then* the draft no longer exists, even if Observações were typed (D-15).
- **AC-7:**
  - *Given* a draft with a client and no lines,
  - *when* the person leaves the page and reopens it from the list,
  - *then* the draft is still there and the page opens at the top.
- **AC-8:**
  - *Given* Padrões with payment "PIX", warranty "90 dias", validity "30 dias" and terms "T",
  - *when* a new draft is created and the Padrões are then changed,
  - *then* the draft's Condições still read PIX, 90 dias, 30 dias and T, and its Observações are empty.
- **AC-9:**
  - *Given* a draft,
  - *when* the person picks client "Residencial Oliveira" in the client sheet and that client's address is then edited in Clientes,
  - *then* the draft (and later its PDF) shows the address as it was when picked.

### Adding lines
- **AC-10:**
  - *Given* catalog equipment "Haste de canto",
  - *when* the person types "HASTE" or "haste" in the add sheet,
  - *then* "Haste de canto" is suggested, and typing "aco" suggests "Fio de aço inox".
- **AC-11:**
  - *Given* a catalog equipment priced R$ 32,00 with unit `un`,
  - *when* it is added with quantity 4 and its price is changed in the sheet to R$ 30,00,
  - *then* the line reads 4 un × R$ 30,00 = R$ 120,00, the catalog still says R$ 32,00, and the name and unit cannot be edited in the sheet.
- **AC-12:**
  - *Given* that line at R$ 30,00 × 4,
  - *when* the same equipment is chosen again with quantity 9998,
  - *then* there is still one line, with quantity 9999 at R$ 30,00 (D-13).
- **AC-13:**
  - *Given* a service already on the quote,
  - *when* the person chooses the same service from the sheet,
  - *then* no line is added and the existing line opens in the sheet.
- **AC-14:**
  - *Given* a service line from the catalog,
  - *when* its description and price are changed in the sheet,
  - *then* the line shows the new values, the catalog service is unchanged, and the line has no quantity or unit.
- **AC-15:**
  - *Given* no catalog item matches "placa de advertencia",
  - *when* the person confirms it as equipment with unit `un` and price R$ 6,40,
  - *then* the sheet first shows the exact name "Placa de advertencia", the button reads "Adicionar e salvar no catálogo", the catalog then contains "Placa de advertencia" (`un`, R$ 6,40), and the line shows "novo no catálogo".
- **AC-16:**
  - *Given* that quote is saved,
  - *when* any quote shows that line or picks that item,
  - *then* no "novo no catálogo" tag is shown.
- **AC-17:**
  - *Given* a line,
  - *when* the person taps it and then "Remover",
  - *then* the line is gone and the total drops by its subtotal. An Item novo it created stays in the catalog.

### Catalog independence
- **AC-18:**
  - *Given* a draft line copied from catalog item X,
  - *when* X's price and name are edited in Catálogo,
  - *then* the draft line keeps its name and price.
- **AC-19:**
  - *Given* a draft line copied from catalog item X,
  - *when* X is deleted from Catálogo,
  - *then* the draft line is still there with its copy, and the PDF prints it.
- **AC-20:**
  - *Given* the Catálogo service create screen,
  - *when* it is shown,
  - *then* it has no Unit field, and a service created there has no unit.

### Condições, Observações and payment methods
- **AC-21:**
  - *Given* a draft,
  - *when* the person changes its Garantia, Validade, Termos and Observações and picks a Pagamento from the payment-method list,
  - *then* only that quote changes, the Padrões stay as they were, and the Pagamento is stored as text, so renaming or deleting the method later does not change it.
- **AC-22:**
  - *Given* Configurações,
  - *when* the person adds and removes payment methods,
  - *then* the Pagamento default is chosen from that list.

### PDF
- **AC-23:**
  - *Given* a quote with a service, two equipment lines, all four Condições and Observações,
  - *when* its PDF is generated,
  - *then*:
    - Serviços prints as "Serviço · Valor" with the description under the name;
    - Equipamentos prints Descrição/Qtd/Un/Preço/Total;
    - the terms block is labelled "Termos";
    - the Condições come from the quote's copy;
    - Observações is the last section.
- **AC-24:**
  - *Given* a quote whose Garantia and Termos are empty,
  - *when* its PDF is generated,
  - *then* neither appears and no fallback text is printed (D-9).

### Saving and sharing
- **AC-25:**
  - *Given* a draft with a client and one line,
  - *when* the person taps PDF,
  - *then* the preview shows and the quote is still a draft.
- **AC-26:**
  - *Given* that preview,
  - *when* the person taps Salvar,
  - *then* the quote is saved with its total recorded, including a total of R$ 0,00 (D-8), and its stored renderer version is the newest.
- **AC-27:**
  - *Given* a draft preview,
  - *when* the person taps Compartilhar and then cancels the system sheet,
  - *then* the quote is saved (D-7).
- **AC-28:**
  - *Given* a saved quote rendered with version N,
  - *when* the newest renderer becomes N+1 and the saved quote is opened,
  - *then* it is drawn by renderer N, while a draft is drawn by N+1 (D-12).
- **AC-29:**
  - *Given* a saved quote,
  - *when* the person tries to change its client, lines, Condições or Observações through the store API,
  - *then* nothing changes. A saved quote has no edit path.

### Lists and the ⋮ menu
- **AC-30:**
  - *Given* the quotes list and the home recents,
  - *when* the person taps a saved quote,
  - *then* its PDF opens.
  - *When* they tap a draft, the quote page opens.
  - A draft without a client reads "Sem cliente".
- **AC-31:**
  - *Given* a saved quote,
  - *when* the person picks ⋮ → Editar, on the card or on the PDF screen,
  - *then*:
    - a new draft opens with today's date;
    - the draft carries the same client copy, lines, Condições, Observações and Preço dos equipamentos fields;
    - the original stays saved and unchanged;
    - later edits to the copy do not touch the original.
- **AC-32:**
  - *Given* a saved quote or a draft,
  - *when* the person picks ⋮ → Excluir and confirms,
  - *then* the quote and its lines are gone.
  - Cancelling the dialog leaves the quote as it was.
  - A draft's ⋮ offers only Excluir.

### Wizard removed
- **AC-33:**
  - *Given* the app,
  - *when* any screen is reached,
  - *then* there is no step bar, no "Revisar" and no wizard route. `QuoteStep` and `QuoteFlowRoute` do not exist.

### Failure
- **AC-F1:**
  - *Given* the database rejects writes,
  - *when* the person confirms a line in the add sheet,
  - *then* a SnackBar shows the store's error message, the sheet stays open with the typed values, and the page lines are unchanged.
- **AC-F2:**
  - *Given* saving fails,
  - *when* the person taps Compartilhar,
  - *then* a SnackBar shows the error, the share sheet does not open, and the quote stays a draft.
- **AC-F3:**
  - *Given* a backup file with `user_version` 1,
  - *when* the person imports it in Configurações,
  - *then* a SnackBar says the backup is from an older version and cannot be imported, and all current data is unchanged.
- **AC-F4:**
  - *Given* opening or recreating the database fails,
  - *when* the app starts,
  - *then* the existing database error screen with "Tentar de novo" is shown (A-4).
- **AC-F5:**
  - *Given* the share call throws after a successful save,
  - *when* the person taps Compartilhar,
  - *then* a SnackBar shows the failure and the quote stays saved (A-6).
- **AC-F6:**
  - *Given* a quote whose stored renderer version is unknown to this build,
  - *when* its PDF is opened,
  - *then* an error message is shown instead of a crash, and nothing is written (A-3).
- **AC-F7:**
  - *Given* the database rejects writes,
  - *when* the person picks Excluir or Editar from ⋮,
  - *then* a SnackBar shows the error and no quote is deleted or created.

## Touched boundaries
| Boundary | Where | Failure covered by |
|---|---|---|
| sqlite3 open, wipe and recreate for `user_version` < 2 | `QuoteStore.open` / `_migrate` | AC-F4 |
| sqlite3 writes: lines, client copy, Condições, Observações, Item novo in the catalog, payment methods | page, sheets, settings | AC-F1, AC-F7 |
| sqlite3 write on save (Salvar / Compartilhar) | PDF screen | AC-F2 |
| Backup import (`file_picker` + sqlite) | `importBackupBytes` / settings | AC-F3 |
| printing (render and `Printing.sharePdf`) | PDF screen | AC-F5, AC-F6 |
| dart:io / path_provider (database path) | `QuoteStore.open` | AC-F4 |

**API maturity hint for the manifest:** the store's quote API is reshaped (nullable client, copied columns, renderer version, copy and delete), and the page and the sheets are new UI. The store side is a candidate for `settled`, since its shape is dictated by the ADRs and this list. The page UI is `exploratory` until the user has used it on the device.
