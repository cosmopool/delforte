import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A primary button widget with an icon and label.
///
/// This button uses the design system's primary color and spans
/// the full width of its parent. It displays an icon followed
/// by a label text.
class PrimaryButton extends StatelessWidget {
  /// Creates a primary button widget.
  ///
  /// [label] is the button label text.
  /// [icon] is the icon displayed before the label.
  /// [onPressed] is the callback when the button is pressed.
  const PrimaryButton({
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
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: VigilColors.primary,
          foregroundColor: VigilColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: VigilRadius.cardRadius),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
