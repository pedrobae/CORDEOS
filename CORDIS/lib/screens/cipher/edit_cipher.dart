import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/providers/cipher/import_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/cipher/parser_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/widgets/ciphers/editor/metadata_tab.dart';
import 'package:cordis/widgets/ciphers/editor/sections_tab.dart';

class EditCipherScreen extends StatefulWidget {
  final int? cipherID; // Null for new cipher
  final dynamic versionID; // Null for new version // could be int or String
  final int? playlistID;
  final VersionType versionType;
  final bool isEnabled;

  const EditCipherScreen({
    super.key,
    this.cipherID,
    this.versionID,
    this.playlistID,
    required this.versionType,
    this.isEnabled = true,
  });

  @override
  State<EditCipherScreen> createState() => _EditCipherScreenState();
}

class _EditCipherScreenState extends State<EditCipherScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final cipherProvider = context.read<CipherProvider>();
    final localVersionProvider = context.read<LocalVersionProvider>();
    final cloudVersionProvider = context.read<CloudVersionProvider>();
    final sectionProvider = context.read<SectionProvider>();

    switch (widget.versionType) {
      case VersionType.import:
        final parserProvider = context.read<ParserProvider>();

        // Load imported cipher data
        final cipher = parserProvider.parsedCipher;

        if (cipher == null) {
          break;
        }
        cipherProvider.setNewCipherInCache(cipher);
        // Load imported version data
        final version = cipher.versions.first;
        localVersionProvider.setNewVersionInCache(version);
        // Load sections
        sectionProvider.setNewSectionsInCache(
          -1,
          version.sections!,
        ); // -1 for new/imported versions

        // CLEAR PARSE AND IMPORT PROVIDERS
        parserProvider.clearCache();
        context.read<ImportProvider>().clearCache();
        break;
      case VersionType.cloud:
        // Ensure cloud version
        await cloudVersionProvider.ensureVersionIsLoaded(widget.versionID!);
        // Load sections
        final version = cloudVersionProvider
            .getVersion(widget.versionID!)!
            .toDomain();
        sectionProvider.setNewSectionsInCache(
          widget.versionID!,
          version.sections!,
        );
        break;
      case VersionType.local:
        // Load the cipher
        await cipherProvider.loadCipher(widget.cipherID!);
        // Load the version
        await localVersionProvider.loadVersion(widget.versionID!);
        // Load sections
        await sectionProvider.loadSectionsOfVersion(widget.versionID!);
        break;
      case VersionType.brandNew:
        cipherProvider.setNewCipherInCache(Cipher.empty());
        localVersionProvider.setNewVersionInCache(Version.empty());
        break;
      case VersionType.playlist:
        final playlistProvider = context.read<PlaylistProvider>();

        final String playlistName = AppLocalizations.of(context)!
            .playlistVersionName(
              playlistProvider.getPlaylistById(widget.playlistID!)!.name,
            );

        // Create a new copy of the version for editing
        // Load the version
        if (widget.versionID is int) {
          final Version originalVersion = localVersionProvider.cachedVersion(
            widget.versionID!,
          )!;
          // Create a copy of the version in cache
          localVersionProvider.setNewVersionInCache(
            originalVersion.copyWith(firebaseId: '', versionName: playlistName),
          );

          // Load the cipher
          await cipherProvider.loadCipher(widget.cipherID!);

          // Load the sections in cache
          await sectionProvider.loadSectionsOfVersion(widget.versionID!);
          sectionProvider.cacheSectionCopy(widget.versionID!);
        } else {
          final VersionDto originalVersion = cloudVersionProvider.getVersion(
            widget.versionID!,
          )!;

          // Check if there exists a local cipher with the same title / author
          final localCipherID = cipherProvider.getCipherIdByTitleOrAuthor(
            originalVersion.title,
            originalVersion.author,
          );

          if (localCipherID != -1 && localCipherID != null) {
            await cipherProvider.loadCipher(localCipherID);
          } else {
            cipherProvider.setNewCipherInCache(
              Cipher.fromVersionDto(originalVersion),
            );
          }
          String? newName;
          if (mounted) {
            newName = AppLocalizations.of(
              context,
            )!.playlistVersionName(playlistName);
          }

          final newVersion = originalVersion
              .toDomain(cipherId: localCipherID)
              .copyWith(versionName: newName);

          // Create a copy of the version in cache
          localVersionProvider.setNewVersionInCache(newVersion);

          sectionProvider.setNewSectionsInCache(-1, newVersion.sections!);
        }
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer6<
      CipherProvider,
      LocalVersionProvider,
      SectionProvider,
      SelectionProvider,
      NavigationProvider,
      PlaylistProvider
    >(
      builder:
          (
            context,
            cipherProvider,
            versionProvider,
            sectionProvider,
            selectionProvider,
            navigationProvider,
            playlistProvider,
            child,
          ) {
            return Scaffold(
              appBar: AppBar(
                leading: BackButton(
                  onPressed: () => navigationProvider.attemptPop(context),
                ),
                title: Text(
                  AppLocalizations.of(
                    context,
                  )!.editPlaceholder(AppLocalizations.of(context)!.cipher),
                  style: textTheme.titleMedium,
                ),
                actions: [
                  IconButton(
                    onPressed: () async {
                      await _save(
                        selectionProvider,
                        versionProvider,
                        cipherProvider,
                        sectionProvider,
                        playlistProvider,
                        navigationProvider,
                      );
                      navigationProvider.pop();
                    },
                    icon: Icon(Icons.save, color: colorScheme.onSurface),
                  ),
                ],
              ),
              body: Column(
                spacing: 16,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          width: 1,
                          color: colorScheme.surfaceContainerHigh,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(4),
                        ),
                      ),
                      child: TabBar(
                        labelPadding: const EdgeInsets.all(0),
                        dividerHeight: 0,
                        labelColor: colorScheme.onSurface,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicator: BoxDecoration(
                          color: colorScheme.surface,
                          border: Border.all(
                            width: 0.5,
                            color: colorScheme.surfaceContainerHigh,
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                        ),
                        controller: _tabController,
                        tabs: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              spacing: 8,
                              children: [
                                const Icon(Icons.info_outline),
                                Text(
                                  AppLocalizations.of(context)!.info,
                                  style: textTheme.titleSmall,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              spacing: 8,
                              children: [
                                const Icon(Icons.music_note),
                                Text(
                                  AppLocalizations.of(context)!.sections,
                                  style: textTheme.titleSmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Basic Info Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Basic cipher info
                              MetadataTab(
                                cipherID: widget.cipherID,
                                versionID: widget.versionID,
                                versionType: widget.versionType,
                                isEnabled: widget.isEnabled,
                              ),
                            ],
                          ),
                        ),
                        // Content Tab
                        SectionsTab(
                          versionID: widget.versionType == VersionType.playlist
                              ? -1
                              : widget.versionID,
                          versionType: widget.versionType,
                          isEnabled: widget.isEnabled,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  Future<void> _save(
    SelectionProvider selectionProvider,
    LocalVersionProvider versionProvider,
    CipherProvider cipherProvider,
    SectionProvider sectionProvider,
    PlaylistProvider playlistProvider,
    NavigationProvider navigationProvider,
  ) async {
    // Cache the transposed key to the version
    final key = context.read<TranspositionProvider>().transposedKey;
    if (widget.versionID is int) {
      versionProvider.cacheUpdates(widget.versionID!, transposedKey: key);
    } else if (widget.versionID is String) {
      context.read<CloudVersionProvider>().cacheUpdates(
        widget.versionID!,
        transposedKey: key,
      );
    }
    if (selectionProvider.isSelectionMode) {
      for (dynamic versionId in selectionProvider.selectedItemIds) {
        if (versionId.runtimeType == int) {
          // LOCAL VERSION: Create a copy of the version in the database
          versionId = await versionProvider.createVersion();
          playlistProvider.addVersion(selectionProvider.targetId!, versionId);
        } else if (versionId.runtimeType == String) {
          // CLOUD VERSION: Upsert the version in the database
          int? localCipherID = widget.cipherID;
          if (widget.cipherID == null) {
            localCipherID = await cipherProvider.createCipher();
          } else {
            await cipherProvider.saveCipher(widget.cipherID!);
          }

          versionId = await versionProvider.createVersion(
            cipherID: localCipherID,
          );
        }
        // Create Section entries for the new version
        await sectionProvider.createSections(versionId);
        await sectionProvider.loadSectionsOfVersion(versionId);
        playlistProvider.cacheAddVersion(
          selectionProvider.targetId!,
          versionId,
        );
      }
      selectionProvider.clearSelection();
      navigationProvider.pop(); // Close editor
    } else {
      switch (widget.versionType) {
        case VersionType.playlist:
          await versionProvider.saveVersion(widget.versionID);
          await sectionProvider.saveSections(versionID: widget.versionID);
          break;

        case VersionType.brandNew:
          final cipherID = await cipherProvider.createCipher();
          final versionID = await versionProvider.createVersion(
            cipherID: cipherID,
          );
          if (versionID == null) {
            throw Exception('Failed to create version for new song');
          }
          await sectionProvider.createSections(versionID);
        case VersionType.import:
          final cipherID = await cipherProvider.createCipher();
          final versionID = await versionProvider.createVersion(
            cipherID: cipherID,
          );
          if (versionID == null) {
            throw Exception('Failed to create version for imported song');
          }
          await sectionProvider.createSections(versionID);
          navigationProvider.pop();
          break;
        case VersionType.cloud:
          throw Exception(
            'Cannot save directly a cloud version. Please download to create a local copy of this version.',
          );

        case VersionType.local:
          await cipherProvider.saveCipher(widget.cipherID!);
          await versionProvider.saveVersion(widget.versionID);
          await sectionProvider.saveSections(versionID: widget.versionID);
          break;
      }
    }
  }
}
