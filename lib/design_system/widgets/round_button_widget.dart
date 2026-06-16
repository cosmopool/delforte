import "package:delforte/design_system.dart";
import "package:delforte/l10n/localization.dart";
import "package:flutter/material.dart";

/// A circular icon button widget.
///
/// This button uses the app action colors and automatically provides
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
    final bool isAdd = icon == Icons.add_rounded;
    return IconButton(
      tooltip: icon == Icons.add_rounded ? strings.increase : strings.decrease,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: isAdd ? VigilColors.primary : VigilColors.surface,
        foregroundColor: isAdd ? VigilColors.surface : VigilColors.textSecondary,
        fixedSize: const Size(36, 36),
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isAdd ? VigilColors.primary : VigilColors.borderStrong,
            width: 1.5,
          ),
        ),
      ),
      icon: Icon(icon, size: 18),
    );
  }
}
