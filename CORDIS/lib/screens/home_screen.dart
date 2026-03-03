import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/widgets/schedule/library/cloud_schedule_card.dart';
import 'package:cordis/widgets/schedule/library/schedule_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';

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
    await cloudScheduleProvider.loadSchedules(authProvider.id!);
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
      child:
          Consumer3<
            MyAuthProvider,
            LocalScheduleProvider,
            CloudScheduleProvider
          >(
            builder: (context, auth, localSch, cloudSch, child) {
              if (auth.isLoading) {
                return _buildLoadingState();
              }
              if (auth.error != null) {
                return _buildErrorState(auth);
              }

              final nextSchedule = _getNextSchedule(localSch, cloudSch);
              return _buildContent(auth, localSch, nextSchedule);
            },
          ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.loading),
        ],
      ),
    );
  }

  Widget _buildErrorState(MyAuthProvider auth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.errorMessage(
              AppLocalizations.of(context)!.authentication,
              auth.error!,
            ),
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => auth.signInAnonymously(),
            child: Text(AppLocalizations.of(context)!.tryAgain),
          ),
        ],
      ),
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

  Widget _buildContent(
    MyAuthProvider auth,
    LocalScheduleProvider localSch,
    dynamic nextSchedule,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        Text(
          DateFormat('EEEE, MMM d', locale.languageCode).format(DateTime.now()),
          style: textTheme.bodyLarge,
        ),
        _buildWelcomeMessage(auth, textTheme),
        _buildNextSchedule(localSch, nextSchedule, textTheme, colorScheme),
      ],
    );
  }

  Widget _buildWelcomeMessage(MyAuthProvider auth, TextTheme textTheme) {
    return Text(
      AppLocalizations.of(
        context,
      )!.helloUser(auth.userName ?? AppLocalizations.of(context)!.guest),
      style: textTheme.headlineSmall,
    );
  }

  Widget _buildNextSchedule(
    LocalScheduleProvider localSch,
    dynamic nextSchedule,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    if (localSch.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (nextSchedule == null) {
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
            AppLocalizations.of(context)!.getStartedMessage,
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
        (nextSchedule is Schedule)
            ? ScheduleCard(scheduleId: nextSchedule.id)
            : CloudScheduleCard(scheduleId: nextSchedule.firebaseId),
      ],
    );
  }
}
