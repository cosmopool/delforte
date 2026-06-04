import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/line_row_widget.dart";
import "package:delforte/design_system/widgets/panel_widget.dart";
import "package:delforte/l10n/localization.dart";
import "package:flutter/material.dart";

export "package:delforte/design_system/widgets/line_row_widget.dart" show DraftLineView;

/// A panel widget that groups and displays a list of line items.
///
/// This widget displays a title with an edit button and shows a list
/// of draft line views. When the list is empty, it displays a
/// "No lines added" message. Each line is rendered using [LineRow].
class LineGroup extends StatelessWidget {
  /// Creates a line group widget.
  ///
  /// [title] is the group title displayed in the panel header.
  /// [lines] is the list of draft line views to display.
  /// [onEdit] is the callback when the edit button is pressed.
  const LineGroup({required this.title, required this.lines, required this.onEdit, super.key});

  /// The group title displayed in the panel header.
  final String title;

  /// The list of draft line views to display.
  final List<DraftLineView> lines;

  /// The callback when the edit button is pressed.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    const Color color = VigilColors.textMuted;
    return Panel(
      title: title,
      trailing: IconButton(
        tooltip: strings.editGroup(title),
        onPressed: onEdit,
        icon: const Icon(Icons.edit_rounded, size: 18),
      ),
      child: lines.isEmpty
          ? Text(
              strings.noLinesAdded,
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
