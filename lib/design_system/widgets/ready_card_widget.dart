import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A card widget displaying a success or completion state.
///
/// This widget shows a check icon, title, subtitle, and a list of
/// chips. It uses a success-themed color scheme with a rounded
/// white container. Useful for indicating completed actions or states.
class ReadyCard extends StatelessWidget {
  /// Creates a ready card widget.
  ///
  /// [title] is the primary title text.
  /// [subtitle] is the secondary descriptive text.
  /// [chips] is the list of chip labels to display.
  const ReadyCard({required this.title, required this.subtitle, required this.chips, super.key});

  /// The primary title text.
  final String title;

  /// The secondary descriptive text.
  final String subtitle;

  /// The list of chip labels to display.
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
