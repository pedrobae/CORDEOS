import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/widgets/ciphers/library/card.dart';
import 'package:cordis/widgets/ciphers/library/card_cloud.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CipherScrollView extends StatefulWidget {
  const CipherScrollView({super.key});

  @override
  State<CipherScrollView> createState() => _CipherScrollViewState();
}

class _CipherScrollViewState extends State<CipherScrollView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadData(context, isInitiating: true),
    );
  }

  void _loadData(
    BuildContext context, {
    bool forceReload = false,
    bool isInitiating = false,
  }) async {
    final cipherProvider = context.read<CipherProvider>();
    final cloudVersionProvider = context.read<CloudVersionProvider>();
    final localVersionProvider = context.read<LocalVersionProvider>();

    localVersionProvider.clearCache();
    await cipherProvider.loadCiphers(forceReload: forceReload);
    await cloudVersionProvider.loadVersions(
      forceReload: forceReload,
      localCiphers: cipherProvider.ciphers.values.toList(),
    );

    for (var cipher in cipherProvider.ciphers.values) {
      await localVersionProvider.loadVersionsOfCipher(cipher.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CipherProvider, CloudVersionProvider>(
      builder: (context, ciph, cloudVer, child) {
        // Handle loading state
        if (ciph.isLoading || cloudVer.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        // Handle error state
        if (ciph.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.errorMessage(
                    AppLocalizations.of(context)!.loading,
                    ciph.error!,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ciph.loadCiphers(forceReload: true),
                  child: Text(AppLocalizations.of(context)!.tryAgain),
                ),
              ],
            ),
          );
        }

        return _buildCiphersList(context, ciph, cloudVer);
      },
    );
  }

  Widget _buildCiphersList(
    BuildContext context,
    CipherProvider cipherProvider,
    CloudVersionProvider cloudVersionProvider,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadData(context, forceReload: true);
      },
      child: (cipherProvider.filteredCipherIds.isEmpty && cloudVersionProvider.filteredCloudVersionIds.isEmpty)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 64),
                Text(
                  AppLocalizations.of(context)!.emptyCipherLibrary,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : ListView.builder(
              cacheExtent: 500,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: (cipherProvider.filteredCipherIds.length + cloudVersionProvider.filteredCloudVersionIds.length),
              itemBuilder: (context, index) {
                if (index >= cipherProvider.filteredCipherIds.length) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 8.0,
                    ), // Spacing between cards
                    child: CloudCipherCard(
                      versionId: cloudVersionProvider.filteredCloudVersionIds[index - cipherProvider.filteredCipherIds.length],
                    ),
                  );
                }

                return CipherCard(
                  cipherId: cipherProvider.filteredCipherIds[index],
                );
              },
            ),
    );
  }
}
