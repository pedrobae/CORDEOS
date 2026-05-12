import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/providers/cipher/edit_sections_state_provider.dart';
import 'package:cordeos/providers/cipher/import_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/cipher/parser_provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/version/cloud_version_provider.dart';
import 'package:cordeos/services/key_recognizer_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/widgets/ciphers/editor/metadata_tab.dart';
import 'package:cordeos/widgets/ciphers/editor/sections_tab.dart';

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
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditSectionsStateProvider>().resetState();
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

    final versionDto = parse.parsedSong;
    if (versionDto == null) return;

    if (widget.cipherID == -1) {
      // CREATING NEW FROM IMPORTED
      ciph.setNewCipherInCache(Cipher.fromVersionDto(versionDto));

      localVer.setNewVersionInCache(versionDto.toDomain());
      sect.setNewSectionsInCache(
        -1,
        versionDto.sections.map(
          (key, value) => MapEntry(key, value.toDomain()),
        ),
      );
    } else {
      // MERGING IMPORTED SECTIONS WITH EXISTING CIPHER
      final importedVersion = versionDto;
      final importedSections = importedVersion.sections.map(
        (key, value) => MapEntry(key, value.toDomain()),
      );
      for (final section in importedSections.values) {
        final newKey = sect.cacheAddSection(widget.versionID, section);
        localVer.addSectionToStruct(widget.versionID, newKey);
      }
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
    final ciph = context.read<CipherProvider>();
    final sect = context.read<SectionProvider>();

    await ciph.loadCipher(widget.cipherID);
    await sect.loadSectionsOfVersion(widget.versionID);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context, listen: false);

    return Column(
      children: [
        _buildAppBar(nav),
        Expanded(
          child: Column(
            spacing: 16,
            children: [_buildTabBar(), _buildTabContent()],
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar(NavigationProvider nav) {
    final textTheme = Theme.of(context).textTheme;

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
            icon: Icon(Icons.publish, size: 30),
          ),
        IconButton(
          onPressed: () async {
            await _save(context);
            nav.pop();
          },
          icon: Icon(Icons.save, size: 30),
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
    await _saveSingleVersion(context);
  }

  Future<void> _saveSingleVersion(BuildContext context) async {
    if (widget.versionType == VersionType.cloud) {
      throw Exception(
        'Cannot save directly a cloud version. Something went wrong.',
      );
    }

    final ciph = context.read<CipherProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final sect = context.read<SectionProvider>();
    final nav = context.read<NavigationProvider>();

    final cipher = ciph.getCipher(widget.cipherID);
    if (cipher == null || cipher.musicKey.isEmpty) {
      final recognizer = KeyRecognizerService();

      final sections = sect.getSections(widget.versionID);
      final key = recognizer.recognizeKeyForNewCipher(sections.values.toList());
      ciph.cacheMusicKey(widget.cipherID, key);
    }

    if (widget.versionType == VersionType.import ||
        widget.versionType == VersionType.brandNew) {
      final cipherID = await ciph.createCipher();
      final versionID = await localVer.createVersion(cipherID: cipherID);
      await sect.createSections(versionID);
    } else {
      if (widget.versionType == VersionType.local) {
        await ciph.saveCipher(widget.cipherID);
      }
      await localVer.saveVersion(versionID: widget.versionID);
      await sect.saveSections(versionID: widget.versionID);
    }

    if (widget.versionType == VersionType.import) {
      nav.pop();
    }
  }

  Future<void> _publish() async {
    final localVer = context.read<LocalVersionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();
    final sect = context.read<SectionProvider>();
    final ciph = context.read<CipherProvider>();

    final version = localVer.getVersion(widget.versionID);
    if (version == null) return;
    final cipher = ciph.getCipher(widget.cipherID);
    if (cipher == null) return;
    final sections = sect.getSections(widget.versionID);
    final versionDTO = version.toDto(cipher, sections);

    final firebaseID = await cloudVer.saveVersion(versionDTO);
    if (firebaseID != null && firebaseID.isEmpty) {
      localVer.updateVersion(version.copyWith(firebaseID: firebaseID));
    }
  }
}
