import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/models/domain/playlist/playlist.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';

import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/services/sync_service.dart';

import 'package:cordis/widgets/playlist/viewer/add_to_playlist_sheet.dart';

import 'package:cordis/widgets/playlist/viewer/version_card.dart';
import 'package:cordis/widgets/playlist/viewer/flow_item_card.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewPlaylistScreen extends StatefulWidget {
  final int playlistId; // Receive the playlist ID from the parent

  const ViewPlaylistScreen({super.key, required this.playlistId});

  @override
  State<ViewPlaylistScreen> createState() => _ViewPlaylistScreenState();
}

class _ViewPlaylistScreenState extends State<ViewPlaylistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final play = context.read<PlaylistProvider>();

      await play.loadPlaylist(widget.playlistId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context, listen: false);

    return Consumer<PlaylistProvider>(
      builder: (context, play, child) {
        final playlist = play.getPlaylist(widget.playlistId);

        if (playlist == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(playlist, nav),
          floatingActionButton: _buildFloatingActionButton(),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: playlist.items.isEmpty
                ? _buildEmptyState()
                : _buildItemsList(playlist),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(Playlist playlist, NavigationProvider nav) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      leading: BackButton(
        color: colorScheme.onSurface,
        onPressed: () => nav.attemptPop(context),
      ),
      title: Text(playlist.name, style: theme.textTheme.titleMedium),
      actions: [
        IconButton(
          icon: Icon(Icons.save, color: colorScheme.onSurface),
          onPressed: () => _handleSave(playlist, nav),
        ),
      ],
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton(
      onPressed: () => _openPlaylistEditSheet(),
      backgroundColor: colorScheme.onSurface,
      shape: const CircleBorder(),
      child: Icon(Icons.add, color: colorScheme.onPrimary),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.emptyPlaylist,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        Text(
          AppLocalizations.of(context)!.emptyPlaylistInstructions,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildItemsList(Playlist playlist) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      proxyDecorator: (child, index, animation) =>
          Material(type: MaterialType.transparency, child: child),
      buildDefaultDragHandles: false,
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.vertical,
      onReorder: (oldIndex, newIndex) =>
          _onReorder(playlist, oldIndex, newIndex),
      itemCount: playlist.items.length,
      itemBuilder: (BuildContext context, int index) {
        final item = playlist.items[index];
        return _buildPlaylistItem(item, index);
      },
    );
  }

  Widget _buildPlaylistItem(PlaylistItem item, int index) {
    switch (item.type) {
      case PlaylistItemType.version:
        return PlaylistVersionCard(
          key: ValueKey('ver_${item.id}_idx_$index'),
          index: index,
          versionId: item.contentId!,
          playlistId: widget.playlistId,
          itemId: item.id ?? -1,
        );
      case PlaylistItemType.flowItem:
        return FlowItemCard(
          key: ValueKey('flow_${item.id}_idx_$index'),
          index: index,
          flowItemId: item.contentId ?? item.id!,
          playlistId: widget.playlistId,
        );
    }
  }

  Future<void> _handleSave(Playlist playlist, NavigationProvider nav) async {
    final play = context.read<PlaylistProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final localSch = context.read<LocalScheduleProvider>();
    final auth = context.read<MyAuthProvider>();

    play.updatePlaylistFromCache(widget.playlistId);
    localVer.persistCachedDeletions();

    final schedule = await localSch.getScheduleWithPlaylistId(
      widget.playlistId,
    );
    if (schedule != null && schedule.scheduleState == ScheduleState.published) {
      ScheduleSyncService().scheduleToCloud(schedule, auth.id!);
    }

    nav.pop();
  }

  void _openPlaylistEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BottomSheet(
          shape: LinearBorder(),
          onClosing: () {},
          builder: (context) {
            return AddToPlaylistSheet(playlistId: widget.playlistId);
          },
        );
      },
    );
  }

  void _onReorder(Playlist playlist, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    try {
      context.read<PlaylistProvider>().cacheReposition(
        playlist.id,
        oldIndex,
        newIndex,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao reordenar: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Tentar Novamente',
            textColor: Colors.white,
            onPressed: () => _onReorder(playlist, oldIndex, newIndex),
          ),
        ),
      );
    }
  }
}
