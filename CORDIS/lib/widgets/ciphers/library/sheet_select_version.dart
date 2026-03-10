import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/view_cipher.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectVersionSheet extends StatelessWidget {
  final int cipherId;

  const SelectVersionSheet({super.key, required this.cipherId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();
    final ciph = context.read<CipherProvider>();
    final localVer = context.read<LocalVersionProvider>();

    final title = ciph.getCipher(cipherId)?.title;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.selectPlaceholder(AppLocalizations.of(context)!.version),
                    style: textTheme.titleMedium,
                  ),
                  if (title != null)
                    Text(title, style: textTheme.titleSmall)
                  else
                    Center(child: CircularProgressIndicator()),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          // VERSIONS
          ...localVer.getVersionsByCipherId(cipherId).map((versionID) {
            return Builder(
              builder: (context) {
                final version = localVer.cachedVersion(versionID);
                if (version == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return FilledTextButton(
                  text: version.versionName,
                  trailingIcon: Icons.chevron_right,
                  isDiscrete: true,
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the bottom sheet
                    nav.push(
                      () => ViewCipherScreen(
                        versionType: VersionType.local,
                        cipherID: cipherId,
                        versionID: versionID,
                      ),
                      showBottomNavBar: true,
                    );
                  },
                );
              },
            );
          }),
          SizedBox(),
        ],
      ),
    );
  }
}
