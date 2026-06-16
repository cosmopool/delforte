import "package:delforte/design_system.dart";
import "package:delforte/l10n/localization.dart";
import "package:delforte/utils.dart";
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
        minimumSize: const Size(34, 34),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      icon: Icon(icon, size: 17),
    );
  }
}

/// Compact blue action used on navy app headers.
class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
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
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: VigilColors.primary,
        foregroundColor: VigilColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
        textStyle: VigilType.body(size: 13, weight: FontWeight.w600),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(label), const SizedBox(width: 6), Icon(icon, size: 15)],
      ),
    );
  }
}

class HeaderFittedText extends StatelessWidget {
  const HeaderFittedText({
    required this.text,
    required this.style,
    super.key,
    this.alignment = Alignment.centerLeft,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final Alignment alignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(text, maxLines: 1, softWrap: false, textAlign: textAlign, style: style),
      ),
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
  /// [continueLabel] is the text for the continue button (defaults to [Localization.continueLabel]).
  /// [onContinue] is the optional callback for the continue button.
  const FlowHeader({
    required this.title,
    super.key,
    this.onBack,
    this.stepIndex,
    this.total,
    this.totalLabel,
    this.continueLabel,
    this.continueIcon,
    this.onContinue,
  });

  /// The header title text.
  final String title;

  /// Icon for the continue/action button. Defaults to a forward arrow.
  final IconData? continueIcon;

  /// The optional current step index.
  final int? stepIndex;

  /// The optional total number of steps.
  final int? total;

  /// The optional label for the total.
  final String? totalLabel;

  /// The text for the continue button. Falls back to [Localization.continueLabel].
  final String? continueLabel;

  /// The optional callback for the back button.
  final VoidCallback? onBack;

  /// The optional callback for the continue button.
  final VoidCallback? onContinue;

  List<String> get _steps => [
    strings.client,
    strings.services,
    strings.equipment,
    strings.review,
    strings.send,
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VigilColors.ink,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, stepIndex != null ? 0 : 14),
            child: Row(
              children: [
                if (onBack != null) ...[
                  HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: strings.back,
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: HeaderFittedText(
                    text: title,
                    style: VigilType.title(color: VigilColors.surface, size: 19),
                  ),
                ),
                if (onContinue != null)
                  HeaderActionButton(
                    label: continueLabel ?? strings.continueLabel,
                    icon: continueIcon ?? Icons.arrow_forward_rounded,
                    onPressed: onContinue!,
                  ),
              ],
            ),
          ),
          if (stepIndex != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: _buildStepBar(stepIndex!),
            ),
          if (total != null && totalLabel != null)
            Container(
              color: Colors.white.withValues(alpha: 0.06),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    totalLabel!,
                    style: VigilType.body(
                      color: Colors.white.withValues(alpha: 0.45),
                      weight: FontWeight.w500,
                      size: 12,
                    ),
                  ),
                  Text(
                    formatMoney(total!),
                    style: VigilType.mono(
                      color: Colors.white.withValues(alpha: 0.85),
                      weight: FontWeight.w500,
                      size: 15,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepBar(int stepIndex) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (int i = 0; i < _steps.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i < stepIndex
                            ? VigilColors.primary
                            : i == stepIndex
                            ? const Color(0xFF5499EE)
                            : Colors.white.withValues(alpha: 0.13),
                      ),
                    ),
                    const SizedBox(height: 7),
                    HeaderFittedText(
                      text: _steps[i],
                      alignment: Alignment.center,
                      textAlign: TextAlign.center,
                      style: VigilType.small(
                        size: 10,
                        weight: i == stepIndex ? FontWeight.w600 : FontWeight.w400,
                        color: i == stepIndex
                            ? Colors.white.withValues(alpha: 0.95)
                            : i < stepIndex
                            ? Colors.white.withValues(alpha: 0.50)
                            : Colors.white.withValues(alpha: 0.25),
                      ).copyWith(letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
              if (i < _steps.length - 1) const SizedBox(width: 5),
            ],
          ],
        ),
      ],
    );
  }
}
