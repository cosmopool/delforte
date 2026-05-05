import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A secondary button widget with an icon and label.
///
/// This button uses an outlined style with the design system's border
/// styling and spans the full width of its parent. It displays an icon
/// followed by a label text, using a less prominent style than [PrimaryButton].
class SecondaryButton extends StatelessWidget {
  /// Creates a secondary button widget.
  ///
  /// [label] is the button label text.
  /// [icon] is the icon displayed before the label.
  /// [onPressed] is the callback when the button is pressed.
  const SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  /// The button label text.
  final String label;

  /// The icon displayed before the label.
  final IconData icon;

  /// The callback when the button is pressed.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: VigilColors.textPrimary,
          side: VigilStroke.strong,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: VigilRadius.cardRadius),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: VigilColors.textSecondary),
        label: Text(label),
      ),
    );
  }
}
