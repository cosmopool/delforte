import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class FieldSummary extends StatelessWidget {
  const FieldSummary({required this.label, required this.value, super.key});

  final String label;
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
