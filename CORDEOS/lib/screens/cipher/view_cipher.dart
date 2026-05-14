import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:cordeos/providers/play/auto_scroll_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/transposition_provider.dart';
import 'package:cordeos/widgets/ciphers/transposer.dart';
import 'package:cordeos/widgets/ciphers/viewer/structure_list.dart';
import 'package:cordeos/widgets/play/version_wrap.dart';
import 'package:cordeos/widgets/settings/sheet_filters.dart';
import 'package:cordeos/widgets/settings/sheet_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/screens/cipher/edit_cipher.dart';

class ViewCipherScreen extends StatefulWidget {
  final int? cipherID;
  final VersionDto? versionDto;
  final int? versionID;
  final VersionType versionType;

  ViewCipherScreen({
    super.key,
    this.versionDto,
    this.cipherID,
    this.versionID,

    required this.versionType,
  }) {
    assert(versionID != null || versionDto != null);
  }

  @override
  State<ViewCipherScreen> createState() => _ViewCipherScreenState();
}

class _ViewCipherScreenState extends State<ViewCipherScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late TranspositionProvider _trans;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _trans = context.read<TranspositionProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setOriginalKey();
      _scrollController.addListener(_scrollListener);
    });
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final scroll = context.read<ScrollProvider>();

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

  void _setOriginalKey() {
    final localVer = context.read<LocalVersionProvider>();
    final ciph = context.read<CipherProvider>();

    final String originalKey;
    final String? transposedKey;

    if (widget.versionDto != null) {
      originalKey = widget.versionDto!.originalKey;
      transposedKey = widget.versionDto!.transposedKey;
    } else {
      final cipher = ciph.getCipher(widget.cipherID!);
      final version = localVer.getVersion(widget.versionID!);
      originalKey = cipher!.musicKey;
      transposedKey = version?.transposedKey;
    }

    _trans.setOriginalKey(originalKey, widget.versionID ?? -2);
    _trans.setTransposedKey(transposedKey);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    _trans.clearTransposer();
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
                    ? const EdgeInsets.symmetric(vertical: 16, horizontal: 8)
                    : const EdgeInsets.symmetric(horizontal: 8),
                child: VersionWrap(
                  itemIndex: 0,
                  versionID: widget.versionID,
                  versionDto: widget.versionDto,
                ),
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
                Expanded(
                  child: StructureList(
                    versionID: widget.versionID,
                    versionDto: widget.versionDto,
                  ),
                ),

              if (widget.versionType == VersionType.local) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _navigateToEditScreen(),
                ),
                if (isWideScreen) ...[SizedBox(width: 24)] else ...[Spacer()],
              ],
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showStyleSettings(),
                onLongPress: _showStyleSettings(secret: true),
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
          if (!isWideScreen)
            StructureList(
              versionID: widget.versionID,
              versionDto: widget.versionDto,
            ),
        ],
      ),
    );
  }

  VoidCallback _showStyleSettings({bool secret = false}) {
    return () {
      showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        context: context,
        isScrollControlled: true,
        builder: (context) => StyleSettings(),
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
          versionID: widget.versionID!,
          versionType: widget.versionType,
        ),
        keepAlive: true,
        changeDetector: () {
          return localVer.hasUnsavedChanges ||
              ciph.hasUnsavedChanges ||
              sect.hasUnsavedChanges;
        },
        onChangeDiscarded: () {
          localVer.loadVersion(widget.versionID!);
          ciph.loadCipher(widget.cipherID ?? -1);
          sect.loadSectionsOfVersion(widget.versionID!);
        },
      );
    };
  }
}
