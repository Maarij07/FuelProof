import 'package:flutter/material.dart';

/// Border radius values (Pinterest: elegant, minimal curves)
class AppBorderRadius {
  static const double card = 16;
  static const double button = 12;
  static const double input = 12;
  static const double pill = 99;
  static const double small = 8;
}

/// Component dimensions
class AppDimensions {
  static const double minTouchTarget = 48;
  static const double iconNavigationSize = 24;
  static const double iconCardSize = 20;
  static const double iconInlineSize = 16;
}

/// Animation durations
class AppDurations {
  static const Duration shortest = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration long = Duration(milliseconds: 500);
}

/// Soft shadow definitions (Pinterest aesthetic)
class AppShadows {
  // Subtle shadow for elevations
  static const BoxShadow subtle = BoxShadow(
    color: Color(0x0A000000), // 10% black opacity
    offset: Offset(0, 2),
    blurRadius: 4,
  );

  // Light shadow for hover states
  static const BoxShadow light = BoxShadow(
    color: Color(0x0F000000), // 15% black opacity
    offset: Offset(0, 4),
    blurRadius: 12,
  );

  // Medium shadow for cards
  static const BoxShadow card = BoxShadow(
    color: Color(0x0D000000), // 13% black opacity
    offset: Offset(0, 2),
    blurRadius: 8,
  );

  // Hover/focus shadow
  static const BoxShadow hover = BoxShadow(
    color: Color(0x12000000), // 18% black opacity
    offset: Offset(0, 8),
    blurRadius: 16,
  );

  static List<BoxShadow> get subtleList => [subtle];
  static List<BoxShadow> get lightList => [light];
  static List<BoxShadow> get cardList => [card];
  static List<BoxShadow> get hoverList => [hover];
}
