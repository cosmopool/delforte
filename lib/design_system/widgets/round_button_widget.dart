import "package:flutter/material.dart";

class RoundButton extends StatelessWidget {
  const RoundButton({required this.icon, required this.onPressed, super.key});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: icon == Icons.add_rounded ? "Increase" : "Decrease",
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    );
  }
}
