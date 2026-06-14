import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/form_field_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";

/// A labeled unit dropdown styled to match [FormFieldWidget].
///
/// Lists unit abbreviations from the store. Falls back to a disabled
/// placeholder when no units are available.
class UnitDropdownWidget extends StatelessWidget {
  const UnitDropdownWidget({
    required this.store,
    required this.label,
    required this.selectedUnitId,
    required this.onChanged,
    super.key,
  });

  final QuoteStore store;
  final String label;
  final int selectedUnitId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final List<Unit> units = store.listUnits();
    final bool hasUnits = units.isNotEmpty;
    final List<DropdownMenuItem<int>> items = [
      for (final Unit unit in units)
        DropdownMenuItem(value: unit.id, child: Text(unit.abbreviation)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: VigilType.small(
            color: VigilColors.textSecondary,
            weight: FontWeight.w700,
            size: 11,
          ),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<int>(
          initialValue: hasUnits && store.unitById(selectedUnitId) != null ? selectedUnitId : null,
          items: items,
          onChanged: hasUnits ? onChanged : null,
          hint: Text(
            hasUnits ? strings.selectUnit : strings.noUnits,
            style: VigilType.body(color: VigilColors.textMuted, size: 14, weight: FontWeight.w400),
          ),
          icon: const Icon(Icons.expand_more_rounded, color: VigilColors.textMuted),
          decoration: formFieldDecoration(),
          style: VigilType.body(color: VigilColors.textPrimary, size: 14),
          dropdownColor: VigilColors.surface,
        ),
      ],
    );
  }
}
