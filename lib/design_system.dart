import "package:flutter/material.dart";

/// Delforte design tokens and app-level component primitives.
///
/// This file is intentionally dependency-free. It keeps the visual language
/// consistent without introducing a state-management or UI package.
abstract final class VigilColors {
  static const Color ink = Color(0xFF080F26);
  static const Color inkElevated = Color(0xFF101D40);
  static const Color primary = Color(0xFF1E66E1);
  static const Color primaryPressed = Color(0xFF1559C4);
  static const Color primarySoft = Color(0xFFEEF4FF);
  static const Color success = Color(0xFF0DBE84);
  static const Color successSoft = Color(0xFFE7F8F3);
  static const Color canvas = Color(0xFFF3F5FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF080F26);
  static const Color textSecondary = Color(0xFF5A6480);
  static const Color textMuted = Color(0xFF9AA3BA);
  static const Color border = Color(0x17101D40);
  static const Color borderStrong = Color(0x29101D40);

  static const List<Color> appBackdrop = [Color(0xFF060D22), Color(0xFF142354), Color(0xFF1A2E6B)];
}

abstract final class VigilSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double page = 16;
}

abstract final class VigilRadius {
  static const double chip = 6;
  static const double input = 14;
  static const double card = 16;
  static const double feature = 20;
  static const double appFrame = 28;

  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(input));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius featureRadius = BorderRadius.all(Radius.circular(feature));
  static const BorderRadius appFrameRadius = BorderRadius.all(Radius.circular(appFrame));
}

abstract final class VigilStroke {
  static const BorderSide subtle = BorderSide(color: VigilColors.border, width: 1.5);
  static const BorderSide strong = BorderSide(color: VigilColors.borderStrong, width: 1.5);
  static const BorderSide primary = BorderSide(color: VigilColors.primary, width: 1.5);
}

abstract final class VigilShadow {
  static final List<BoxShadow> primaryLift = List.unmodifiable([
    BoxShadow(
      color: VigilColors.primary.withValues(alpha: 0.28),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ]);
}

abstract final class VigilGradients {
  static const LinearGradient appBackdrop = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: VigilColors.appBackdrop,
  );

  static const LinearGradient primaryAction = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [VigilColors.primary, VigilColors.primaryPressed],
  );
}

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
        contentPadding: const EdgeInsets.symmetric(horizontal: VigilSpace.lg, vertical: VigilSpace.md),
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

class VigilSurface extends StatelessWidget {
  const VigilSurface({
    required this.child,
    super.key,
    this.selected = false,
    this.padding,
    this.onTap,
    this.radius,
    this.background,
  });

  final Widget child;
  final bool selected;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BorderRadius? radius;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final BorderRadius resolvedRadius = radius ?? VigilRadius.cardRadius;
    final Color resolvedBackground =
        background ?? (selected ? VigilColors.primarySoft : VigilColors.surface);
    final BorderSide side = selected ? VigilStroke.primary : VigilStroke.subtle;
    final Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedBackground,
        border: Border.all(color: side.color, width: side.width),
        borderRadius: resolvedRadius,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    if (onTap == null) return content;
    return Material(
      color: resolvedBackground,
      borderRadius: resolvedRadius,
      child: InkWell(borderRadius: resolvedRadius, onTap: onTap, child: content),
    );
  }
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

class VigilPill extends StatelessWidget {
  const VigilPill({required this.label, required this.color, required this.background, super.key});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: VigilRadius.chipRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VigilSpace.xs, vertical: VigilSpace.xxs),
        child: Text(
          label,
          style: VigilType.small(color: color, size: 10, weight: FontWeight.w900),
        ),
      ),
    );
  }
}
