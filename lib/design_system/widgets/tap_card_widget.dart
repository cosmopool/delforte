import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A tappable card widget with selection state support.
///
/// This widget wraps the design system's [VigilSurface] component
/// to provide a tappable card that can display a selected state.
/// It's a simple wrapper that delegates to the underlying surface widget.
class TapCard extends StatelessWidget {
  /// Creates a tap card widget.
  ///
  /// [child] is the content widget displayed inside the card.
  /// [onTap] is the callback when the card is tapped.
  /// [selected] indicates whether the card is in a selected state.
  const TapCard({required this.child, required this.onTap, super.key, this.selected = false});

  /// The content widget displayed inside the card.
  final Widget child;

  /// The callback when the card is tapped.
  final VoidCallback onTap;

  /// Whether the card is in a selected state.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return VigilSurface(selected: selected, onTap: onTap, child: child);
  }
}
