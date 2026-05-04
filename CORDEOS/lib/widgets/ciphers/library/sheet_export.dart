import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/screens/cipher/print_preview_screen.dart';
import 'package:cordeos/screens/cipher/text_export.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExportSheet extends StatelessWidget {
  final int versionID;

  const ExportSheet({super.key, required this.versionID});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.export,
                style: textTheme.titleMedium,
              ),
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          // OPTIONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<NavigationProvider>().push(
                    () => TextExportScreen(versionID: versionID),
                  );
                },
                child: Container(
                  color: Colors.transparent,
                  width: 40,
                  height: 40,
                  child: Icon(Icons.text_fields),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<NavigationProvider>().push(
                    () => PrintPreviewScreen(versionID: versionID),
                  );
                },
                child: Container(
                  color: Colors.transparent,
                  width: 40,
                  height: 40,
                  child: Icon(Icons.picture_as_pdf),
                ),
              ),
            ],
          ),

          SizedBox(),
        ],
      ),
    );
  }
}
