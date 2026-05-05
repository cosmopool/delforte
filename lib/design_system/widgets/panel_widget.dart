import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A panel widget with a title and optional trailing widget.
///
/// This widget displays content in a bordered white container with
/// rounded corners. The title is displayed in uppercase at the top,
/// with an optional trailing widget (such as an edit button).
class Panel extends StatelessWidget {
  /// Creates a panel widget.
  ///
  /// [title] is the panel title displayed in uppercase.
  /// [child] is the content widget displayed below the title.
  /// [trailing] is the optional widget displayed next to the title.
  const Panel({required this.title, required this.child, super.key, this.trailing});

  /// The panel title displayed in uppercase.
  final String title;

  /// The content widget displayed below the title.
  final Widget child;

  /// The optional widget displayed next to the title.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    const Color color = VigilColors.textMuted;
    const FontWeight weight = FontWeight.w900;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: VigilColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: VigilType.small(color: color, size: 10, weight: weight),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}
