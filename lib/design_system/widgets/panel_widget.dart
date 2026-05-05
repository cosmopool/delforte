import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class Panel extends StatelessWidget {
  const Panel({required this.title, required this.child, super.key, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    const Color color = VigilColors.textMuted;
    const FontWeight weight = FontWeight.w900;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: VigilColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: VigilType.small(color: color, size: 10, weight: weight),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}
