import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/utils/locale.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';

class LabeledLanguagePicker extends StatelessWidget {
  final String? language;
  final Function(String) onLanguageChanged;
  final bool singleLine;
  final bool isDiscrete;

  const LabeledLanguagePicker({
    super.key,
    this.language,
    this.singleLine = false,
    this.isDiscrete = false,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: singleLine ? 0 : 8,
      children: [
        singleLine
            ? SizedBox.shrink()
            : Text(
                AppLocalizations.of(context)!.language,
                style: textTheme.labelMedium,
              ),
        GestureDetector(
          onTap: showLanguageSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDiscrete
                    ? colorScheme.surfaceContainer
                    : colorScheme.shadow,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                singleLine
                    ? Text(
                        AppLocalizations.of(context)!.language,
                        style: textTheme.labelMedium,
                      )
                    : SizedBox.shrink(),
                Expanded(
                  child: Row(
                    mainAxisAlignment: singleLine
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.spaceBetween,
                    spacing: 8,
                    children: [
                      Text(
                        language?.isEmpty ?? true
                            ? AppLocalizations.of(context)!.languageHint
                            : language!,
                        style: textTheme.bodyLarge?.copyWith(
                          color: language?.isEmpty ?? true
                              ? colorScheme.shadow
                              : colorScheme.onSurface,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  VoidCallback showLanguageSheet(BuildContext context) {
    return () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          final languages = AppLocalizations.supportedLocales.map((locale) {
            return LocaleUtils.getLanguageName(locale, context);
          }).toList();

          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(0),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.chooseLanguage,
                      style: textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                // LANGUAGE OPTIONS
                Column(
                  spacing: 8,
                  children: [
                    ...languages.map((language) {
                      bool isSelected = language == this.language;

                      return FilledTextButton(
                        text: language,
                        isDark: isSelected,
                        trailingIcon: Icons.chevron_right,
                        onPressed: () {
                          onLanguageChanged(language);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),

                SizedBox(),
              ],
            ),
          );
        },
      );
    };
  }
}
