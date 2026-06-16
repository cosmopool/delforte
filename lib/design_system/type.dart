import "package:delforte/design_system/colors.dart";
import "package:flutter/material.dart";

abstract final class VigilType {
  static const String fontFamily = "DM Sans";
  static const String monoFontFamily = "DM Mono";

  static TextStyle title({
    Color color = VigilColors.textPrimary,
    double size = 20,
    FontWeight weight = FontWeight.w700,
  }) {
    return TextStyle(
      color: color,
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: 1.12,
    );
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

  static TextStyle mono({
    Color color = VigilColors.textPrimary,
    FontWeight weight = FontWeight.w500,
    double size = 13,
  }) {
    return TextStyle(
      color: color,
      fontFamily: monoFontFamily,
      fontSize: size,
      fontWeight: weight,
      height: 1.2,
    );
  }
}
