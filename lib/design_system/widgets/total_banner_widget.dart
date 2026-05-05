import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class TotalBanner extends StatelessWidget {
  const TotalBanner({required this.label, required this.amount, super.key});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    const Color color = Colors.white;
    const Color color2 = Colors.white;
    const FontWeight weight = FontWeight.w800;
    return DecoratedBox(
      decoration: BoxDecoration(color: VigilColors.ink, borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: VigilType.body(color: color2, size: 15, weight: weight),
            ),
            Text(amount, style: VigilType.title(color: color, size: 26)),
          ],
        ),
      ),
    );
  }
}
