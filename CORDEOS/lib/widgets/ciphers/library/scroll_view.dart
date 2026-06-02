import 'package:azlistview/azlistview.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/version/cloud_version_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/widgets/ciphers/library/card.dart';
import 'package:cordeos/widgets/ciphers/library/card_cloud.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Model for AzListView that holds cipher/cloud version data
class CipherListItem extends ISuspensionBean {
  final dynamic id; // int for local cipher, String for cloud version
  final String title;
  String tag = '';

  CipherListItem({required this.id, required this.title}) {
    // Extract first letter for alphabet grouping, handle special chars
    if (title.isEmpty) {
      tag = '#';
    } else {
      final firstChar = title[0].toUpperCase();
      tag = RegExp(r'[A-Z]').hasMatch(firstChar) ? firstChar : '#';
    }
  }

  @override
  String getSuspensionTag() => tag;
}

class CipherScrollView extends StatefulWidget {
  const CipherScrollView({super.key});

  @override
  State<CipherScrollView> createState() => _CipherScrollViewState();
}

class _CipherScrollViewState extends State<CipherScrollView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData({bool forceReload = false}) async {
    final cipherProvider = context.read<CipherProvider>();
    final cloudVersionProvider = context.read<CloudVersionProvider>();
    final localVersionProvider = context.read<LocalVersionProvider>();

    await cipherProvider.loadCiphers(forceReload: forceReload);
    await cloudVersionProvider.loadVersions(
      forceReload: forceReload,
      localCiphers: cipherProvider.ciphers.values.toList(),
    );

    for (var cipher in cipherProvider.ciphers.values) {
      await localVersionProvider.ensureCipherVersionsAreLoaded(
        cipher.id,
        forceReload: forceReload,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Selector3<
      CipherProvider,
      CloudVersionProvider,
      LocalVersionProvider,
      List<CipherListItem>
    >(
      selector: (context, ciph, cloudVer, localVer) {
        final filteredCipherIds = ciph.filteredCipherIds;
        final filteredCloudVersionIds = cloudVer.filteredCloudVersionIds;

        final filteredIds = {
          ...filteredCipherIds,
          ...filteredCloudVersionIds,
        }.entries.toList();

        // Create CipherListItem objects for AzListView
        final songIDs = filteredIds
            .map((entry) => CipherListItem(id: entry.key, title: entry.value))
            .toList();

        // Remove -1 (unsaved new song)
        songIDs.removeWhere((item) => item.id == -1);

        // Sort and set suspension status for AzListView
        SuspensionUtil.sortListBySuspensionTag(songIDs);
        SuspensionUtil.setShowSuspensionStatus(songIDs);

        return songIDs;
      },
      builder: (context, songs, child) {
        return RefreshIndicator(
          onRefresh: () async {
            _loadData(forceReload: true);
          },
          child: (songs.isEmpty)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 64),
                    Text(
                      l10n.emptyCipherLibrary,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : AzListView(
                  data: songs,
                  physics: const AlwaysScrollableScrollPhysics(),
                  indexBarData: SuspensionUtil.getTagIndexList(songs),
                  padding: const EdgeInsets.only(right: 38),
                  indexBarOptions: IndexBarOptions(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: colorScheme.surfaceContainerLowest,
                        ),
                        right: BorderSide(
                          color: colorScheme.surfaceContainerLowest,
                        ),
                        top: BorderSide(
                          color: colorScheme.surfaceContainerLowest,
                        ),
                      ),
                    ),
                    needRebuild: false,
                    indexHintAlignment: Alignment.centerRight,
                    indexHintOffset: const Offset(-20, 0),
                    textStyle: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final item = songs[index];
                    const itemPadding = EdgeInsets.only(bottom: 8.0);

                    if (item.id is String) {
                      return Padding(
                        padding: itemPadding,
                        child: CloudCipherCard(versionId: item.id),
                      );
                    }

                    if (item.id is! int) {
                      return Center(
                        child: Text(
                          '${l10n.error} (ID: ${item.id})',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      );
                    }

                    final versionID = context
                        .read<LocalVersionProvider>()
                        .getIdOfOldestVersionOfCipher(item.id);

                    if (versionID == null) {
                      return Center(
                        child: Text(
                          l10n.errorMessage(l10n.load, l10n.malformedData),
                          style: TextStyle(color: colorScheme.error),
                        ),
                      );
                    }

                    return Padding(
                      padding: itemPadding,
                      child: CipherCard(versionID: versionID),
                    );
                  },
                ),
        );
      },
    );
  }
}
