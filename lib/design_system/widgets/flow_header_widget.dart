import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// An icon button widget styled for use in flow headers.
///
/// This button uses a semi-transparent white background and
/// foreground color, with a fixed size and rounded corners.
/// Designed for use in the [FlowHeader] widget.
class HeaderIconButton extends StatelessWidget {
  /// Creates a header icon button.
  ///
  /// [icon] is the icon to display.
  /// [tooltip] is the tooltip text for the button.
  /// [onPressed] is the callback when the button is pressed.
  const HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  /// The icon to display.
  final IconData icon;

  /// The tooltip text for the button.
  final String tooltip;

  /// The callback when the button is pressed.
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

/// A header widget for multi-step flows or navigation screens.
///
/// This widget displays a title with optional back and continue buttons.
/// It uses an ink background color and supports step indicators.
/// The header is designed for use in multi-step workflows.
class FlowHeader extends StatelessWidget {
  /// Creates a flow header widget.
  ///
  /// [title] is the header title text.
  /// [onBack] is the optional callback for the back button.
  /// [stepIndex] is the optional current step index.
  /// [total] is the optional total number of steps.
  /// [totalLabel] is the optional label for the total.
  /// [continueLabel] is the text for the continue button (defaults to "Continue").
  /// [onContinue] is the optional callback for the continue button.
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

  /// The header title text.
  final String title;

  /// The optional current step index.
  final int? stepIndex;

  /// The optional total number of steps.
  final int? total;

  /// The optional label for the total.
  final String? totalLabel;

  /// The text for the continue button.
  final String continueLabel;

  /// The optional callback for the back button.
  final VoidCallback? onBack;

  /// The optional callback for the continue button.
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
