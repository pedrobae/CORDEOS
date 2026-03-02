import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/widgets/schedule/play/play_flow_item.dart';
import 'package:cordis/widgets/schedule/play/play_version.dart';
import 'package:cordis/widgets/settings/auto_scroll_settings.dart';
import 'package:cordis/widgets/settings/content_filters.dart';
import 'package:cordis/widgets/settings/style_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayScheduleScreen extends StatefulWidget {
  final dynamic scheduleId;

  const PlayScheduleScreen({super.key, required this.scheduleId});

  @override
  State<PlayScheduleScreen> createState() => PlayScheduleScreenState();
}

class PlayScheduleScreenState extends State<PlayScheduleScreen>
    with SingleTickerProviderStateMixin {
  late final bool isCloud = widget.scheduleId is String;
  bool showSettings = false;

  int currentTabIndex = 0;
  List<PlaylistItem> items = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureDataLoaded();
    });
    super.initState();
  }

  Future<void> _ensureDataLoaded() async {
    final scheduleProvider = context.read<LocalScheduleProvider>();
    final cloudScheduleProvider = context.read<CloudScheduleProvider>();
    final playlistProvider = context.read<PlaylistProvider>();
    final cipherProvider = context.read<CipherProvider>();
    final versionProvider = context.read<LocalVersionProvider>();
    final flowItemProvider = context.read<FlowItemProvider>();
    final sectionProvider = context.read<SectionProvider>();

    if (widget.scheduleId == null) throw Exception("Schedule ID is required");

    if (!isCloud) {
      final schedule = scheduleProvider.getSchedule(widget.scheduleId)!;

      await playlistProvider.loadPlaylist(schedule.playlistId!);

      items = playlistProvider.getPlaylistById(schedule.playlistId!)!.items;

      for (final item in items) {
        if (item.type == PlaylistItemType.version) {
          await versionProvider.loadVersion(item.contentId!);
          await cipherProvider.loadCipherOfVersion(item.contentId!);
          await sectionProvider.loadSectionsOfVersion(item.contentId!);
        } else if (item.type == PlaylistItemType.flowItem) {
          await flowItemProvider.loadFlowItem(item.contentId!);
        }
      }
    } else {
      if (!cloudScheduleProvider.schedules.containsKey(widget.scheduleId)) {
        await cloudScheduleProvider.loadSchedule(widget.scheduleId);
      }

      final schedule = cloudScheduleProvider.schedules[widget.scheduleId];

      if (schedule == null) {
        throw Exception("Schedule not found");
      }
      setState(() {
        items = schedule.playlist.getPlaylistItems();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer6<
      CloudScheduleProvider,
      PlaylistProvider,
      LocalVersionProvider,
      CipherProvider,
      FlowItemProvider,
      NavigationProvider
    >(
      builder:
          (
            context,
            cloudScheduleProvider,
            playlistProvider,
            versionProvider,
            cipherProvider,
            flowItemProvider,
            navigationProvider,
            child,
          ) {
            return Stack(
              children: [
                // TAB VIEWER
                items.isEmpty
                    ? (versionProvider.isLoading ||
                              cloudScheduleProvider.isLoading ||
                              flowItemProvider.isLoading ||
                              cipherProvider.isLoading ||
                              playlistProvider.isLoading)
                          ? Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            )
                          : Center(
                              child: Text(
                                AppLocalizations.of(context)!.noPlaylistItems,
                                style: textTheme.bodyMedium,
                              ),
                            )
                    : Builder(
                        builder: (context) {
                          final item = items[currentTabIndex];
                          switch (item.type) {
                            case PlaylistItemType.version:
                              if (isCloud) {
                                return PlayVersion(
                                  cloudVersionID: item.firebaseContentId!,
                                );
                              } else {
                                return PlayVersion(
                                  localVersionID: item.contentId!,
                                );
                              }
                            case PlaylistItemType.flowItem:
                              if (isCloud) {
                                final flowItemMap =
                                    (cloudScheduleProvider.schedules[widget
                                                .scheduleId]
                                            as ScheduleDto)
                                        .playlist
                                        .flowItems[item.firebaseContentId]!;

                                return PlayFlowItem(
                                  flowItem: FlowItem(
                                    firebaseId: item.firebaseContentId!,
                                    playlistId: -1,
                                    title: flowItemMap['title'] as String,
                                    contentText:
                                        flowItemMap['contentText'] as String,
                                    duration: Duration(
                                      seconds: (flowItemMap['duration'] as int),
                                    ),
                                    position: flowItemMap['position'] as int,
                                  ),
                                );
                              } else {
                                return PlayFlowItem(
                                  flowItem: flowItemProvider.getFlowItem(
                                    item.contentId!,
                                  )!,
                                );
                              }
                          }
                        },
                      ),

                // TOP RIGHT CLOSE BUTTON
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => navigationProvider.attemptPop(context),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.close,
                        color: colorScheme.onSurface,
                        size: 26,
                      ),
                    ),
                  ),
                ),

                // BOTTOM CONTROLS
                Positioned(
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(0),
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.surfaceContainerHigh,
                          width: .5,
                        ),
                      ),
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [
                        /// SETTINGS CONTROLS
                        if (showSettings)
                          Container(
                            color: colorScheme.surfaceContainerHigh,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                // Style settings button - opens bottom sheet
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        showSettings = false;
                                      });
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (context) {
                                          return BottomSheet(
                                            onClosing: () {},
                                            builder: (context) {
                                              return StyleSettings();
                                            },
                                          );
                                        },
                                      );
                                    },
                                    child: Icon(Icons.format_paint),
                                  ),
                                ),
                                // Filters button - opens bottom sheet
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        showSettings = false;
                                      });
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (context) {
                                          return BottomSheet(
                                            onClosing: () {},
                                            builder: (context) {
                                              return ContentFilters();
                                            },
                                          );
                                        },
                                      );
                                    },
                                    child: Icon(Icons.filter_alt),
                                  ),
                                ),
                                // Autoplay controls
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        showSettings = false;
                                      });
                                      showModalBottomSheet(
                                        context: context,
                                        barrierColor: Colors.transparent,
                                        builder: (context) {
                                          return BottomSheet(
                                            onClosing: () {},
                                            builder: (context) {
                                              return AutoScrollSettings();
                                            },
                                          );
                                        },
                                      );
                                    },
                                    child: Icon(Icons.auto_stories_outlined),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        /// PLAY CONTROLS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // PREVIOUS ITEM BUTTON
                            GestureDetector(
                              onTap: () {
                                if (currentTabIndex > 0) {
                                  setState(() {
                                    currentTabIndex--;
                                  });
                                }
                              },
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width / 4,
                                height: 48,
                                child: Icon(
                                  Icons.chevron_left,
                                  color: colorScheme.surfaceContainerLowest,
                                  size: 48,
                                ),
                              ),
                            ),

                            // NEXT ITEM TITLE
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 2,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    showSettings = !showSettings;
                                  });
                                },
                                child: Builder(
                                  builder: (context) {
                                    String nextTitle = '';
                                    if (currentTabIndex < items.length - 1) {
                                      final nextItem =
                                          items[currentTabIndex + 1];
                                      switch (nextItem.type) {
                                        case PlaylistItemType.version:
                                          if (isCloud) {
                                            nextTitle =
                                                ((cloudScheduleProvider
                                                            .schedules[widget
                                                            .scheduleId]
                                                        as ScheduleDto)
                                                    .playlist
                                                    .versions[nextItem
                                                        .firebaseContentId]
                                                    ?.title) ??
                                                '';
                                          } else {
                                            final version = versionProvider
                                                .cachedVersion(
                                                  nextItem.contentId!,
                                                );

                                            if (version == null) {
                                              return CircularProgressIndicator();
                                            }

                                            nextTitle =
                                                cipherProvider
                                                    .getCipher(version.cipherId)
                                                    ?.title ??
                                                '';
                                          }
                                          break;
                                        case PlaylistItemType.flowItem:
                                          if (isCloud) {
                                            nextTitle =
                                                ((cloudScheduleProvider
                                                            .schedules[widget
                                                            .scheduleId]
                                                        as ScheduleDto)
                                                    .playlist
                                                    .flowItems[nextItem
                                                    .firebaseContentId]?['title']) ??
                                                '';
                                          } else {
                                            nextTitle =
                                                flowItemProvider
                                                    .getFlowItem(
                                                      nextItem.contentId!,
                                                    )
                                                    ?.title ??
                                                '';
                                          }
                                          break;
                                      }
                                    }
                                    return Text(
                                      nextTitle.isEmpty
                                          ? '-'
                                          : AppLocalizations.of(
                                              context,
                                            )!.nextPlaceholder(nextTitle),
                                      style: textTheme.bodyLarge,
                                      softWrap: true,
                                      textAlign: TextAlign.center,
                                    );
                                  },
                                ),
                              ),
                            ),

                            // NEXT ITEM BUTTON
                            GestureDetector(
                              onTap: () {
                                if (currentTabIndex < items.length - 1) {
                                  setState(() {
                                    currentTabIndex++;
                                  });
                                }
                              },
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width / 4,
                                height: 48,
                                child: Icon(
                                  Icons.chevron_right,
                                  color: colorScheme.surfaceContainerLowest,
                                  size: 48,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
    );
  }
}
