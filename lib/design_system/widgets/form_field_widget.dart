import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

InputDecoration formFieldDecoration({String? hintText, TextStyle? hintStyle}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: hintStyle,
    filled: true,
    fillColor: VigilColors.surface,
    border: OutlineInputBorder(
      borderRadius: VigilRadius.inputRadius,
      borderSide: VigilStroke.subtle,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: VigilRadius.inputRadius,
      borderSide: VigilStroke.subtle,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: VigilRadius.inputRadius,
      borderSide: VigilStroke.primary,
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: VigilRadius.inputRadius,
      borderSide: VigilStroke.subtle,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

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
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

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
          onChanged: onChanged,
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          decoration: formFieldDecoration(
            hintText: hint,
            hintStyle: VigilType.body(
              color: VigilColors.textMuted,
              size: 14,
              weight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
