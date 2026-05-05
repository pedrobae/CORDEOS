import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/screens/cipher/print_preview_screen.dart';
import 'package:cordeos/screens/cipher/text_export.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExportSheet extends StatelessWidget {
  final int? versionID;
  final int? playlistID;

  ExportSheet({super.key, this.versionID, this.playlistID}) {
    assert((versionID != null || playlistID != null));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.export, style: textTheme.titleMedium),
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          // OPTIONS
          FilledTextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<NavigationProvider>().push(
                () => TextExportScreen(
                  versionID: versionID,
                  playlistID: playlistID,
                ),
              );
            },
            text: l10n.textExport,
            icon: Icons.text_fields,
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
          ),
          FilledTextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<NavigationProvider>().push(
                () => PrintPreviewScreen(
                  versionID: versionID,
                  playlistID: playlistID,
                ),
              );
            },
            text: l10n.pdfExport,
            icon: Icons.picture_as_pdf,
            isDiscrete: true,
            trailingIcon: Icons.chevron_right,
          ),
          SizedBox(),
        ],
      ),
    );
  }
}
