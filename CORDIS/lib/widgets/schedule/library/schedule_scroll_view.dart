import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/widgets/schedule/library/cloud_schedule_card.dart';
import 'package:cordis/widgets/schedule/library/schedule_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleScrollView extends StatefulWidget {
  const ScheduleScrollView({super.key});

  @override
  State<ScheduleScrollView> createState() => _ScheduleScrollViewState();
}

class _ScheduleScrollViewState extends State<ScheduleScrollView> {
  final _scrollController = ScrollController();
  final _pastHeaderKey = GlobalKey();

  bool passedFutureSchedules = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(_listenForEndOfFutureSchedules);
    });
  }

  void _listenForEndOfFutureSchedules() {
    // CHECK IF WE SCROLLED THE PAST SCHEDULES HEADER
    final box = _pastHeaderKey.currentContext!.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    if (_scrollController.offset >= position.dy + kToolbarHeight) {
      setState(() {
        passedFutureSchedules = true;
      });
    } else {
      setState(() {
        passedFutureSchedules = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Consumer3<
      LocalScheduleProvider,
      CloudScheduleProvider,
      MyAuthProvider
    >(
      builder:
          (
            context,
            localScheduleProvider,
            cloudScheduleProvider,
            authProvider,
            child,
          ) {
            // Handle loading state
            if (localScheduleProvider.isLoading ||
                cloudScheduleProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final localfuture = localScheduleProvider.futureScheduleIDs;
            final localPast = localScheduleProvider.pastScheduleIDs;
            final cloudFuture = cloudScheduleProvider.futureScheduleIDs;
            final cloudPast = cloudScheduleProvider.pastScheduleIDs;

            final futureScheduleIds = [...localfuture, ...cloudFuture];

            final pastScheduleIds = [...localPast, ...cloudPast];

            // If there are no past schedules, remove the listner
            if (pastScheduleIds.isEmpty) {
              _scrollController.removeListener(_listenForEndOfFutureSchedules);
            }
            // Handle empty state
            if (futureScheduleIds.isEmpty && pastScheduleIds.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 64),
                  Text(
                    AppLocalizations.of(context)!.emptyScheduleLibrary,
                    style: textTheme.bodyLarge!,
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            return _buildScheduleList(
              pastScheduleIds,
              futureScheduleIds,
              localScheduleProvider,
              cloudScheduleProvider,
              authProvider,
              textTheme,
            );
          },
    );
  }

  Widget _buildScheduleList(
    List<dynamic> pastScheduleIDs,
    List<dynamic> futureScheduleIDs,
    LocalScheduleProvider localScheduleProvider,
    CloudScheduleProvider cloudScheduleProvider,
    MyAuthProvider authProvider,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SCHEDULES HEADER
        passedFutureSchedules
            ? (pastScheduleIDs.isNotEmpty
                  ? Text(
                      AppLocalizations.of(context)!.pastSchedules,
                      style: textTheme.titleMedium,
                    )
                  : SizedBox.shrink())
            : (futureScheduleIDs.isNotEmpty
                  ? Text(
                      AppLocalizations.of(context)!.futureSchedules,
                      style: textTheme.titleMedium,
                    )
                  : SizedBox.shrink()),

        // SCHEDULES LIST
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await localScheduleProvider.loadSchedules();
              await cloudScheduleProvider.loadSchedules(
                authProvider.id!,
                forceFetch: true,
              );
              for (var schedule in cloudScheduleProvider.schedules.values) {
                for (var version in schedule.playlist.versions.entries) {
                  if (mounted) {
                    context.read<CloudVersionProvider>().setVersion(
                      version.key,
                      version.value,
                    );
                  }
                }
              }
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.0),
                  ...futureScheduleIDs.map((scheduleId) {
                    if (scheduleId is String) {
                      return CloudScheduleCard(scheduleId: scheduleId);
                    }
                    return ScheduleCard(scheduleId: scheduleId);
                  }),
                  SizedBox(height: 16.0),
                  pastScheduleIDs.isEmpty
                      ? SizedBox.shrink()
                      : Text(
                          key: _pastHeaderKey,
                          AppLocalizations.of(context)!.pastSchedules,
                          style: textTheme.titleMedium,
                        ),
                  SizedBox(height: 8.0),
                  ...pastScheduleIDs.map((scheduleId) {
                    if (scheduleId is String) {
                      return CloudScheduleCard(scheduleId: scheduleId);
                    }
                    return ScheduleCard(scheduleId: scheduleId);
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
