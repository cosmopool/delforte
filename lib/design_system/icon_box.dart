import "package:flutter/material.dart";

class VigilIconBox extends StatelessWidget {
  const VigilIconBox({
    required this.icon,
    required this.color,
    required this.background,
    super.key,
    this.size = 36,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size > 40 ? 13 : 11),
      ),
      child: Icon(icon, size: size * 0.52, color: color),
    );
  }
}
