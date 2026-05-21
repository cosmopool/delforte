import "package:delforte/design_system.dart";
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

class ServicesPage extends StatefulWidget {
  const ServicesPage({required this.store, required this.router, this.selectedClientId, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;
  final int? selectedClientId;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  int? _expandedId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<int> indexes;
    final String query = _searchController.text.trim();
    if (query.isEmpty) {
      indexes = <int>[];
      for (var i = 0; i < widget.store.draft.count; i++) {
        if (widget.store.draft.types[i] == quoteLineService) {
          final int catalogIndex = widget.store.services.indexOfId(widget.store.draft.refIds[i]);
          if (catalogIndex >= 0) indexes.add(catalogIndex);
        }
      }
    } else {
      indexes = widget.store.services.searchIndexes(query);
    }

    return AppShell(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ColoredBox(
          color: VigilColors.canvas,
          child: Column(
            children: [
              FlowHeader(
                title: "Services",
                stepIndex: 1,
                total: _draftTotalFor(quoteLineService),
                totalLabel: "Services Total",
                onBack: () => widget.router.goTo(
                  QuoteFlowRoute(QuoteStep.client, selectedClientId: widget.selectedClientId),
                ),
                onContinue: () => widget.router.goTo(
                  QuoteFlowRoute(QuoteStep.equipment, selectedClientId: widget.selectedClientId),
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
                          hintText: "Search to add a service...",
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        for (final int index in indexes)
                          CatalogCard(
                            name: widget.store.services.nameAt(index),
                            description: widget.store.services.descriptionAt(index),
                            price: formatMoney(widget.store.services.priceCentsAt(index)),
                            icon: _catalogIcon(widget.store.services.nameAt(index)),
                            expanded: _expandedId == widget.store.services.idAt(index),
                            selectedQuantity: _draftQuantity(widget.store.services.idAt(index)),
                            onToggle: () => setState(() {
                              final int id = widget.store.services.idAt(index);
                              _expandedId = _expandedId == id ? null : id;
                            }),
                            onAdd: () => _addDraftLine(widget.store.services.idAt(index)),
                            onDecrease: () =>
                                _changeDraftQuantity(widget.store.services.idAt(index), -1),
                            onIncrease: () =>
                                _changeDraftQuantity(widget.store.services.idAt(index), 1),
                            onRemove: () => _removeDraftLine(widget.store.services.idAt(index)),
                          ),
                        AddCard(
                          label: "Add new service",
                          onTap: () => widget.router.goTo(
                            ServiceCreateRoute(selectedClientId: widget.selectedClientId),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _draftQuantity(int refId) {
    final int index = widget.store.draft.lineIndex(quoteLineService, refId);
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
    setState(_searchController.clear);
    final bool ok = widget.store.addDraftLine(quoteLineService, refId, 1);
    if (!ok) _showSnack(widget.store.latestErrorMessage());
  }

  void _changeDraftQuantity(int refId, int delta) {
    setState(_searchController.clear);
    final int index = widget.store.draft.lineIndex(quoteLineService, refId);
    if (index < 0) {
      if (delta > 0) _addDraftLine(refId);
      return;
    }
    final bool ok = widget.store.changeDraftQuantity(index, delta);
    if (!ok) _showSnack(widget.store.latestErrorMessage());
  }

  void _removeDraftLine(int refId) {
    setState(_searchController.clear);
    final int index = widget.store.draft.lineIndex(quoteLineService, refId);
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
    return Icons.handyman_rounded;
  }
}
