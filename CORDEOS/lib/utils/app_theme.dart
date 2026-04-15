import 'package:flutter/material.dart';
import 'package:cordeos/utils/palette.dart';

enum ThemeColor { green, gold, orange, burgundy }

class AppTheme {
  static final ColorScheme _greenLightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: BrandPalette.green,
    onPrimary: BrandPalette.white,
    secondary: BrandPalette.burgundy,
    onSecondary: BrandPalette.white,
    error: NeutralPalette.error,
    onError: NeutralPalette.onError,
    surface: NeutralPalette.surfaceLight,
    surfaceContainerHighest: NeutralPalette.surface5Light,
    surfaceContainerHigh: NeutralPalette.surface4Light,
    surfaceContainer: NeutralPalette.surface3Light,
    surfaceContainerLow: NeutralPalette.surface2Light,
    surfaceContainerLowest: NeutralPalette.surface1Light,
    surfaceTint: BrandPalette.greenTint,
    onSurface: BrandPalette.black,
    outline: NeutralPalette.outlineLight,
    shadow: NeutralPalette.shadowLight,
    scrim: NeutralPalette.scrimLight,
    inverseSurface: NeutralPalette.surface5Dark,
    onInverseSurface: NeutralPalette.surface1Light,
  );

  static final ColorScheme _orangeDarkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: BrandPalette.orange,
    onPrimary: BrandPalette.black,
    secondary: BrandPalette.gold,
    onSecondary: BrandPalette.black,
    error: NeutralPalette.error,
    onError: NeutralPalette.onError,
    surface: NeutralPalette.surfaceDark,
    surfaceContainerHighest: NeutralPalette.surface5Dark,
    surfaceContainerHigh: NeutralPalette.surface4Dark,
    surfaceContainer: NeutralPalette.surface3Dark,
    surfaceContainerLow: NeutralPalette.surface2Dark,
    surfaceContainerLowest: NeutralPalette.surface1Dark,
    surfaceTint: BrandPalette.orangeTint,
    onSurface: Colors.white,
    outline: NeutralPalette.outlineDark,
    shadow: NeutralPalette.shadowDark,
    scrim: NeutralPalette.scrimDark,
    inverseSurface: NeutralPalette.surface5Light,
    onInverseSurface: NeutralPalette.surface1Dark,
  );

  static final ColorScheme _goldDarkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: BrandPalette.gold,
    onPrimary: BrandPalette.black,
    secondary: BrandPalette.orange,
    onSecondary: BrandPalette.black,
    error: NeutralPalette.error,
    onError: NeutralPalette.onError,
    surface: NeutralPalette.surfaceDark,
    surfaceContainerHighest: NeutralPalette.surface5Dark,
    surfaceContainerHigh: NeutralPalette.surface4Dark,
    surfaceContainer: NeutralPalette.surface3Dark,
    surfaceContainerLow: NeutralPalette.surface2Dark,
    surfaceContainerLowest: NeutralPalette.surface1Dark,
    surfaceTint: BrandPalette.goldTint,
    onSurface: Colors.white,
    outline: NeutralPalette.outlineDark,
    shadow: NeutralPalette.shadowDark,
    scrim: NeutralPalette.scrimDark,
    inverseSurface: NeutralPalette.surface5Light,
    onInverseSurface: NeutralPalette.surface1Dark,
  );
  static final ColorScheme _burgundyLightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: BrandPalette.burgundy,
    onPrimary: BrandPalette.white,
    secondary: BrandPalette.green,
    onSecondary: BrandPalette.white,
    error: NeutralPalette.error,
    onError: NeutralPalette.onError,
    surface: NeutralPalette.surfaceLight,
    surfaceContainerHighest: NeutralPalette.surface5Light,
    surfaceContainerHigh: NeutralPalette.surface4Light,
    surfaceContainer: NeutralPalette.surface3Light,
    surfaceContainerLow: NeutralPalette.surface2Light,
    surfaceContainerLowest: NeutralPalette.surface1Light,
    surfaceTint: BrandPalette.burgundyTint,
    onSurface: Colors.black,
    outline: NeutralPalette.outlineLight,
    shadow: NeutralPalette.shadowLight,
    scrim: NeutralPalette.scrimLight,
    inverseSurface: NeutralPalette.surface5Dark,
    onInverseSurface: NeutralPalette.surface1Light,
  );

  static ThemeData getTheme(bool isVariation, bool isDark) {
    // Get pre-calculated color schemes for optimization
    final colorScheme = _getColorScheme(isVariation, isDark);
    return _buildTheme(colorScheme, _textTheme, isDark);
  }

  static ColorScheme _getColorScheme(bool isVariation, bool isDark) {
    if (isDark) {
      return isVariation ? _orangeDarkColorScheme : _goldDarkColorScheme;
    } else {
      return isVariation ? _burgundyLightColorScheme : _greenLightColorScheme;
    }
  }

  static final TextTheme _textTheme = TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
  );

  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'FormaDJRMicro',
      textTheme: textTheme,
      shadowColor: isDark
          ? NeutralPalette.shadowDark
          : NeutralPalette.shadowLight,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 3 : 1,
        shadowColor: isDark
            ? NeutralPalette.shadowDark
            : NeutralPalette.shadowLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: colorScheme.onSurface, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: .38);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: .12);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: .12);
          }
          if (states.contains(WidgetState.selected)) {
            return isDark
                ? colorScheme.onPrimary.withValues(alpha: 0.80)
                : colorScheme.primary.withValues(alpha: 0.35);
          }
          return isDark
              ? colorScheme.onPrimary.withValues(alpha: 0.62)
              : colorScheme.onPrimary.withValues(alpha: 0.38);
        }),
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary.withValues(alpha: 0.12);
            }
            return colorScheme.onSurface.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            return colorScheme.onSurface.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary.withValues(alpha: 0.12);
            }
            return colorScheme.onSurface.withValues(alpha: 0.12);
          }
          return Colors.transparent;
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: isDark ? 3 : 1,
          shadowColor: isDark
              ? NeutralPalette.shadowDark
              : NeutralPalette.shadowLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: colorScheme.outline),
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.secondaryContainer,
        checkmarkColor: colorScheme.onSecondaryContainer,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: colorScheme.primaryContainer,
        valueIndicatorTextStyle: TextStyle(
          color: colorScheme.onPrimaryContainer,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurface.withValues(alpha: 0.62);
        }),
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: isDark ? 6 : 6,
        highlightElevation: isDark ? 12 : 12,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
