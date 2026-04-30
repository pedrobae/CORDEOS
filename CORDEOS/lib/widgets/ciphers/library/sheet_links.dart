import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LinksSheet extends StatelessWidget {
  final List<String> links;

  const LinksSheet({super.key, required this.links});

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
                AppLocalizations.of(context)!.openLink,
                style: textTheme.titleMedium,
              ),
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          // VERSIONS
          for (final link in links) ...[_buildLinkOption(context, link)],
          SizedBox(),
        ],
      ),
    );
  }

  Widget _buildLinkOption(BuildContext context, String link) {
    return FilledTextButton(
      text: link,
      trailingIcon: Icons.chevron_right,
      isDiscrete: true,
      onPressed: () async {
        await context.read<NavigationProvider>().launchURL(link);
      },
    );
  }
}
