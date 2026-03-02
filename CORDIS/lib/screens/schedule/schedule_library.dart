import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer4<
      LocalScheduleProvider,
      CloudScheduleProvider,
      NavigationProvider,
      SelectionProvider
    >(
      builder:
          (
            context,
            localScheduleProvider,
            cloudScheduleProvider,
            navigationProvider,
            selectionProvider,
            child,
          ) {
            return Padding(
              padding: const EdgeInsets.only(
                top: 16.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchSchedule,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(0),
                        borderSide: BorderSide(
                          color: colorScheme.surfaceContainer,
                        ),
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
                      localScheduleProvider.setSearchTerm(value);
                      cloudScheduleProvider.setSearchTerm(value);
                    },
                  ),

                  // Loading state
                  if (localScheduleProvider.isLoading ||
                      cloudScheduleProvider.isLoading) ...[
                    Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    // Error state
                  ] else if (localScheduleProvider.error != null ||
                      cloudScheduleProvider.error != null) ...[
                    Expanded(
                      child: Center(
                        child: Text(
                          localScheduleProvider.error ??
                              cloudScheduleProvider.error ??
                              '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                    // Schedule list
                  ] else ...[
                    Expanded(child: ScheduleScrollView()),
                  ],
                ],
              ),
            );
          },
    );
  }
}
