import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/add_card_widget.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/catalog_card_widget.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/search_field_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

class ServicesPage extends StatefulWidget {
  const ServicesPage({required this.store, required this.router, required this.draftId, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;
  final int draftId;

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
    return AppShell(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ColoredBox(
          color: VigilColors.canvas,
          child: ListenableBuilder(
            listenable: widget.store.quotesNotifier,
            builder: (BuildContext context, Widget? _) {
              final String query = _searchController.text.trim();
              final Map<int, int> quantities = _draftQuantities();
              final Map<int, int> unitPrices = _draftUnitPrices();
              final List<CatalogItem> items = query.isEmpty
                  ? [
                      for (final int refId in quantities.keys)
                        widget.store.catalogById(.service, refId),
                    ].whereType<CatalogItem>().toList()
                  : widget.store.searchCatalog(.service, query);
              return Column(
                children: [
                  FlowHeader(
                    title: strings.services,
                    stepIndex: 1,
                    total: widget.store.quoteSubtotal(widget.draftId, .service),
                    totalLabel: strings.servicesTotal,
                    onBack: () => widget.router.goTo(
                      QuoteFlowRoute(QuoteStep.client, draftId: widget.draftId),
                    ),
                    onContinue: () => widget.router.goTo(
                      QuoteFlowRoute(QuoteStep.equipment, draftId: widget.draftId),
                    ),
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
                            icon: _catalogIcon(item.name),
                            expanded: _expandedId == item.id,
                            selectedQuantity: quantities[item.id] ?? 0,
                            onToggle: () => setState(() {
                              _expandedId = _expandedId == item.id ? null : item.id;
                            }),
                            onDecrease: () => _changeDraftQuantity(item.id, -1),
                            onIncrease: () => _changeDraftQuantity(item.id, 1),
                            onUnitPriceChanged: (int cents) => _setUnitPrice(item.id, cents),
                          ),
                        AddCard(
                          label: strings.createNewService,
                          onTap: () =>
                              widget.router.goTo(ServiceCreateRoute(draftId: widget.draftId)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Map of service refId -> quantity for the lines already in the draft.
  Map<int, int> _draftQuantities() {
    return {
      for (final QuoteLine line in widget.store.listQuoteLines(widget.draftId))
        if (line.type == CatalogItemType.service) line.refId: line.quantity,
    };
  }

  /// Map of service refId -> unit price (cents) for the lines in the draft.
  Map<int, int> _draftUnitPrices() {
    return {
      for (final QuoteLine line in widget.store.listQuoteLines(widget.draftId))
        if (line.type == CatalogItemType.service) line.refId: line.unitPriceCents,
    };
  }

  void _setUnitPrice(int refId, int cents) {
    if (!widget.store.setDraftLineUnitPrice(widget.draftId, .service, refId, cents)) {
      _showSnack(widget.store.latestErrorMessage());
    }
  }

  void _changeDraftQuantity(int refId, int delta) {
    setState(_searchController.clear);
    FocusScope.of(context).unfocus();
    final bool exists = widget.store
        .listQuoteLines(widget.draftId)
        .any((QuoteLine line) => line.type == CatalogItemType.service && line.refId == refId);
    if (exists) {
      if (!widget.store.changeDraftLineQuantity(widget.draftId, .service, refId, delta)) {
        _showSnack(widget.store.latestErrorMessage());
      }
      return;
    }
    if (delta < 0) return;
    if (!widget.store.addDraftLine(widget.draftId, .service, refId, 1)) {
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
