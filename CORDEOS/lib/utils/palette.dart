import 'package:flutter/material.dart';

class Palette {
  // Five color palette
  // PALETTE
  static const Color _green = Color(0xFF145550); // Green
  static const Color _orange = Color(0xFFE66423); // Orange
  static const Color _gold = Color(0xFFE6B428); // Gold
  static const Color _burgundy = Color(0xFF5A002D); // Burgundy
  static const Color _neutral = Color(0xFFE1E1E6); // Neutral
  static const Color _darkNeutral = Color(0xFF121214); // Dark Neutral

  /// Lighten a color by [amount] (0.0 to 1.0)
  static Color lighten(Color color, [double amount = .08]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  /// Darken a color by [amount] (0.0 to 1.0)
  static Color darken(Color color, [double amount = .08]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

class BrandPalette extends Palette {
  static Color white = Palette._neutral;
  static Color black = Palette._darkNeutral;

  // ===== PRECOMPUTED COLORS ======
  // GREEN THEME
  // PRIMARIES (Green)
  static Color green = Palette._green;
  static Color greenTint = const Color.fromARGB(255, 129, 167, 163);

  // =============================================================================
  // ORANGE THEME
  // PRIMARIES (Orange)
  static Color orange = Palette._orange;
  static Color orangeTint = const Color.fromARGB(255, 110, 43, 9);

  // =============================================================================
  // GOLD THEME
  // PRIMARIES (Gold)
  static Color gold = Palette._gold;
  static Color goldTint = const Color.fromARGB(255, 155, 115, 6);

  // =============================================================================
  //  BURGUNDY THEME
  //  PRIMARIES (burgundy)
  static Color burgundy = Palette._burgundy;
  static Color burgundyTint = const Color.fromARGB(255, 190, 150, 170);
}

class NeutralPalette extends Palette {
  // Neutral colors for surfaces using final with calculations
  static Color surface1Light = Palette.darken(Palette._neutral, 0.25);
  static Color surface2Light = Palette.darken(Palette._neutral, 0.2);
  static Color surface3Light = Palette.darken(Palette._neutral, 0.15);
  static Color surface4Light = Palette.darken(Palette._neutral, 0.1);
  static Color surface5Light = Palette.darken(Palette._neutral, 0.05);
  static Color surfaceLight = Palette._neutral;

  static Color surface1Dark = Palette.lighten(Palette._darkNeutral, 0.25);
  static Color surface2Dark = Palette.lighten(Palette._darkNeutral, 0.2);
  static Color surface3Dark = Palette.lighten(Palette._darkNeutral, 0.15);
  static Color surface4Dark = Palette.lighten(Palette._darkNeutral, 0.1);
  static Color surface5Dark = Palette.lighten(Palette._darkNeutral, 0.05);
  static Color surfaceDark = Palette._darkNeutral;

  // Neutral elements using final with calculations
  static Color outlineLight = Palette.darken(
    Palette._neutral,
    0.5,
  ); // Light outline
  static Color outlineDark = Palette.lighten(
    Palette._darkNeutral,
    0.5,
  ); // Dark outline

  static const Color shadowLight = Color.fromARGB(127, 0, 0, 0); // Light shadow
  static const Color shadowDark = Color.fromARGB(
    127,
    168,
    168,
    168,
  ); // Dark shadow
  static const Color scrimLight = Color(0x0D000000); // Light scrim (5% opacity)
  static const Color scrimDark = Color(0x1A000000); // Dark scrim (10% opacity)

  static const Color error = Colors.red; // Standard error red
  static const Color onError = Color(0xFFFFFFFF); // White text for contrast
}
