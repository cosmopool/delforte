import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/panel_widget.dart";
import "package:delforte/design_system/widgets/primary_button_widget.dart";
import "package:delforte/design_system/widgets/secondary_button_widget.dart";
import "package:delforte/store/item_data.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";

class CatalogCreatePage extends StatelessWidget {
  const CatalogCreatePage({
    required this.store,
    required this.isService,
    required this.onBack,
    required this.onSaved,
    super.key,
  });

  final QuoteStore store;
  final bool isService;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: CatalogCreateBody(store: store, isService: isService, onBack: onBack, onSaved: onSaved),
    );
  }
}

class CatalogCreateBody extends StatefulWidget {
  const CatalogCreateBody({
    required this.store,
    required this.isService,
    required this.onBack,
    required this.onSaved,
    super.key,
  });

  final QuoteStore store;
  final bool isService;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  @override
  State<CatalogCreateBody> createState() => _CatalogCreateBodyState();
}

class _CatalogCreateBodyState extends State<CatalogCreateBody> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _price = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String label = widget.isService ? "Service" : "Equipment";
    return Column(
      children: [
        FlowHeader(title: "Add $label", onBack: widget.onBack),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Panel(
                title: "$label Details",
                child: Column(
                  children: [
                    _CatalogField(controller: _name, label: "Name"),
                    _CatalogField(controller: _description, label: "Description"),
                    _CatalogField(
                      controller: _price,
                      label: "Price",
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: "Save and Add to Quote",
                icon: Icons.check_rounded,
                onPressed: _save,
              ),
              const SizedBox(height: 10),
              SecondaryButton(label: "Cancel", icon: Icons.close_rounded, onPressed: widget.onBack),
            ],
          ),
        ),
      ],
    );
  }

  void _save() {
    final int cents = _parseMoneyCents(_price.text);
    final String name = _name.text.trim();
    final String description = _description.text.trim();
    final bool catalogSaved = widget.isService
        ? widget.store.addService(name, description, cents)
        : widget.store.addItem(name, description, cents);
    if (!catalogSaved) {
      _showSnack(widget.store.latestErrorMessage());
      return;
    }

    final ItemData data = widget.isService ? widget.store.services : widget.store.items;
    final int insertedId = data.idAt(data.count - 1);
    final bool lineSaved = widget.store.addDraftLine(
      widget.isService ? quoteLineService : quoteLineItem,
      insertedId,
      1,
    );
    if (!lineSaved) {
      _showSnack(widget.store.latestErrorMessage());
      return;
    }

    widget.onSaved();
  }

  void _showSnack(String message) {
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  int _parseMoneyCents(String value) {
    final String normalized = value.trim().replaceAll(".", "").replaceAll(",", ".");
    final double parsed = double.tryParse(normalized) ?? 0;
    if (parsed <= 0) return 0;
    return (parsed * 100).round();
  }
}

class _CatalogField extends StatelessWidget {
  const _CatalogField({required this.controller, required this.label, this.keyboardType});

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
