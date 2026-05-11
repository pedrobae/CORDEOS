import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/utils/fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StyleSettings extends StatefulWidget {
  const StyleSettings({super.key});

  @override
  State<StyleSettings> createState() => _StyleSettingsState();
}

class _StyleSettingsState extends State<StyleSettings> {
  double? _cardsOnScreen;
  double? _screenWidth;
  late double _heightSpacing;

  @override
  void initState() {
    super.initState();

    final set = context.read<LayoutSetProvider>();

    _heightSpacing = set.heightSpacingMult.clamp(-0.1, 0.25);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _screenWidth = MediaQuery.sizeOf(context).width;
        _cardsOnScreen = _calcCardsOnScreen(set.cardWidthMult, _screenWidth!);
      });
    });
  }

  /// Width mult is a value from 0.2 to 1 that determines the width of the cards.
  /// The number of cards on screen is calculated from this value, with 1 being 1 cards on screen and 0.2 being 5 cards on screen.
  double _calcCardsOnScreen(double widthMult, double screenWidth) {
    final cardWidth = screenWidth * widthMult;
    final cardsOnScreen = ((screenWidth - 8) / (cardWidth + 8));
    return cardsOnScreen;
  }

  double _calcWidthMult(double cardsOnScreen, double screenWidth) {
    final totalSpacing = 8 * (cardsOnScreen + 1);
    final availableWidth = screenWidth - totalSpacing;
    final cardWidth = availableWidth / cardsOnScreen;
    return cardWidth / screenWidth;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final set = context.read<LayoutSetProvider>();

    return Selector<
      LayoutSetProvider,
      ({
        double cardsOnScreen,
        Axis scrollDirection,
        bool showSectionHeaders,
        String fontFamily,
        double fontSize,
      })
    >(
      selector: (context, set) {
        return (
          cardsOnScreen: _calcCardsOnScreen(
            set.cardWidthMult,
            MediaQuery.sizeOf(context).width,
          ),
          scrollDirection: set.scrollDirection,
          showSectionHeaders: set.showSectionHeaders,
          fontFamily: set.fontFamily,
          fontSize: set.fontSize,
        );
      },
      builder: (context, s, child) {
        return Container(
          color: colorScheme.surface,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                // HEADER
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.styleSettings,
                      style: textTheme.titleMedium,
                    ),
                    Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                // SCROLL DIRECTION SETTINGS
                _buildOption(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.scrollDirection,
                          style: textTheme.labelLarge,
                        ),
                      ),
                      Switch(
                        value: s.scrollDirection == Axis.vertical,
                        onChanged: (_) {
                          set.toggleAxisDirection();
                        },
                        thumbIcon: WidgetStatePropertyAll(
                          s.scrollDirection == Axis.vertical
                              ? const Icon(Icons.swap_vert)
                              : const Icon(Icons.swap_horiz),
                        ),
                        thumbColor: WidgetStatePropertyAll(colorScheme.primary),
                        trackColor: WidgetStatePropertyAll(
                          colorScheme.surfaceContainerHigh,
                        ),
                        trackOutlineColor: WidgetStatePropertyAll(
                          colorScheme.surfaceTint,
                        ),
                      ),
                    ],
                  ),
                ),

                /// COMPACT VIEW
                _buildOption(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.compactView,
                          style: textTheme.labelLarge,
                        ),
                      ),
                      Switch(
                        value: !s.showSectionHeaders,
                        onChanged: (_) => set.toggleSectionHeaders(),
                        thumbColor: WidgetStatePropertyAll(colorScheme.primary),
                        trackColor: WidgetStatePropertyAll(
                          colorScheme.surfaceContainerHigh,
                        ),
                        trackOutlineColor: WidgetStatePropertyAll(
                          colorScheme.surfaceTint,
                        ),
                      ),
                    ],
                  ),
                ),

                // CARD WIDTH SETTINGS
                _buildOption(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.cardWidth,
                          style: textTheme.labelLarge,
                        ),
                      ),
                      Text(
                        (_cardsOnScreen ?? 0).toStringAsFixed(2),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: Slider(
                          value: ((6 - (_cardsOnScreen ?? 0)) / 5).clamp(
                            0.2,
                            1.0,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 16,
                          ),
                          divisions: 80,
                          min: 0.2,
                          max: 1.0,
                          onChanged: (v) {
                            setState(() => _cardsOnScreen = 6 - v * 5);
                          },
                          onChangeEnd: (v) {
                            set.setCardWidthMult(
                              _calcWidthMult(
                                _cardsOnScreen!,
                                _screenWidth ?? 0,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Height spacing
                _buildOption(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.heightSpacing,
                          style: textTheme.labelLarge,
                        ),
                      ),
                      Text(
                        (_heightSpacing * 10).toStringAsFixed(1),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: Slider(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 16,
                          ),
                          value: _heightSpacing,
                          divisions: 75,
                          min: -0.1,
                          max: 0.25,
                          onChanged: (v) {
                            setState(() => _heightSpacing = v);
                          },
                          onChangeEnd: (v) {
                            set.setHeightSpacingMult(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // FONT SETTINGS
                _buildOption(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: s.fontFamily,
                          isExpanded: true,
                          items: [
                            for (final fontFamily in FontFamilies.values) ...[
                              DropdownMenuItem(
                                value: fontFamily.key,
                                child: Text(
                                  fontFamily.key,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontFamily: fontFamily.key,
                                  ),
                                ),
                              ),
                            ],
                          ],
                          onChanged: (v) {
                            if (v != null) set.setFontFamily(v);
                          },
                          underline: Container(),
                        ),
                      ),
                      const SizedBox(width: 32),
                      DropdownButton<double>(
                        value: s.fontSize,
                        items: List.generate(12, (i) {
                          final double size = 12 + i * 2;
                          return DropdownMenuItem(
                            value: size,
                            child: Text(size.toString()),
                          );
                        }),
                        onChanged: (v) {
                          if (v != null) set.setFontSize(v);
                        },
                        underline: Container(),
                      ),
                    ],
                  ),
                ),

                SizedBox(),
              ],
            ),
          ),
        );
      },
    );
  }

  Container _buildOption(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: colorScheme.surfaceContainerLowest, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }
}
