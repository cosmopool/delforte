import "package:flutter/material.dart";

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
