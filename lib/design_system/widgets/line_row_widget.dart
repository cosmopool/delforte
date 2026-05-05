import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A data class representing a draft line item view.
///
/// This class holds the display data for a single line item,
/// including its name, quantity, and subtotal.
class DraftLineView {
  /// Creates a draft line view.
  ///
  /// [name] is the line item name.
  /// [quantity] is the line item quantity.
  /// [subtotal] is the line item subtotal as a string.
  const DraftLineView({required this.name, required this.quantity, required this.subtotal});

  /// The line item name.
  final String name;

  /// The line item quantity.
  final int quantity;

  /// The line item subtotal as a string.
  final String subtotal;
}

/// A row widget that displays a single draft line item.
///
/// This widget shows the line item name, quantity as a pill badge,
/// and subtotal. It optionally displays a divider below the row
/// when [showDivider] is true.
class LineRow extends StatelessWidget {
  /// Creates a line row widget.
  ///
  /// [line] is the draft line view to display.
  /// [showDivider] indicates whether to show a divider below the row.
  const LineRow({required this.line, required this.showDivider, super.key});

  /// The draft line view to display.
  final DraftLineView line;

  /// Whether to show a divider below the row.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    const Color color = VigilColors.textPrimary;
    const FontWeight weight = FontWeight.w800;
    const Color color2 = VigilColors.textSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: showDivider ? VigilColors.border : Colors.transparent),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      line.name,
                      overflow: TextOverflow.ellipsis,
                      style: VigilType.small(color: color2, size: 13, weight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  VigilPill(
                    label: "${line.quantity}x",
                    color: VigilColors.textMuted,
                    background: VigilColors.canvas,
                  ),
                ],
              ),
            ),
            Text(
              line.subtotal,
              style: VigilType.small(color: color, size: 11, weight: weight),
            ),
          ],
        ),
      ),
    );
  }
}
