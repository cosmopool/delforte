import "package:delforte/design_system/colors.dart";
import "package:flutter/material.dart";

abstract final class VigilType {
  static const String fontFamily = "Roboto";

  static TextStyle title({Color color = VigilColors.textPrimary, double size = 20}) {
    return TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w900, height: 1.12);
  }

  static TextStyle body({
    Color color = VigilColors.textPrimary,
    FontWeight weight = FontWeight.w600,
    double size = 14,
  }) {
    return TextStyle(color: color, fontSize: size, fontWeight: weight, height: 1.25);
  }

  static TextStyle small({
    Color color = VigilColors.textMuted,
    FontWeight weight = FontWeight.w600,
    double size = 11,
  }) {
    return TextStyle(color: color, fontSize: size, fontWeight: weight, height: 1.25);
  }
}
