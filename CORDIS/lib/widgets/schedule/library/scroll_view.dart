import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/widgets/schedule/library/card_cloud.dart';
import 'package:cordis/widgets/schedule/library/card.dart';
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

  bool pastFutureSch = false;

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
        pastFutureSch = true;
      });
    } else {
      setState(() {
        pastFutureSch = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Selector2<
      LocalScheduleProvider,
      CloudScheduleProvider,
      ({
        List<dynamic> futureScheduleIDs,
        List<dynamic> pastScheduleIDs,
        String? error,
      })
    >(
      selector: (context, localSch, cloudSch) {
        final localFuture = localSch.futureScheduleIDs;
        final localPast = localSch.pastScheduleIDs;
        final cloudFuture = cloudSch.futureScheduleIDs;
        final cloudPast = cloudSch.pastScheduleIDs;

        return (
          futureScheduleIDs: [...localFuture, ...cloudFuture],
          pastScheduleIDs: [...localPast, ...cloudPast],
          error: (localSch.error != null && localSch.error!.isNotEmpty)
              ? localSch.error
              : (cloudSch.error != null && cloudSch.error!.isNotEmpty)
              ? cloudSch.error
              : null,
        );
      },
      builder: (context, s, child) {
        if (s.error != null && s.error!.isNotEmpty) {
          return _buildErrorState(s.error!);
        }

        // If there are no past schedules, remove the listener
        if (s.pastScheduleIDs.isEmpty) {
          _scrollController.removeListener(_listenForEndOfFutureSchedules);
        }

        // Handle empty state
        if (s.futureScheduleIDs.isEmpty && s.pastScheduleIDs.isEmpty) {
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

        return _buildScheduleList(s.pastScheduleIDs, s.futureScheduleIDs);
      },
    );
  }

  Widget _buildErrorState(String error) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Center(
        child: Text(
          error,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildScheduleList(
    List<dynamic> pastScheduleIDs,
    List<dynamic> futureScheduleIDs,
  ) {
    final textTheme = Theme.of(context).textTheme;
    
    final localSch = context.read<LocalScheduleProvider>();
    final cloudSch = context.read<CloudScheduleProvider>();
    final auth = context.read<MyAuthProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SCHEDULES HEADER
        pastFutureSch
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
              await localSch.loadSchedules();
              await cloudSch.loadSchedules(auth.id!, forceFetch: true);
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
