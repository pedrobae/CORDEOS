import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/widgets/ciphers/transposer.dart';
import 'package:cordis/widgets/ciphers/viewer/structure_list.dart';
import 'package:cordis/widgets/schedule/play/version_wrap.dart';
import 'package:cordis/widgets/settings/sheet_filters.dart';
import 'package:cordis/widgets/settings/sheet_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/settings/layout_settings_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';

class ViewCipherScreen extends StatefulWidget {
  final int? cipherID;
  final dynamic versionID;
  final VersionType versionType;

  const ViewCipherScreen({
    super.key,
    required this.cipherID,
    this.versionID,

    required this.versionType,
  });

  @override
  State<ViewCipherScreen> createState() => _ViewCipherScreenState();
}

class _ViewCipherScreenState extends State<ViewCipherScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _setOriginalKey();
      _scrollController.addListener(_scrollListener);
    });
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final scroll = context.read<AutoScrollProvider>();

    scroll.currentItemIndex = 0;

    final isManualScroll =
        _scrollController.position.userScrollDirection != ScrollDirection.idle;

    if (isManualScroll) {
      if (scroll.scrollModeEnabled) scroll.stopAutoScroll();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        scroll.syncSectionFromViewport(
          _scrollController.position.viewportDimension,
          context.read<LayoutSetProvider>().scrollDirection,
        );
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final sect = context.read<SectionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();

    switch (widget.versionType) {
      case VersionType.import:
      case VersionType.brandNew:
        break;
      case VersionType.local:
      case VersionType.playlist:
        if (widget.versionID != null) {
          await sect.loadSectionsOfVersion(widget.versionID);
        }
        break;
      case VersionType.cloud:
        if (widget.versionID != null) {
          final version = cloudVer.getVersion(widget.versionID);

          if (version == null) return;

          sect.setNewSectionsInCache(
            widget.versionID,
            version.sections.map(
              (key, value) => MapEntry(key, value.toDomain()),
            ),
          );
        }
        break;
    }
  }

  void _setOriginalKey() {
    final trans = context.read<TranspositionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final ciph = context.read<CipherProvider>();

    final String originalKey;
    final String? transposedKey;

    if (widget.versionType == VersionType.cloud) {
      final version = cloudVer.getVersion(widget.versionID)!;
      originalKey = version.originalKey;
      transposedKey = version.transposedKey;
    } else {
      final cipher = ciph.getCipher(widget.cipherID!);
      final version = localVer.getVersion(widget.versionID);
      originalKey = cipher!.musicKey;
      transposedKey = version?.transposedKey;
    }
    trans.setOriginalKey(originalKey);
    trans.setTransposedKey(transposedKey);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStructBar(),
        Selector<LayoutSetProvider, Axis>(
          selector: (context, laySet) => laySet.scrollDirection,
          builder: (context, scrollDirection, child) {
            return Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: scrollDirection,
                padding: scrollDirection == Axis.vertical
                    ? const EdgeInsets.only(bottom: 16, left: 8, right: 8)
                    : const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: VersionWrap(itemIndex: 0, versionID: widget.versionID),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStructBar() {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (isWideScreen)
                Expanded(child: StructureList(versionID: widget.versionID)),

              if (widget.versionType == VersionType.local) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _navigateToEditScreen(),
                ),
                if (isWideScreen) ...[SizedBox(width: 24)] else ...[Spacer()],
              ],
              IconButton(
                icon: const Icon(Icons.format_paint),
                onPressed: _showStyleSettings(),
              ),
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: _showFilters(),
              ),
              if (isWideScreen) ...[SizedBox(width: 24)] else ...[Spacer()],

              const Transposer(),
              if (isWideScreen) ...[SizedBox(width: 24)] else ...[Spacer()],

              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () =>
                    context.read<NavigationProvider>().attemptPop(context),
              ),
            ],
          ),
          if (!isWideScreen) StructureList(versionID: widget.versionID),
        ],
      ),
    );
  }

  VoidCallback _showStyleSettings() {
    return () {
      showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        context: context,
        isScrollControlled: true,
        builder: (context) => const StyleSettings(),
      );
    };
  }

  VoidCallback _showFilters() {
    return () {
      showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        context: context,
        isScrollControlled: true,
        builder: (context) => BottomSheet(
          onClosing: () {},
          builder: (context) => const ContentFilters(),
        ),
      );
    };
  }

  VoidCallback _navigateToEditScreen() {
    return () {
      final localVer = context.read<LocalVersionProvider>();
      final ciph = context.read<CipherProvider>();
      final sect = context.read<SectionProvider>();
      context.read<NavigationProvider>().push(
        () => EditCipherScreen(
          cipherID: widget.cipherID!,
          versionID: widget.versionID,
          versionType: widget.versionType,
        ),
        changeDetector: () {
          return localVer.hasUnsavedChanges ||
              ciph.hasUnsavedChanges ||
              sect.hasUnsavedChanges;
        },
        onChangeDiscarded: () {
          localVer.loadVersion(widget.versionID);
          ciph.loadCipher(widget.cipherID ?? -1);
          sect.loadSectionsOfVersion(widget.versionID);
        },
        showBottomNavBar: true,
      );
    };
  }
}
