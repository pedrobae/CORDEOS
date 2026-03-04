import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/models/domain/playlist/playlist.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';

import 'package:cordis/providers/playlist/flow_item_provider.dart';
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
      final localVer = context.read<LocalVersionProvider>();
      final flow = context.read<FlowItemProvider>();

      await play.loadPlaylist(widget.playlistId);

      // Load versions for the playlist items
      final items = play.getPlaylistById(widget.playlistId)?.items ?? [];

      for (var item in items) {
        if (item.type == PlaylistItemType.version) {
          await localVer.loadVersion(item.contentId!);
        } else if (item.type == PlaylistItemType.flowItem) {
          await flow.loadFlowItem(item.contentId!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    final localSch = Provider.of<LocalScheduleProvider>(context, listen: false);
    final auth = Provider.of<MyAuthProvider>(context, listen: false);

    return Consumer<PlaylistProvider>(
      builder: (context, play, child) {
        final playlist = play.getPlaylistById(widget.playlistId);

        if (playlist == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(playlist, play, nav, localSch, auth),
          floatingActionButton: _buildFloatingActionButton(),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: playlist.items.isEmpty
                ? _buildEmptyState()
                : _buildItemsList(context, playlist),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(
    Playlist playlist,
    PlaylistProvider play,
    NavigationProvider nav,
    LocalScheduleProvider localSch,
    MyAuthProvider auth,
  ) {
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
          onPressed: () => _handleSave(playlist, play, nav, localSch, auth),
        ),
      ],
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton(
      onPressed: () => _openPlaylistEditSheet(context),
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

  Widget _buildItemsList(BuildContext context, Playlist playlist) {
    return Builder(
      builder: (context) {
        return ReorderableListView.builder(
          shrinkWrap: true,
          proxyDecorator: (child, index, animation) =>
              Material(type: MaterialType.transparency, child: child),
          buildDefaultDragHandles: false,
          physics: const ClampingScrollPhysics(),
          scrollDirection: Axis.vertical,
          onReorder: (oldIndex, newIndex) =>
              _onReorder(context, playlist, oldIndex, newIndex),
          itemCount: playlist.items.length,
          itemBuilder: (BuildContext context, int index) {
            final item = playlist.items[index];
            return _buildPlaylistItem(item, index);
          },
        );
      },
    );
  }

  Widget _buildPlaylistItem(PlaylistItem item, int index) {
    switch (item.type) {
      case PlaylistItemType.version:
        if (item.id == null) return SizedBox.shrink(key: GlobalKey(),);
        return PlaylistVersionCard(
          key: ValueKey('playlist_version_${item.id}'),
          index: index,
          versionId: item.contentId,
          playlistId: widget.playlistId,
          itemId: item.id!,
        );
      case PlaylistItemType.flowItem:
        return FlowItemCard(
          key: ValueKey('flow_item_${item.id}'),
          index: index,
          flowItemId: item.contentId ?? item.id!,
          playlistId: widget.playlistId,
        );
    }
  }

  Future<void> _handleSave(
    Playlist playlist,
    PlaylistProvider play,
    NavigationProvider nav,
    LocalScheduleProvider localSch,
    MyAuthProvider auth,
  ) async {
    play.updatePlaylistFromCache(widget.playlistId);

    final schedule = await localSch.getScheduleWithPlaylistId(
      widget.playlistId,
    );
    if (schedule != null && schedule.scheduleState == ScheduleState.published) {
      ScheduleSyncService().scheduleToCloud(schedule, auth.id!);
    }

    nav.pop();
  }

  void _openPlaylistEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return BottomSheet(
          shape: LinearBorder(),
          onClosing: () {},
          builder: (BuildContext context) {
            return AddToPlaylistSheet(playlistId: widget.playlistId);
          },
        );
      },
    );
  }

  void _onReorder(
    BuildContext context,
    Playlist playlist,
    int oldIndex,
    int newIndex,
  ) async {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reordenar: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Tentar Novamente',
              textColor: Colors.white,
              onPressed: () =>
                  _onReorder(context, playlist, oldIndex, newIndex),
            ),
          ),
        );
      }
    }
  }
}
