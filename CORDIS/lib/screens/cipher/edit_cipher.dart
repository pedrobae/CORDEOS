import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher/import_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/cipher/parser_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/services/key_recognizer_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/widgets/ciphers/editor/metadata_tab.dart';
import 'package:cordis/widgets/ciphers/editor/sections_tab.dart';

class EditCipherScreen extends StatefulWidget {
  final int cipherID;
  final int versionID;
  final VersionType versionType;
  final bool isEnabled;

  const EditCipherScreen({
    super.key,
    required this.cipherID,
    required this.versionID,
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
    switch (widget.versionType) {
      case VersionType.import:
        await _loadImportedCipher();
      case VersionType.local:
        await _loadLocalVersion();
      case VersionType.brandNew:
        _loadNewCipher();
      case VersionType.playlist:
        await _loadPlaylistVersion();
      case VersionType.cloud:
        throw Exception(
          'Cannot edit directly a cloud version. Please download to create a local copy.',
        );
    }
  }

  Future<void> _loadImportedCipher() async {
    final parse = context.read<ParserProvider>();
    final ciph = context.read<CipherProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final sect = context.read<SectionProvider>();

    final cipher = parse.parsedCipher;
    if (cipher == null) return;

    if (widget.cipherID == -1) {
      // CREATING NEW FROM IMPORTED
      ciph.setNewCipherInCache(cipher);
      final version = cipher.versions.first;
      localVer.setNewVersionInCache(version);
      sect.setNewSectionsInCache(-1, version.sections!);
    } else {
      // MERGING IMPORTED SECTIONS WITH EXISTING CIPHER
      final importedVersion = cipher.versions.first;
      final importedStruct = importedVersion.songStructure;
      final importedSections = importedVersion.sections!;

      final existingVersion = localVer.getVersion(widget.versionID)!;
      final existingStruct = existingVersion.songStructure;

      // FOR ANY CODE THAT OVERLAPS RENAME THE IMPORTED CODE
      for (String code in importedStruct) {
        String? newCode;

        final baseCode = code.toString().replaceAll(RegExp(r'\d+$'), '');
        if (existingStruct.contains(code)) {
          // Get new Code
          final matchingCodes = <String>[];
          for (String code in existingStruct) {
            // Strip numbering suffixes for comparison
            final strippedCode = code.toString().replaceAll(
              RegExp(r'\d+$'),
              '',
            );
            if (strippedCode == baseCode) {
              matchingCodes.add(code);
            }
          }
          newCode = '$baseCode${matchingCodes.length + 1}';
        }
        final newSect = importedSections[code]!.copyWith(
          contentCode: newCode ?? code,
          versionId: widget.versionID,
        );
        // Cache new section
        sect.cacheAddSection(
          widget.versionID,
          newSect.contentCode,
          newSect.contentColor,
          newSect.contentType,
        );
        sect.cacheContent(
          sectionCode: newSect.contentCode,
          versionID: widget.versionID,
          content: newSect.contentText,
        );
        // append to existing struct
        existingStruct.add(newSect.contentCode);
      }
      // Cache new struct
      localVer.cacheUpdates(widget.versionID, songStructure: existingStruct);
    }

    parse.clearCache();
    context.read<ImportProvider>().clearCache();
  }

  Future<void> _loadLocalVersion() async {
    final cipherProvider = context.read<CipherProvider>();
    final localVersionProvider = context.read<LocalVersionProvider>();
    final sectionProvider = context.read<SectionProvider>();

    await cipherProvider.loadCipher(widget.cipherID);
    await localVersionProvider.loadVersion(widget.versionID);
    await sectionProvider.loadSectionsOfVersion(widget.versionID);
  }

  void _loadNewCipher() {
    final ciph = context.read<CipherProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final sect = context.read<SectionProvider>();

    ciph.setNewCipherInCache(Cipher.empty());
    localVer.setNewVersionInCache(Version.empty());
    sect.setNewSectionsInCache(-1, {});
  }

  Future<void> _loadPlaylistVersion() async {
    final play = context.read<PlaylistProvider>();
    final ciph = context.read<CipherProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final sect = context.read<SectionProvider>();
    final sel = context.read<SelectionProvider>();

    final playlistName = AppLocalizations.of(
      context,
    )!.playlistVersionName(play.getPlaylist(sel.targetId!)!.name);

    await _loadPlaylistVersionFromLocal(playlistName, ciph, localVer, sect);
  }

  Future<void> _loadPlaylistVersionFromLocal(
    String playlistName,
    CipherProvider cipherProvider,
    LocalVersionProvider localVersionProvider,
    SectionProvider sectionProvider,
  ) async {
    final originalVersion = localVersionProvider.getVersion(widget.versionID)!;
    localVersionProvider.setNewVersionInCache(
      originalVersion.copyWith(firebaseID: '', versionName: playlistName),
    );

    await cipherProvider.loadCipher(widget.cipherID);
    await sectionProvider.loadSectionsOfVersion(widget.versionID);
    sectionProvider.cacheCopyOfVersion(widget.versionID);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context, listen: false);

    return Scaffold(
      appBar: _buildAppBar(nav),
      body: Column(spacing: 16, children: [_buildTabBar(), _buildTabContent()]),
    );
  }

  AppBar _buildAppBar(NavigationProvider nav) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final auth = context.read<MyAuthProvider>();

    return AppBar(
      leading: BackButton(onPressed: () => nav.attemptPop(context)),
      title: Text(
        AppLocalizations.of(
          context,
        )!.editPlaceholder(AppLocalizations.of(context)!.cipher),
        style: textTheme.titleMedium,
      ),
      actions: [
        if (auth.isAdmin)
          IconButton(
            onPressed: () async {
              await _publish();
              nav.pop();
            },
            icon: Icon(Icons.publish, color: colorScheme.onSurface),
          ),
        IconButton(
          onPressed: () async {
            await _save(context);
            nav.pop();
          },
          icon: Icon(Icons.save, color: colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(width: 1, color: colorScheme.surfaceContainerHigh),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
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
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          controller: _tabController,
          tabs: [
            _buildTabLabel(
              Icons.info_outline,
              AppLocalizations.of(context)!.info,
            ),
            _buildTabLabel(
              Icons.music_note,
              AppLocalizations.of(context)!.sections,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabLabel(IconData icon, String label) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 8,
        children: [
          Icon(icon),
          Text(label, style: textTheme.titleSmall),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [_buildMetadataTab(), _buildSectionsTab()],
      ),
    );
  }

  Widget _buildMetadataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: MetadataTab(
        cipherID: widget.cipherID,
        versionID: widget.versionID,
        versionType: widget.versionType,
        isEnabled: widget.isEnabled,
      ),
    );
  }

  Widget _buildSectionsTab() {
    return SectionsTab(
      versionID: widget.versionID,
      versionType: widget.versionType,
      isEnabled: widget.isEnabled,
    );
  }

  Future<void> _save(BuildContext context) async {
    final selectionProvider = context.read<SelectionProvider>();

    // Cache transposed key
    _cacheKey();

    if (selectionProvider.isSelectionMode) {
      await _saveVersionsToPlaylist(context);
    } else {
      await _saveSingleVersion(context);
    }

    // Clear unsaved changes flags
    if (context.mounted) _clearUnsavedChanges(context);
  }

  void _cacheKey() {
    final tp = context.read<TranspositionProvider>();
    final localVer = context.read<LocalVersionProvider>();

    if (widget.versionType == VersionType.import ||
        widget.versionType == VersionType.brandNew) {
    } else {
      localVer.cacheUpdates(widget.versionID, transposedKey: tp.transposedKey);
    }
  }

  Future<void> _saveVersionsToPlaylist(BuildContext context) async {
    final ciph = context.read<CipherProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final sect = context.read<SectionProvider>();
    final play = context.read<PlaylistProvider>();
    final nav = context.read<NavigationProvider>();
    final sel = context.read<SelectionProvider>();

    for (dynamic verID in sel.selectedItemIds) {
      int? versionId;
      if (verID.runtimeType == int) {
        // Version is local, create a copy for the playlist
        versionId = (await localVer.createVersion())!;
        play.addVersion(sel.targetId!, versionId);
      } else if (verID.runtimeType == String) {
        // Version is cloud, create a local copy and add to playlist
        int? localCipherID = widget.cipherID;
        if (widget.cipherID == -1) {
          localCipherID = await ciph.createCipher();
        } else {
          await ciph.saveCipher(widget.cipherID);
        }

        versionId = (await localVer.createVersion(cipherID: localCipherID))!;
      }

      await sect.createSections(versionId!);
      play.cacheAddVersion(sel.targetId!, versionId);
    }

    sel.clearSelection();
    nav.pop();
  }

  Future<void> _saveSingleVersion(BuildContext context) async {
    switch (widget.versionType) {
      case VersionType.import:
        await _saveImportedCipher(context);

      case VersionType.brandNew:
        await _saveBrandNewCipher(context);

      case VersionType.local:
        await _saveLocalCipher(context);

      case VersionType.playlist:
        await _savePlaylistVersion(context);

      case VersionType.cloud:
        throw Exception(
          'Cannot save directly a cloud version. Please download to create a local copy.',
        );
    }
  }

  Future<void> _saveImportedCipher(BuildContext context) async {
    final ciph = context.read<CipherProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final sect = context.read<SectionProvider>();
    final nav = context.read<NavigationProvider>();

    final recognizer = KeyRecognizerService();

    if (ciph.getCipher(-1)!.musicKey.isEmpty) {
      final sections = sect.getSections(-1);
      final key = await recognizer.recognizeKeyForNewCipher(sections.values.toList());
      ciph.cacheMusicKey(-1, key);
    }

    final cipherID = await ciph.createCipher();
    final versionID = await localVer.createVersion(
      cipherID: cipherID,
    );

    if (versionID == null) {
      throw Exception('Failed to create version for imported song');
    }

    await sect.createSections(versionID);
    nav.pop();
  }

  Future<void> _saveBrandNewCipher(BuildContext context) async {
    final cipherProvider = context.read<CipherProvider>();
    final localVersionProvider = context.read<LocalVersionProvider>();
    final sectionProvider = context.read<SectionProvider>();

    final cipherID = await cipherProvider.createCipher();
    final versionID = await localVersionProvider.createVersion(
      cipherID: cipherID,
    );

    if (versionID == null) {
      throw Exception('Failed to create version for new song');
    }

    await sectionProvider.createSections(versionID);
  }

  Future<void> _saveLocalCipher(BuildContext context) async {
    final cipherProvider = context.read<CipherProvider>();
    final localVersionProvider = context.read<LocalVersionProvider>();
    final sectionProvider = context.read<SectionProvider>();

    await cipherProvider.saveCipher(widget.cipherID);
    await localVersionProvider.saveVersion(widget.versionID);
    await sectionProvider.saveSections(versionID: widget.versionID);
  }

  Future<void> _savePlaylistVersion(BuildContext context) async {
    final localVersionProvider = context.read<LocalVersionProvider>();
    final sectionProvider = context.read<SectionProvider>();

    await localVersionProvider.saveVersion(widget.versionID);
    await sectionProvider.saveSections(versionID: widget.versionID);
  }

  void _clearUnsavedChanges(BuildContext context) {
    context.read<LocalVersionProvider>().clearUnsavedChanges();
    context.read<CipherProvider>().clearUnsavedChanges();
    context.read<SectionProvider>().clearUnsavedChanges();
  }

  Future<void> _publish() async {
    final localVer = context.read<LocalVersionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();
    final ciph = context.read<CipherProvider>();

    final version = localVer.getVersion(widget.versionID);
    if (version == null) return;

    final cipher = ciph.getCipher(widget.cipherID);
    if (cipher == null) return;

    await cloudVer.saveVersion(version.toDto(cipher));
  }
}
