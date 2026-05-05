import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A text field widget for search input.
///
/// This widget provides a search input field with a search icon prefix.
/// It calls [onChanged] whenever the text content changes, making it
/// suitable for real-time search filtering.
class SearchField extends StatelessWidget {
  /// Creates a search field widget.
  ///
  /// [controller] is the text editing controller for the field.
  /// [hintText] is the placeholder text displayed when the field is empty.
  /// [onChanged] is called whenever the text content changes.
  const SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  /// The text editing controller for the field.
  final TextEditingController controller;

  /// The placeholder text displayed when the field is empty.
  final String hintText;

  /// Called whenever the text content changes.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded, color: VigilColors.textMuted),
      ),
    );
  }
}
