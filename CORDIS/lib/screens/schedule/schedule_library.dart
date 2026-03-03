import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/widgets/schedule/library/schedule_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleLibraryScreen extends StatefulWidget {
  const ScheduleLibraryScreen({super.key});

  @override
  State<ScheduleLibraryScreen> createState() => _ScheduleLibraryScreenState();
}

class _ScheduleLibraryScreenState extends State<ScheduleLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final localScheduleProvider = context.read<LocalScheduleProvider>();
      final cloudScheduleProvider = context.read<CloudScheduleProvider>();
      final cloudVersionProvider = context.read<CloudVersionProvider>();

      if (mounted) {
        await cloudScheduleProvider.loadSchedules(
          context.read<MyAuthProvider>().id!,
        );
        await localScheduleProvider.loadSchedules();
      }
      for (var schedule in cloudScheduleProvider.schedules.values) {
        for (var versionEntry in schedule.playlist.versions.entries) {
          cloudVersionProvider.setVersion(versionEntry.key, versionEntry.value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer2<LocalScheduleProvider, CloudScheduleProvider>(
      builder: (context, localSch, cloudSch, child) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              _buildSearchBar(localSch, cloudSch, colorScheme),
              if (localSch.isLoading || cloudSch.isLoading)
                _buildLoadingState(colorScheme)
              else if (localSch.error != null || cloudSch.error != null)
                _buildErrorState(localSch, cloudSch, colorScheme)
              else
                _buildScheduleList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(
    LocalScheduleProvider localSch,
    CloudScheduleProvider cloudSch,
    ColorScheme colorScheme,
  ) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchSchedule,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: colorScheme.surfaceContainer),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        suffixIcon: const Icon(Icons.search),
        fillColor: colorScheme.surfaceContainerHighest,
        visualDensity: VisualDensity.compact,
      ),
      onChanged: (value) {
        localSch.setSearchTerm(value);
        cloudSch.setSearchTerm(value);
      },
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Expanded(
      child: Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      ),
    );
  }

  Widget _buildErrorState(
    LocalScheduleProvider localSch,
    CloudScheduleProvider cloudSch,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Center(
        child: Text(
          localSch.error ?? cloudSch.error ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    return const Expanded(child: ScheduleScrollView());
  }
}
