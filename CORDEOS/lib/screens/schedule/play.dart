import 'dart:async';
import 'package:flutter/material.dart';

import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/models/domain/playlist/playlist_item.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/playlist/flow_item_provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordeos/providers/play/play_state_provider.dart';
import 'package:cordeos/providers/version/cloud_version_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';

import 'package:cordeos/widgets/play/play_playlist.dart';

class PlaySchedule extends StatefulWidget {
  final dynamic scheduleId;

  const PlaySchedule({super.key, required this.scheduleId});

  @override
  State<PlaySchedule> createState() => PlayScheduleState();
}

class PlayScheduleState extends State<PlaySchedule> {
  late final bool isCloud = widget.scheduleId is String;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
      if (mounted) {
        setState(() => _isReady = true);
      }
    });
  }

  @override
  void dispose() {
    // Clear token cache when leaving play screen
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.scheduleId == null) throw Exception("Schedule ID is required");

    if (!isCloud) {
      await _loadLocal();
    } else {
      await _loadCloud();
    }
  }

  Future<void> _loadLocal() async {
    if (!mounted) return;

    final localSch = context.read<LocalScheduleProvider>();
    final play = context.read<PlaylistProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final ciph = context.read<CipherProvider>();
    final sect = context.read<SectionProvider>();
    final flow = context.read<FlowItemProvider>();
    final state = context.read<PlayStateProvider>();

    final schedule = localSch.getSchedule(widget.scheduleId)!;
    await play.loadPlaylist(schedule.playlistId);

    final items = play.getPlaylist(schedule.playlistId)!.items;
    state.setItemCount(items.length);
    for (final item in items) {
      switch (item.type) {
        case PlaylistItemType.version:
          await localVer.loadVersion(item.contentId!);
          final version = localVer.getVersion(item.contentId!);
          if (version == null) continue;
          await ciph.loadCipher(version.cipherID);
          await sect.loadSectionsOfVersion(item.contentId!);

          break;
        case PlaylistItemType.flowItem:
          await flow.loadFlowItem(item.contentId!);
          break;
      }

      state.appendItem(item);
    }
  }

  Future<void> _loadCloud() async {
    if (!mounted) return;

    final cloudSch = context.read<CloudScheduleProvider>();
    final cloudVer = context.read<CloudVersionProvider>();
    final sect = context.read<SectionProvider>();
    final state = context.read<PlayStateProvider>();

    final schedule = cloudSch.getSchedule(widget.scheduleId);

    if (schedule == null) {
      throw Exception("Schedule not found");
    }

    final items = schedule.items;
    state.setItemCount(items.length);

    for (var item in items) {
      switch (item.type) {
        case PlaylistItemType.version:
          final version = schedule.playlist.versions[item.firebaseContentId]!;
          cloudVer.setVersion(item.firebaseContentId!, version);

          final sections = <String, Section>{};
          for (var entry in version.sections.entries) {
            sections[entry.key] = entry.value.toDomain();
          }

          sect.setNewSectionsInCache(item.firebaseContentId!, sections);
          break;
        case PlaylistItemType.flowItem:
          // Flow items are loaded as part of the schedule
          break;
      }

      state.appendItem(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [CircularProgressIndicator()],
          ),
        ),
      );
    }

    final cloudSch = context.read<CloudScheduleProvider>();

    return PlayPlaylist(
      playlistDto: isCloud
          ? cloudSch.getSchedule(widget.scheduleId)!.playlist
          : null,
    );
  }
}
