import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';

class DeleteConfirmationSheet extends StatelessWidget {
  final String itemType;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDangerous;

  const DeleteConfirmationSheet({
    super.key,
    required this.itemType,
    required this.onConfirm,
    this.onCancel,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        color: colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.deleteConfirmationTitle,
                  style: textTheme.titleLarge?.copyWith(
                    color: isDangerous ? Colors.red : colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: colorScheme.onSurface,
                    size: 32,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            // MESSAGE
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.deleteConfirmationMessage(itemType),
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  AppLocalizations.of(context)!.deleteWarningMessage,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            // ACTIONS
            // DELETE
            FilledTextButton(
              text: AppLocalizations.of(context)!.delete,
              isDark: true,
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
            ),
            // CANCEL
            FilledTextButton(
              text: AppLocalizations.of(context)!.cancel,
              onPressed: () {
                onCancel?.call();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
