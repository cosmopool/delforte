import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class ReadyCard extends StatelessWidget {
  const ReadyCard({required this.title, required this.subtitle, required this.chips, super.key});

  final String title;
  final String subtitle;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    const Color color = VigilColors.textSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: VigilColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: VigilColors.successSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check_circle_rounded, size: 34, color: VigilColors.success),
            ),
            const SizedBox(height: 13),
            Text(
              title,
              style: VigilType.title(color: VigilColors.textPrimary, size: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: VigilType.small(color: color, size: 13, weight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final String chip in chips)
                  VigilPill(
                    label: chip,
                    color: VigilColors.primary,
                    background: VigilColors.primarySoft,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
