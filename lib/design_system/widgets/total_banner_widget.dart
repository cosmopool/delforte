import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A banner widget for displaying total amounts.
///
/// This widget displays a label and amount in a dark ink-colored
/// container with rounded corners. The amount is displayed in a
/// large title style, making it prominent for summary displays.
class TotalBanner extends StatelessWidget {
  /// Creates a total banner widget.
  ///
  /// [label] is the label text displayed on the left.
  /// [amount] is the amount text displayed on the right in large text.
  const TotalBanner({required this.label, required this.amount, super.key});

  /// The label text displayed on the left.
  final String label;

  /// The amount text displayed on the right in large text.
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
