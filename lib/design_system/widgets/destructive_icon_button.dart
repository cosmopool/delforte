import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class DestructiveIconButton extends StatelessWidget {
  const DestructiveIconButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFFF5F5),
          side: const BorderSide(color: Color(0xFFFFD0D0), width: 1.5),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: VigilRadius.cardRadius),
        ),
        onPressed: onPressed,
        child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFE54040)),
      ),
    );
  }
}
