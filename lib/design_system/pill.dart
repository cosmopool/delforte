import "package:delforte/design_system/radius.dart";
import "package:delforte/design_system/space.dart";
import "package:delforte/design_system/type.dart";
import "package:flutter/material.dart";

class VigilPill extends StatelessWidget {
  const VigilPill({required this.label, required this.color, required this.background, super.key});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: VigilRadius.chipRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VigilSpace.xs, vertical: VigilSpace.xxs),
        child: Text(
          label,
          style: VigilType.small(color: color, size: 10, weight: FontWeight.w900),
        ),
      ),
    );
  }
}
