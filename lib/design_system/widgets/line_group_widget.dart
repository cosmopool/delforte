import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/line_row_widget.dart";
import "package:delforte/design_system/widgets/panel_widget.dart";
import "package:flutter/material.dart";

class DraftLineView {
  const DraftLineView({required this.name, required this.quantity, required this.subtotal});

  final String name;
  final int quantity;
  final String subtotal;
}

class LineGroup extends StatelessWidget {
  const LineGroup({required this.title, required this.lines, required this.onEdit, super.key});

  final String title;
  final List<DraftLineView> lines;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    const Color color = VigilColors.textMuted;
    return Panel(
      title: title,
      trailing: IconButton(
        tooltip: "Edit $title",
        onPressed: onEdit,
        icon: const Icon(Icons.edit_rounded, size: 18),
      ),
      child: lines.isEmpty
          ? Text(
              "No lines added",
              style: VigilType.small(color: color, size: 13, weight: FontWeight.w600),
            )
          : Column(
              children: [
                for (var i = 0; i < lines.length; i++)
                  LineRow(line: lines[i], showDivider: i < lines.length - 1),
              ],
            ),
    );
  }
}
