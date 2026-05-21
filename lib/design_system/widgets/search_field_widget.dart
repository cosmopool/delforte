import "dart:async";

import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

/// A text field widget for search input with debounced [onChanged].
///
/// This widget provides a search input field with a search icon prefix.
/// [onChanged] is only fired after the user stops typing for [debounceMs]
/// milliseconds, preventing spam to the store.
class SearchField extends StatefulWidget {
  /// Creates a search field widget.
  ///
  /// [controller] is the text editing controller for the field.
  /// [hintText] is the placeholder text displayed when the field is empty.
  /// [onChanged] is called after debounce when the text content changes.
  /// [debounceMs] controls the delay before [onChanged] fires (default 300).
  const SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.debounceMs = 300,
    super.key,
  });

  /// The text editing controller for the field.
  final TextEditingController controller;

  /// The placeholder text displayed when the field is empty.
  final String hintText;

  /// Called after debounce when the text content changes.
  final ValueChanged<String> onChanged;

  /// Milliseconds to wait after the last keystroke before calling [onChanged].
  final int debounceMs;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search_rounded, color: VigilColors.textMuted),
      ),
    );
  }
}
