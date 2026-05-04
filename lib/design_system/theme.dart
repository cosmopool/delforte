import "package:delforte/design_system/colors.dart";
import "package:delforte/design_system/radius.dart";
import "package:delforte/design_system/space.dart";
import "package:delforte/design_system/stroke.dart";
import "package:delforte/design_system/type.dart";
import "package:flutter/material.dart";

abstract final class VigilTheme {
  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: VigilColors.primary,
      primary: VigilColors.primary,
      surface: VigilColors.surface,
    );
    return ThemeData(
      colorScheme: scheme,
      fontFamily: VigilType.fontFamily,
      scaffoldBackgroundColor: VigilColors.canvas,
      useMaterial3: true,
      textSelectionTheme: const TextSelectionThemeData(cursorColor: VigilColors.primary),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VigilColors.primary,
          foregroundColor: VigilColors.surface,
          shape: RoundedRectangleBorder(borderRadius: VigilRadius.cardRadius),
          textStyle: VigilType.body(color: VigilColors.surface, weight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VigilColors.textPrimary,
          side: VigilStroke.strong,
          shape: RoundedRectangleBorder(borderRadius: VigilRadius.cardRadius),
          textStyle: VigilType.body(weight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VigilColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VigilSpace.lg,
          vertical: VigilSpace.md,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: VigilStroke.subtle,
          borderRadius: VigilRadius.inputRadius,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: VigilStroke.primary,
          borderRadius: VigilRadius.inputRadius,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VigilColors.ink,
        contentTextStyle: VigilType.body(color: VigilColors.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: VigilRadius.inputRadius),
      ),
    );
  }
}
