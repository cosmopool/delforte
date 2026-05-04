import "package:delforte/design_system/colors.dart";
import "package:flutter/material.dart";

abstract final class VigilShadow {
  static final List<BoxShadow> primaryLift = List.unmodifiable([
    BoxShadow(
      color: VigilColors.primary.withValues(alpha: 0.28),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ]);
}
