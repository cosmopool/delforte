import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/add_card_widget.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/catalog_card_widget.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/search_field_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

class QuoteCatalogStep extends StatefulWidget {
  const QuoteCatalogStep({
    required this.store,
    required this.draftId,
    required this.type,
    required this.onBack,
    required this.onContinue,
    required this.onCreate,
    super.key,
  });

  final QuoteStore store;
  final int draftId;
  final CatalogItemType type;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onCreate;

  @override
  State<QuoteCatalogStep> createState() => _QuoteCatalogStepState();
}

class _QuoteCatalogStepState extends State<QuoteCatalogStep> {
  final TextEditingController _searchController = TextEditingController();
  int? _expandedId;

  bool get _isServices => widget.type == CatalogItemType.service;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListenableBuilder(
          listenable: widget.store.quotesNotifier,
          builder: (BuildContext context, Widget? _) {
            final Map<int, int> quantities = {};
            final Map<int, int> unitPrices = {};
            for (final QuoteLine line in widget.store.listQuoteLines(widget.draftId)) {
              if (line.type != widget.type) continue;
              quantities[line.refId] = line.quantity;
              unitPrices[line.refId] = line.unitPriceCents;
            }

            final String query = _searchController.text.trim();
            final List<CatalogItem> items = query.isEmpty
                ? [
                    for (final int refId in quantities.keys)
                      widget.store.catalogById(widget.type, refId),
                  ].whereType<CatalogItem>().toList()
                : widget.store.searchCatalog(widget.type, query);
            final IconData fallbackIcon = _isServices
                ? Icons.handyman_rounded
                : Icons.inventory_2_rounded;

            return Column(
              children: [
                FlowHeader(
                  title: _isServices ? strings.services : strings.equipment,
                  stepIndex: _isServices ? 1 : 2,
                  total: widget.store.quoteSubtotal(widget.draftId, widget.type),
                  totalLabel: _isServices ? strings.servicesTotal : strings.equipmentTotal,
                  onBack: widget.onBack,
                  onContinue: widget.onContinue,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SearchField(
                        controller: _searchController,
                        hintText: strings.searchAdd,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      for (final CatalogItem item in items)
                        CatalogCard(
                          name: item.name,
                          description: item.description,
                          price: formatMoney(unitPrices[item.id] ?? item.priceCents),
                          unitPrice: unitPrices[item.id] ?? item.priceCents,
                          icon: catalogItemIcon(item.name, fallback: fallbackIcon),
                          expanded: _expandedId == item.id,
                          selectedQuantity: quantities[item.id] ?? 0,
                          onToggle: () => setState(() {
                            _expandedId = _expandedId == item.id ? null : item.id;
                          }),
                          onDecrease: () => _changeDraftQuantity(item.id, -1),
                          onIncrease: () => _changeDraftQuantity(item.id, 1),
                          onUnitPriceChanged: (cents) => _setUnitPrice(item.id, cents),
                        ),
                      AddCard(
                        label: _isServices ? strings.createNewService : strings.createNewEquipment,
                        onTap: widget.onCreate,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _setUnitPrice(int refId, int cents) {
    if (!widget.store.setDraftLineUnitPrice(widget.draftId, widget.type, refId, cents)) {
      _showSnack(widget.store.latestErrorMessage());
    }
  }

  void _changeDraftQuantity(int refId, int delta) {
    setState(_searchController.clear);
    FocusScope.of(context).unfocus();
    final bool exists = widget.store
        .listQuoteLines(widget.draftId)
        .any((line) => line.type == widget.type && line.refId == refId);
    final bool changed = exists
        ? widget.store.changeDraftLineQuantity(widget.draftId, widget.type, refId, delta)
        : delta > 0 && widget.store.addDraftLine(widget.draftId, widget.type, refId, 1);
    if (!changed && (exists || delta > 0)) _showSnack(widget.store.latestErrorMessage());
  }

  void _showSnack(String message) {
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
