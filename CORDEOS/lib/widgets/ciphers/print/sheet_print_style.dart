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
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final print = context.read<PrintingProvider>();

    return Selector<PrintingProvider, ({String fontFamily, double fontSize})>(
      selector: (context, print) {
        return (fontFamily: print.fontFamily, fontSize: print.fontSize);
      },
      builder: (context, s, child) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Container(
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
                            onChanged: (v) async {
                              if (v == null) return;
                              await print.setFontFamily(v);
                            },
                            underline: Container(),
                          ),
                        ),
                        const SizedBox(width: 32),
                        DropdownButton<double>(
                          value: s.fontSize,
                          items: List.generate(10, (i) {
                            final double size = 6 + i * 2;
                            return DropdownMenuItem(
                              value: size,
                              child: Text(size.toString()),
                            );
                          }),
                          onChanged: (v) async {
                            if (v == null) return;
                            await print.setFontSize(v);
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
