import 'package:flutter/material.dart';

class AppColors {
  // New Brand Colors
  static const Color primary = Color(0xFF006C0C);
  static const Color primaryContainer = Color(0xFF1C871E);
  static const Color onPrimaryContainer = Color(0xFFF8FFF0);
  
  static const Color secondary = Color(0xFF904D00);
  static const Color secondaryContainer = Color(0xFFFD8B00);
  static const Color onSecondaryContainer = Color(0xFF603100);

  static const Color tertiaryContainer = Color(0xFF5A7A7A);
  static const Color onTertiaryContainer = Color(0xFFF3FFFE);

  static const Color background = Color(0xFFF9F9FC);
  static const Color surface = Color(0xFFF9F9FC);
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color onSurfaceVariant = Color(0xFF3F4A3B);

  static const Color outline = Color(0xFF6F7A6A);
  static const Color outlineVariant = Color(0xFFBECAB7);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Surface Containers
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3F6);
  static const Color surfaceContainer = Color(0xFFEEEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE8E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E5);

  // M3 Fixed Colors
  static const Color primaryFixed = Color(0xFF92FA83);
  static const Color primaryFixedDim = Color(0xFF77DD6A);
  static const Color onPrimaryFixed = Color(0xFF002201);
  static const Color onPrimaryFixedVariant = Color(0xFF005307);

  static const Color secondaryFixed = Color(0xFFFFDCC3);
  static const Color secondaryFixedDim = Color(0xFFFFB77D);
  static const Color onSecondaryFixed = Color(0xFF2F1500);
  static const Color onSecondaryFixedVariant = Color(0xFF6E3900);

  static const Color tertiaryFixed = Color(0xFFC6E9E9);
  static const Color tertiaryFixedDim = Color(0xFFABCDCD);
  static const Color onTertiaryFixed = Color(0xFF002020);
  static const Color onTertiaryFixedVariant = Color(0xFF2C4C4C);

  // Deprecated/Legacy compatibility mapping
  static const Color textBody = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color cardShadow = Color(0x0D000000);
  
  static const Color gray50 = surfaceContainerLow;
  static const Color gray100 = surfaceContainer;
  static const Color gray200 = surfaceContainerHigh;
  static const Color gray300 = surfaceContainerHighest;
  static const Color gray400 = outlineVariant;
  static const Color gray500 = outline;
}
