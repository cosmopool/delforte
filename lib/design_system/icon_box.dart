import "package:flutter/material.dart";

IconData catalogItemIcon(String name, {required IconData fallback}) {
  final String value = name.toLowerCase();
  if (value.contains("camera") || value.contains("cctv")) return Icons.videocam_rounded;
  if (value.contains("alarm")) return Icons.alarm_on_rounded;
  if (value.contains("gate") || value.contains("motor")) return Icons.garage_rounded;
  if (value.contains("panel")) return Icons.electrical_services_rounded;
  if (value.contains("lock")) return Icons.lock_rounded;
  if (value.contains("sensor")) return Icons.sensors_rounded;
  if (value.contains("maint") || value.contains("install")) return Icons.build_circle_rounded;
  return fallback;
}

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
