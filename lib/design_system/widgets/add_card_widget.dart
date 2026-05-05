import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class AddCard extends StatelessWidget {
  const AddCard({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return VigilSurface(
      background: VigilColors.canvas,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          VigilIconBox(
            icon: Icons.add_rounded,
            color: VigilColors.textMuted,
            background: VigilColors.border,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: _bodyStyle(color: VigilColors.textSecondary, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
