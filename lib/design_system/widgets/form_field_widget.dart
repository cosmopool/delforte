import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A labeled text field styled for full-page forms.
///
/// Matches the JSX form input style: white background, 1.5 px border,
/// 13 px radius, uppercase label above the field.
class FormFieldWidget extends StatelessWidget {
  const FormFieldWidget({
    required this.controller,
    required this.label,
    super.key,
    this.hint,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: VigilType.body(color: VigilColors.textMuted, size: 14, weight: FontWeight.w400),
            filled: true,
            fillColor: VigilColors.surface,
            border: OutlineInputBorder(
              borderRadius: VigilRadius.inputRadius,
              borderSide: const BorderSide(color: VigilColors.border, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: VigilRadius.inputRadius,
              borderSide: const BorderSide(color: VigilColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: VigilRadius.inputRadius,
              borderSide: const BorderSide(color: VigilColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
