import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({required this.text, required this.selected, super.key});

  final String text;
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
