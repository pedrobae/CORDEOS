import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/printing_provider.dart';
import 'package:cordeos/utils/fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrintStyle extends StatefulWidget {
  const PrintStyle({super.key});

  @override
  State<PrintStyle> createState() => _PrintStyleState();
}

class _PrintStyleState extends State<PrintStyle> {
  late String lyricFontFamily;
  late double lyricFontSize;

  late String chordFontFamily;
  late double chordFontSize;

  late String headerFontFamily;
  late double headerFontSize;

  @override
  void initState() {
    final print = context.read<PrintingProvider>();

    lyricFontFamily = print.lyricFontFamily;
    lyricFontSize = print.lyricFontSize;
    chordFontFamily = print.chordFontFamily;
    chordFontSize = print.chordFontSize;
    headerFontFamily = print.headerFontFamily;
    headerFontSize = print.headerFontSize;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final print = context.read<PrintingProvider>();

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
                  AppLocalizations.of(context)!.contentFilters,
                  style: textTheme.titleMedium,
                ),
                Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            _buildOption(
              context,
              child: Row(
                children: [
                  Text(l10n.lyrics, style: textTheme.titleMedium),
                  Expanded(
                    child: DropdownButton<String>(
                      value: lyricFontFamily,
                      isExpanded: true,
                      items: [
                        for (final fontFamily in FontFamilies.values) ...[
                          DropdownMenuItem(
                            alignment: Alignment.centerRight,
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
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() {
                          lyricFontFamily = v;
                        });
                        await print.setLyricFontFamily(v);
                      },
                      underline: Container(),
                    ),
                  ),
                  const SizedBox(width: 32),
                  DropdownButton<double>(
                    value: lyricFontSize,
                    items: List.generate(12, (i) {
                      final double size = 10 + i * 2;
                      return DropdownMenuItem(
                        value: size,
                        child: Text(size.toString()),
                      );
                    }),
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() {
                        lyricFontSize = v;
                      });
                      await print.setLyricFontSize(v);
                    },
                    underline: Container(),
                  ),
                ],
              ),
            ),
            _buildOption(
              context,
              child: Row(
                children: [
                  Text(l10n.chords, style: textTheme.titleMedium),
                  Expanded(
                    child: DropdownButton<String>(
                      value: chordFontFamily,
                      isExpanded: true,
                      items: [
                        for (final fontFamily in FontFamilies.values) ...[
                          DropdownMenuItem(
                            alignment: Alignment.centerRight,
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
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() {
                          chordFontFamily = v;
                        });
                        await print.setChordFontFamily(v);
                      },
                      underline: Container(),
                    ),
                  ),
                  const SizedBox(width: 32),
                  DropdownButton<double>(
                    value: chordFontSize,
                    items: List.generate(12, (i) {
                      final double size = 10 + i * 2;
                      return DropdownMenuItem(
                        value: size,
                        child: Text(size.toString()),
                      );
                    }),
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() {
                        chordFontSize = v;
                      });
                      await print.setChordFontSize(v);
                    },
                    underline: Container(),
                  ),
                ],
              ),
            ),
            _buildOption(
              context,
              child: Row(
                children: [
                  Text(l10n.header, style: textTheme.titleMedium),
                  Expanded(
                    child: DropdownButton<String>(
                      value: headerFontFamily,
                      isExpanded: true,
                      items: [
                        for (final fontFamily in FontFamilies.values) ...[
                          DropdownMenuItem(
                            alignment: Alignment.centerRight,
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
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() {
                          headerFontFamily = v;
                        });
                        await print.setHeaderFontFamily(v);
                      },
                      underline: Container(),
                    ),
                  ),
                  const SizedBox(width: 32),
                  DropdownButton<double>(
                    value: headerFontSize,
                    items: List.generate(12, (i) {
                      final double size = 10 + i * 2;
                      return DropdownMenuItem(
                        value: size,
                        child: Text(size.toString()),
                      );
                    }),
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() {
                        headerFontSize = v;
                      });
                      await print.setHeaderFontSize(v);
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
