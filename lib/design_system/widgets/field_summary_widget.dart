import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A widget that displays a label-value pair in a compact format.
///
/// This widget shows a label in uppercase followed by a value,
/// styled as a small card with a canvas background and border.
/// Useful for displaying summary information in a grid or list.
class FieldSummary extends StatelessWidget {
  /// Creates a field summary widget.
  ///
  /// [label] is the label text displayed in uppercase.
  /// [value] is the value text displayed below the label.
  const FieldSummary({required this.label, required this.value, super.key});

  /// The label text displayed in uppercase.
  final String label;

  /// The value text displayed below the label.
  final String value;

  @override
  Widget build(BuildContext context) {
    const Color color = VigilColors.textPrimary;
    const FontWeight weight = FontWeight.w800;
    const Color color2 = VigilColors.textMuted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VigilColors.canvas,
        border: Border.all(color: VigilColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: VigilType.small(color: color2, size: 10, weight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: VigilType.small(color: color, size: 11, weight: weight),
            ),
          ],
        ),
      ),
    );
  }
}
