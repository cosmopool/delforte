import "package:delforte/design_system.dart";
import "package:flutter/material.dart";

class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
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
