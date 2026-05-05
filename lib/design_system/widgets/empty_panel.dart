import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A panel widget displayed when a list or section is empty.
///
/// This widget shows an icon, title, and subtitle to indicate
/// that no content is available. It uses a bordered white container
/// with rounded corners and centered text.
class EmptyPanel extends StatelessWidget {
  /// Creates an empty panel widget.
  ///
  /// [icon] is the icon displayed above the title.
  /// [title] is the primary text displayed in the panel.
  /// [subtitle] is the secondary descriptive text.
  const EmptyPanel({required this.icon, required this.title, required this.subtitle, super.key});

  /// The icon displayed above the title.
  final IconData icon;

  /// The primary text displayed in the panel.
  final String title;

  /// The secondary descriptive text.
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
