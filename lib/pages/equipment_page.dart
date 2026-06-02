import "package:delforte/design_system/widgets/add_card_widget.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/catalog_card_widget.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/search_field_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({required this.store, required this.router, required this.draftId, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;
  final int draftId;

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  final TextEditingController _searchController = TextEditingController();
  int? _expandedId;

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
            final String query = _searchController.text.trim();
            final Map<int, int> quantities = _draftQuantities();
            final List<CatalogItem> items = query.isEmpty
                ? [
                    for (final int refId in quantities.keys)
                      widget.store.catalogById(.equipment, refId),
                  ].whereType<CatalogItem>().toList()
                : widget.store.searchCatalog(.equipment, query);
            return Column(
              children: [
                FlowHeader(
                  title: "Equipment",
                  stepIndex: 2,
                  total: widget.store.quoteSubtotal(widget.draftId, .equipment),
                  totalLabel: "Equipment Total",
                  onBack: () => widget.router.goTo(
                    QuoteFlowRoute(QuoteStep.services, draftId: widget.draftId),
                  ),
                  onContinue: () => widget.router.goTo(
                    QuoteFlowRoute(QuoteStep.review, draftId: widget.draftId),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SearchField(
                        controller: _searchController,
                        hintText: "Search to add equipment...",
                        onChanged: (name) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      for (final CatalogItem item in items)
                        CatalogCard(
                          name: item.name,
                          description: item.description,
                          price: formatMoney(item.priceCents),
                          icon: _catalogIcon(item.name),
                          expanded: _expandedId == item.id,
                          selectedQuantity: quantities[item.id] ?? 0,
                          onToggle: () => setState(() {
                            _expandedId = _expandedId == item.id ? null : item.id;
                          }),
                          onDecrease: () => _changeDraftQuantity(item.id, -1),
                          onIncrease: () => _changeDraftQuantity(item.id, 1),
                        ),
                      AddCard(
                        label: "Add new equipment",
                        onTap: () => widget.router.goTo(
                          EquipmentCreateRoute(draftId: widget.draftId),
                        ),
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

  /// Map of equipment refId -> quantity for the lines already in the draft.
  Map<int, int> _draftQuantities() {
    return {
      for (final QuoteLine line in widget.store.listQuoteLines(widget.draftId))
        if (line.type == CatalogItemType.equipment) line.refId: line.quantity,
    };
  }

  void _changeDraftQuantity(int refId, int delta) {
    setState(_searchController.clear);
    FocusScope.of(context).unfocus();
    final bool exists = widget.store
        .listQuoteLines(widget.draftId)
        .any((QuoteLine line) => line.type == CatalogItemType.equipment && line.refId == refId);
    if (exists) {
      if (!widget.store.changeDraftLineQuantity(widget.draftId, .equipment, refId, delta)) {
        _showSnack(widget.store.latestErrorMessage());
      }
      return;
    }
    if (delta < 0) return;
    if (!widget.store.addDraftLine(widget.draftId, .equipment, refId, 1)) {
      _showSnack(widget.store.latestErrorMessage());
    }
  }

  void _showSnack(String message) {
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  IconData _catalogIcon(String name) {
    final String value = name.toLowerCase();
    if (value.contains("camera") || value.contains("cctv")) return Icons.videocam_rounded;
    if (value.contains("alarm")) return Icons.alarm_on_rounded;
    if (value.contains("gate") || value.contains("motor")) return Icons.garage_rounded;
    if (value.contains("panel")) return Icons.electrical_services_rounded;
    return Icons.inventory_2_rounded;
  }
}
