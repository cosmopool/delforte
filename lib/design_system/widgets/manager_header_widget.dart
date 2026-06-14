import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:flutter/material.dart";

class ManagerHeader extends StatelessWidget {
  const ManagerHeader({
    required this.title,
    required this.actionLabel,
    required this.onBack,
    required this.onAction,
    this.bottom,
    super.key,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onBack;
  final VoidCallback onAction;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VigilColors.ink,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Row(
              children: [
                HeaderIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: strings.back,
                  onPressed: onBack,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: VigilType.title(color: VigilColors.surface, size: 19)),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: VigilColors.primary,
                    foregroundColor: VigilColors.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(actionLabel),
                ),
              ],
            ),
          ),
          ?bottom,
        ],
      ),
    );
  }
}
