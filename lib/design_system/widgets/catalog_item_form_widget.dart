import "package:delforte/design_system/widgets/form_field_widget.dart";
import "package:delforte/design_system/widgets/form_section_divider.dart";
import "package:delforte/design_system/widgets/primary_button_widget.dart";
import "package:delforte/design_system/widgets/unit_dropdown_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/store/quote_store.dart";
import "package:delforte/utils.dart";
import "package:flutter/material.dart";

class CatalogItemForm extends StatelessWidget {
  const CatalogItemForm({
    required this.store,
    required this.type,
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.selectedUnitId,
    required this.onUnitChanged,
    required this.onSave,
    super.key,
  });

  final QuoteStore store;
  final CatalogItemType type;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final int selectedUnitId;
  final ValueChanged<int?> onUnitChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final bool isService = type == CatalogItemType.service;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FormSectionDivider(label: isService ? strings.sectionIdentity : strings.sectionProduct),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: nameController,
          label: isService ? strings.serviceName : strings.equipmentName,
          hint: isService ? strings.serviceNameHint : strings.equipmentNameHint,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: descriptionController,
          label: strings.description,
          hint: isService ? strings.serviceDescriptionHint : strings.equipmentDescriptionHint,
          minLines: 3,
          maxLines: null,
          keyboardType: TextInputType.multiline,
        ),
        const SizedBox(height: 24),
        FormSectionDivider(label: strings.sectionPricing),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FormFieldWidget(
                controller: priceController,
                onChanged: (text) {
                  final String formatted = formatMoney(moneyStringToCents(text));
                  priceController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                },
                label: isService ? strings.defaultPrice : strings.unitPrice,
                hint: strings.priceHint,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: UnitDropdownWidget(
                store: store,
                label: strings.unit,
                selectedUnitId: selectedUnitId,
                onChanged: onUnitChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: isService ? strings.saveService : strings.saveEquipment,
          icon: Icons.check_rounded,
          onPressed: onSave,
        ),
      ],
    );
  }
}
