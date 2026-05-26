import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/design_system/widgets/form_field_widget.dart";
import "package:delforte/design_system/widgets/form_section_divider.dart";
import "package:delforte/design_system/widgets/primary_button_widget.dart";
import "package:delforte/design_system/widgets/unit_dropdown_widget.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/item_data.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

class EquipmentCreatePage extends StatefulWidget {
  const EquipmentCreatePage({
    required this.store,
    required this.router,
    this.selectedClientId,
    super.key,
  });

  final QuoteStore store;
  final AppRouterDelegate router;
  final int? selectedClientId;

  @override
  State<EquipmentCreatePage> createState() => _EquipmentCreatePageState();
}

class _EquipmentCreatePageState extends State<EquipmentCreatePage> {
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
            title: "New Equipment",
            onBack: () => widget.router.goTo(
              QuoteFlowRoute(QuoteStep.equipment, selectedClientId: widget.selectedClientId),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const FormSectionDivider(label: "Product"),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _name,
                  label: "Equipment Name",
                  hint: "e.g. IP Camera 4MP",
                ),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _description,
                  label: "Description",
                  hint: "Technical specs, compatibility notes…",
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
                        label: "Unit Price",
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
                PrimaryButton(label: "Save Equipment", icon: Icons.check_rounded, onPressed: _save),
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
      _showSnack("Equipment name is required");
      return;
    }
    final int cents = moneyStringToCents(_price.text);
    final bool catalogSaved = widget.store.addEquipment(
      name,
      _description.text.trim(),
      cents,
      _unitId,
    );
    if (!catalogSaved) {
      _showSnack(widget.store.latestErrorMessage());
      return;
    }

    final ItemData data = widget.store.equipments;
    final int insertedId = data.idAt(data.count - 1);
    final bool lineSaved = widget.store.addDraftLine(.equipment, insertedId, 1);
    if (!lineSaved) {
      _showSnack(widget.store.latestErrorMessage());
      return;
    }

    widget.router.goTo(
      QuoteFlowRoute(QuoteStep.equipment, selectedClientId: widget.selectedClientId),
    );
  }

  void _showSnack(String message) {
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
