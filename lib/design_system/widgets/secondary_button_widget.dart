import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
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
