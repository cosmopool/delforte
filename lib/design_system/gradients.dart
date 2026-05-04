import "package:delforte/design_system/colors.dart";
import "package:flutter/material.dart";

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
