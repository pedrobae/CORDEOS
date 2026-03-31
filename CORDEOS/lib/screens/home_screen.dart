import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/schedule.dart';
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(child: _buildContent()),
    );
  }

  dynamic _getNextSchedule(
    LocalScheduleProvider localSch,
    CloudScheduleProvider cloudSch,
  ) {
    final nextLocal = localSch.getNextSchedule();
    final nextCloud = cloudSch.getNextSchedule();

    if (nextLocal != null && nextCloud != null) {
      return nextLocal.time.isBefore(
            TimeOfDay.fromDateTime(nextCloud.datetime.toDate()),
          )
          ? nextLocal
          : nextCloud;
    }

    return nextLocal ?? nextCloud;
  }

  Widget _buildContent() {
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        Text(
          DateFormat('EEEE, MMM d', locale.languageCode).format(DateTime.now()),
          style: textTheme.bodyLarge,
        ),
        _buildWelcomeMessage(),
        _buildNextSchedule(),
      ],
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

  Widget _buildNextSchedule() {
    final textTheme = Theme.of(context).textTheme;

    return Selector2<
      LocalScheduleProvider,
      CloudScheduleProvider,
      ({dynamic nextSchedule})
    >(
      selector: (context, localSch, cloudSch) =>
          (nextSchedule: _getNextSchedule(localSch, cloudSch)),
      builder: (context, s, child) {
        if (s.nextSchedule == null) {
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Text(
              AppLocalizations.of(context)!.nextUp,
              style: textTheme.titleMedium,
            ),
            (s.nextSchedule is Schedule)
                ? ScheduleCard(scheduleId: s.nextSchedule.id)
                : CloudScheduleCard(scheduleId: s.nextSchedule.firebaseId),
          ],
        );
      },
    );
  }
}
