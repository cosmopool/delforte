import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// An avatar widget that displays initials text.
///
/// This widget shows text initials in a rounded container. The background
/// color changes based on the selection state, using the primary color
/// when selected and the ink elevated color when not selected.
class InitialsAvatar extends StatelessWidget {
  /// Creates an initials avatar widget.
  ///
  /// [text] is the initials text to display.
  /// [selected] indicates whether the avatar is in a selected state.
  const InitialsAvatar({required this.text, required this.selected, super.key});

  /// The initials text to display.
  final String text;

  /// Whether the avatar is in a selected state.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? VigilColors.primary : VigilColors.inkElevated,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: VigilType.small(color: VigilColors.surface, size: 13, weight: FontWeight.w900),
      ),
    );
  }
}
