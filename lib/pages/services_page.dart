import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/add_card_widget.dart";
import "package:delforte/design_system/widgets/catalog_card_widget.dart";
import "package:delforte/design_system/widgets/dialog_field_widget.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/search_field_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store.dart";
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
    final String query = _searchController.text.trim().toLowerCase();
    final List<int> indexes = [
      for (var i = 0; i < widget.store.services.count; i++)
        if (query.isEmpty ||
            widget.store.services.nameAt(i).toLowerCase().contains(query) ||
            widget.store.services.descriptionAt(i).toLowerCase().contains(query))
          i,
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: VigilGradients.appBackdrop),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ClipRRect(
                borderRadius: VigilRadius.appFrameRadius,
                child: ColoredBox(color: VigilColors.canvas, child: _buildBody(indexes)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<int> indexes) {
    return Column(
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
            QuoteFlowRoute(QuoteStep.items, selectedClientId: widget.selectedClientId),
          ),
        ),
        Expanded(
          child: ListView(
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
                  price: _formatMoney(widget.store.services.priceCentsAt(index)),
                  icon: _catalogIcon(widget.store.services.nameAt(index)),
                  expanded: _expandedId == widget.store.services.idAt(index),
                  selectedQuantity: _draftQuantity(widget.store.services.idAt(index)),
                  onToggle: () => setState(() {
                    final int id = widget.store.services.idAt(index);
                    _expandedId = _expandedId == id ? null : id;
                  }),
                  onAdd: () => _addDraftLine(widget.store.services.idAt(index)),
                  onDecrease: () => _changeDraftQuantity(widget.store.services.idAt(index), -1),
                  onIncrease: () => _changeDraftQuantity(widget.store.services.idAt(index), 1),
                  onRemove: () => _removeDraftLine(widget.store.services.idAt(index)),
                ),
              AddCard(label: "Add new service", onTap: _showCatalogDialog),
            ],
          ),
        ),
      ],
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
    final bool ok = widget.store.addDraftLine(quoteLineService, refId, 1);
    if (!ok) _showSnack(widget.store.latestErrorMessage());
  }

  void _changeDraftQuantity(int refId, int delta) {
    final int index = widget.store.draft.lineIndex(quoteLineService, refId);
    if (index < 0) {
      if (delta > 0) _addDraftLine(refId);
      return;
    }
    final bool ok = widget.store.changeDraftQuantity(index, delta);
    if (!ok) _showSnack(widget.store.latestErrorMessage());
  }

  void _removeDraftLine(int refId) {
    final int index = widget.store.draft.lineIndex(quoteLineService, refId);
    if (index >= 0 && !widget.store.removeDraftLine(index)) {
      _showSnack(widget.store.latestErrorMessage());
    }
  }

  Future<void> _showCatalogDialog() async {
    final TextEditingController name = TextEditingController();
    final TextEditingController description = TextEditingController();
    final TextEditingController price = TextEditingController();
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Add Service"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DialogField(controller: name, label: "Name"),
                DialogField(controller: description, label: "Description"),
                DialogField(controller: price, label: "Price", keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
    if (saved == true) {
      final int cents = _parseMoneyCents(price.text);
      final bool ok = widget.store.addService(name.text.trim(), description.text.trim(), cents);
      if (!ok) _showSnack(widget.store.latestErrorMessage());
    }
    name.dispose();
    description.dispose();
    price.dispose();
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

  String _formatMoney(int cents) {
    final int safe = cents < 0 ? 0 : cents;
    final int whole = safe ~/ 100;
    final int decimal = safe % 100;
    final String raw = whole.toString();
    final StringBuffer buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final int remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(".");
    }
    return "R\$ ${buffer.toString()},${decimal.toString().padLeft(2, "0")}";
  }

  int _parseMoneyCents(String value) {
    final String normalized = value.trim().replaceAll(".", "").replaceAll(",", ".");
    final double parsed = double.tryParse(normalized) ?? 0;
    if (parsed <= 0) return 0;
    return (parsed * 100).round();
  }
}
