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

class ItemsPage extends StatefulWidget {
  const ItemsPage({required this.store, required this.router, this.selectedClientId, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;
  final int? selectedClientId;

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final TextEditingController _searchController = TextEditingController();
  int? _expandedId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<int> indexes = widget.store.items.searchIndexes(_searchController.text);

    return AppShell(
      body: Column(
        children: [
          FlowHeader(
            title: "Equipment",
            stepIndex: 2,
            total: _draftTotalFor(quoteLineItem),
            totalLabel: "Equipment Total",
            onBack: () => widget.router.goTo(
              QuoteFlowRoute(QuoteStep.services, selectedClientId: widget.selectedClientId),
            ),
            onContinue: () => widget.router.goTo(
              QuoteFlowRoute(QuoteStep.review, selectedClientId: widget.selectedClientId),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.store.quoteDraftNotifier,
              builder: (BuildContext context, Widget? _) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SearchField(
                      controller: _searchController,
                      hintText: "Search to add equipment...",
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    for (final int index in indexes)
                      CatalogCard(
                        name: widget.store.items.nameAt(index),
                        description: widget.store.items.descriptionAt(index),
                        price: formatMoney(widget.store.items.priceCentsAt(index)),
                        icon: _catalogIcon(widget.store.items.nameAt(index)),
                        expanded: _expandedId == widget.store.items.idAt(index),
                        selectedQuantity: _draftQuantity(widget.store.items.idAt(index)),
                        onToggle: () => setState(() {
                          final int id = widget.store.items.idAt(index);
                          _expandedId = _expandedId == id ? null : id;
                        }),
                        onAdd: () => _addDraftLine(widget.store.items.idAt(index)),
                        onDecrease: () => _changeDraftQuantity(widget.store.items.idAt(index), -1),
                        onIncrease: () => _changeDraftQuantity(widget.store.items.idAt(index), 1),
                        onRemove: () => _removeDraftLine(widget.store.items.idAt(index)),
                      ),
                    AddCard(
                      label: "Add new equipment",
                      onTap: () => widget.router.goTo(
                        ItemCreateRoute(selectedClientId: widget.selectedClientId),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _draftQuantity(int refId) {
    final int index = widget.store.draft.lineIndex(quoteLineItem, refId);
    return index < 0 ? 0 : widget.store.draft.quantities[index];
  }

  int _draftTotalFor(int type) {
    var total = 0;
    for (var i = 0; i < widget.store.draft.count; i++) {
      if (widget.store.draft.types[i] == type) total += widget.store.draft.subtotalCents[i];
    }
    return total;
  }

  void _addDraftLine(int refId) {
    final bool ok = widget.store.addDraftLine(quoteLineItem, refId, 1);
    if (!ok) _showSnack(widget.store.latestErrorMessage());
  }

  void _changeDraftQuantity(int refId, int delta) {
    final int index = widget.store.draft.lineIndex(quoteLineItem, refId);
    if (index < 0) {
      if (delta > 0) _addDraftLine(refId);
      return;
    }
    final bool ok = widget.store.changeDraftQuantity(index, delta);
    if (!ok) _showSnack(widget.store.latestErrorMessage());
  }

  void _removeDraftLine(int refId) {
    final int index = widget.store.draft.lineIndex(quoteLineItem, refId);
    if (index >= 0 && !widget.store.removeDraftLine(index)) {
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
