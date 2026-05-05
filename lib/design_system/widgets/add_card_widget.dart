import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A card widget that displays an add action with an icon and label.
///
/// The card is tappable and uses the design system's surface component
/// with a canvas background. It displays an add icon in an icon box
/// followed by the provided label text.
class AddCard extends StatelessWidget {
  /// Creates an add card widget.
  ///
  /// [label] is the text displayed next to the add icon.
  /// [onTap] is the callback when the card is tapped.
  const AddCard({required this.label, required this.onTap, super.key});

  /// The text label displayed next to the add icon.
  final String label;

  /// Callback invoked when the card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return VigilSurface(
      background: VigilColors.canvas,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          VigilIconBox(
            icon: Icons.add_rounded,
            color: VigilColors.textMuted,
            background: VigilColors.border,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: VigilType.body(
              color: VigilColors.textSecondary,
              size: 14,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
