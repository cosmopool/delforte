import "package:flutter/material.dart";

/// A text field widget designed for use in dialogs.
///
/// This widget provides a text input field with a label and optional
/// keyboard type configuration. It uses an outlined border decoration
/// and includes bottom padding for spacing in dialog layouts.
class DialogField extends StatelessWidget {
  /// Creates a dialog field widget.
  ///
  /// [controller] is the text editing controller for the field.
  /// [label] is the label text displayed above the field.
  /// [keyboardType] is the optional keyboard type for the input.
  const DialogField({required this.controller, required this.label, super.key, this.keyboardType});

  /// The text editing controller for the field.
  final TextEditingController controller;

  /// The label text displayed above the field.
  final String label;

  /// The optional keyboard type for the input.
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
