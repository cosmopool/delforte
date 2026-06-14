import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/catalog_item_form_widget.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

class ServiceCreatePage extends StatefulWidget {
  const ServiceCreatePage({required this.store, required this.router, this.draftId, super.key});

  final QuoteStore store;
  final AppRouterDelegate router;
  final int? draftId;

  @override
  State<ServiceCreatePage> createState() => _ServiceCreatePageState();
}

class _ServiceCreatePageState extends State<ServiceCreatePage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _price = TextEditingController();
  int _unitId = 0;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: Column(
        children: [
          FlowHeader(title: strings.newService, onBack: () => widget.router.goTo(_origin())),
          Expanded(
            child: CatalogItemForm(
              store: widget.store,
              type: .service,
              nameController: _name,
              descriptionController: _description,
              priceController: _price,
              selectedUnitId: _unitId,
              onUnitChanged: (value) => setState(() => _unitId = value ?? 0),
              onSave: _save,
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      _showSnack(strings.serviceNameRequired);
      return;
    }
    final int cents = moneyStringToCents(_price.text);
    final bool catalogSaved = widget.store.addService(
      name,
      _description.text.trim(),
      cents,
      _unitId,
    );
    if (!catalogSaved) {
      _showSnack(widget.store.latestErrorMessage());
      return;
    }

    final int? draftId = widget.draftId;
    if (draftId != null) {
      final int insertedId = widget.store.lastCatalogId(.service);
      if (!widget.store.addDraftLine(draftId, .service, insertedId, 1)) {
        _showSnack(widget.store.latestErrorMessage());
        return;
      }
    }

    widget.router.goTo(_origin());
  }

  /// Where to return: the services step when editing a draft, or the catalog
  /// manager when created standalone (no draft).
  AppRoute _origin() => widget.draftId == null
      ? const CatalogRoute()
      : QuoteFlowRoute(QuoteStep.services, draftId: widget.draftId);

  void _showSnack(String message) {
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
