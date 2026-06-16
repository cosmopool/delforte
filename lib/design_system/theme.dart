import "package:delforte/design_system/colors.dart";
import "package:delforte/design_system/radius.dart";
import "package:delforte/design_system/space.dart";
import "package:delforte/design_system/stroke.dart";
import "package:delforte/design_system/type.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

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
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VigilColors.primary,
          foregroundColor: VigilColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: VigilRadius.cardRadius),
          textStyle: VigilType.body(size: 15, weight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: VigilColors.surface,
          foregroundColor: VigilColors.textPrimary,
          side: VigilStroke.strong,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: VigilRadius.cardRadius),
          textStyle: VigilType.body(size: 15, weight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VigilColors.primary,
          textStyle: VigilType.body(size: 13, weight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: VigilColors.textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VigilColors.surface,
        hintStyle: VigilType.body(color: VigilColors.textMuted, size: 14, weight: FontWeight.w400),
        prefixIconColor: VigilColors.textMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: VigilSpace.md),
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
