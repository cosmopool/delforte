import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({required this.icon, required this.title, required this.subtitle, super.key});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    const FontWeight weight = FontWeight.w800;
    const Color color = VigilColors.textMuted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: VigilColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: VigilColors.textMuted),
            const SizedBox(height: 8),
            Text(
              title,
              style: VigilType.body(color: VigilColors.textPrimary, size: 14, weight: weight),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: VigilType.small(color: color, size: 11, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
