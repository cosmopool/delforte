import "package:flutter/material.dart";

/// A circular icon button widget.
///
/// This button uses a filled tonal style and automatically provides
/// tooltips based on the icon (Increase for add, Decrease for remove).
/// Designed for quantity adjustment controls.
class RoundButton extends StatelessWidget {
  /// Creates a round button widget.
  ///
  /// [icon] is the icon to display (typically add or remove).
  /// [onPressed] is the callback when the button is pressed.
  const RoundButton({required this.icon, required this.onPressed, super.key});

  /// The icon to display (typically add or remove).
  final IconData icon;

  /// The callback when the button is pressed.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: icon == Icons.add_rounded ? "Increase" : "Decrease",
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    );
  }
}
