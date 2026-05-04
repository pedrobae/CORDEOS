import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/providers/user/user_provider.dart';
import 'package:cordeos/providers/version/cloud_version_provider.dart';
import 'package:cordeos/widgets/schedule/library/card_cloud.dart';
import 'package:cordeos/widgets/schedule/library/card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<MyAuthProvider>();
    final userProvider = context.read<UserProvider>();
    final localScheduleProvider = context.read<LocalScheduleProvider>();
    final cloudScheduleProvider = context.read<CloudScheduleProvider>();
    final cloudVersionProvider = context.read<CloudVersionProvider>();

    if (!authProvider.isAuthenticated) {
      return;
    }
    await cloudScheduleProvider.loadSchedules(context, authProvider.id!);
    await localScheduleProvider.loadSchedules();

    final user = userProvider.getUserByFirebaseId(authProvider.id!);
    if (user != null) {
      authProvider.setUserData(user);
    }

    for (var schedule in cloudScheduleProvider.schedules.values) {
      for (var versionEntry in schedule.playlist.versions.entries) {
        cloudVersionProvider.setVersion(versionEntry.key, versionEntry.value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          Text(
            DateFormat(
              'EEEE, MMM d',
              locale.languageCode,
            ).format(DateTime.now()),
            style: textTheme.bodyLarge,
          ),
          _buildWelcomeMessage(),
          Expanded(child: _buildSchedules()),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    final textTheme = Theme.of(context).textTheme;

    return Selector<MyAuthProvider, String?>(
      selector: (_, auth) => auth.userName,
      builder: (context, userName, child) {
        return Text(
          userName == null
              ? AppLocalizations.of(context)!.welcome
              : AppLocalizations.of(context)!.helloUser(userName),
          style: textTheme.headlineSmall,
        );
      },
    );
  }

  Widget _buildSchedules() {
    final textTheme = Theme.of(context).textTheme;

    return Selector2<
      LocalScheduleProvider,
      CloudScheduleProvider,
      ({List<dynamic> futureScheduleIDs, String? error})
    >(
      selector: (context, localSch, cloudSch) {
        final localFuture = localSch.futureScheduleIDs;
        final cloudFuture = cloudSch.futureScheduleIDs;

        return (
          futureScheduleIDs: [...localFuture, ...cloudFuture],
          error: (localSch.error != null && localSch.error!.isNotEmpty)
              ? localSch.error
              : (cloudSch.error != null && cloudSch.error!.isNotEmpty)
              ? cloudSch.error
              : null,
        );
      },
      builder: (context, s, child) {
        if (s.futureScheduleIDs.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 16,
            children: [
              SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)!.welcome,
                style: textTheme.headlineSmall,
              ),
              Text(
                AppLocalizations.of(context)!.noUpcomingSchedules,
                style: textTheme.bodyLarge,
              ),
            ],
          );
        }

        return _buildScheduleList(s.futureScheduleIDs);
      },
    );
  }

  Widget _buildScheduleList(List<dynamic> futureScheduleIDs) {
    final textTheme = Theme.of(context).textTheme;

    final localSch = context.read<LocalScheduleProvider>();
    final cloudSch = context.read<CloudScheduleProvider>();
    final auth = context.read<MyAuthProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Text(
          AppLocalizations.of(context)!.futureSchedules,
          style: textTheme.titleMedium,
        ),

        // SCHEDULES LIST
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await cloudSch.loadSchedules(context, auth.id!, forceFetch: true);
              await localSch.loadSchedules();
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
