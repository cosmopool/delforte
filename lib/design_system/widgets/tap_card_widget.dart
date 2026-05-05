import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class TapCard extends StatelessWidget {
  const TapCard({required this.child, required this.onTap, super.key, this.selected = false});

  final Widget child;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return VigilSurface(selected: selected, onTap: onTap, child: child);
  }
}
