import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A section divider used in form pages.
///
/// Displays an uppercase label centered between two horizontal lines,
/// matching the JSX `FormDivider` pattern.
class FormSectionDivider extends StatelessWidget {
  const FormSectionDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(height: 1, color: VigilColors.border)),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: VigilType.small(color: VigilColors.textMuted, weight: FontWeight.w700, size: 11),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(height: 1, color: VigilColors.border)),
      ],
    );
  }
}
