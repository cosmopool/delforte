import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        foregroundColor: Colors.white.withValues(alpha: 0.80),
        fixedSize: const Size(34, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      icon: Icon(icon, size: 17),
    );
  }
}

class FlowHeader extends StatelessWidget {
  const FlowHeader({
    required this.title,
    super.key,
    this.onBack,
    this.stepIndex,
    this.total,
    this.totalLabel,
    this.continueLabel = "Continue",
    this.onContinue,
  });

  final String title;
  final int? stepIndex;
  final int? total;
  final String? totalLabel;
  final String continueLabel;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VigilColors.ink,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(
          children: [
            if (onBack != null) ...[
              HeaderIconButton(icon: Icons.arrow_back_rounded, tooltip: "Back", onPressed: onBack),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(title, style: VigilType.title(color: VigilColors.surface, size: 19)),
            ),
            if (onContinue != null)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: VigilColors.primary,
                  foregroundColor: VigilColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                ),
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(continueLabel),
              ),
          ],
        ),
      ),
    );
  }
}
