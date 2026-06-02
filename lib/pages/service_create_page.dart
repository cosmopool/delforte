import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/form_field_widget.dart";
import "package:delforte/design_system/widgets/form_section_divider.dart";
import "package:delforte/design_system/widgets/primary_button_widget.dart";
import "package:delforte/design_system/widgets/unit_dropdown_widget.dart";
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
          FlowHeader(
            title: "New Service",
            onBack: () =>
                widget.router.goTo(QuoteFlowRoute(QuoteStep.services, draftId: widget.draftId)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const FormSectionDivider(label: "Identity"),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _name,
                  label: "Service Name",
                  hint: "e.g. CCTV Installation",
                ),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _description,
                  label: "Description",
                  hint: "Brief description of what this service includes…",
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 24),
                const FormSectionDivider(label: "Pricing"),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FormFieldWidget(
                        onChanged: _updatePrice,
                        controller: _price,
                        label: "Default Price",
                        hint: "0,00",
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: UnitDropdownWidget(
                        store: widget.store,
                        label: "Unit",
                        selectedUnitId: _unitId,
                        onChanged: (value) => setState(() => _unitId = value ?? 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: "Save Service", icon: Icons.check_rounded, onPressed: _save),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updatePrice(String text) {
    final int digits = moneyStringToCents(text);
    final String decimal = formatMoney(digits);
    _price.text = decimal;
  }

  void _save() {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      _showSnack("Service name is required");
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

    widget.router.goTo(QuoteFlowRoute(QuoteStep.services, draftId: draftId));
  }

  void _showSnack(String message) {
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
