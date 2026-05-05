import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class DraftLineView {
  const DraftLineView({required this.name, required this.quantity, required this.subtotal});

  final String name;
  final int quantity;
  final String subtotal;
}

class LineRow extends StatelessWidget {
  const LineRow({required this.line, required this.showDivider, super.key});

  final DraftLineView line;
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
