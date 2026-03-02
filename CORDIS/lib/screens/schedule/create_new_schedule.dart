import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/screens/playlist/playlist_library.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/schedule/create_edit/details_form.dart';
import 'package:cordis/widgets/schedule/create_edit/roles_users_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateScheduleScreen extends StatefulWidget {
  final int creationStep;

  const CreateScheduleScreen({super.key, required this.creationStep});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  late LocalScheduleProvider _scheduleProvider;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _roomVenueController = TextEditingController();
  final TextEditingController _annotationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scheduleProvider = context.read<LocalScheduleProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scheduleProvider.addListener(_scheduleErrorListener);
      }
    });
  }

  void _scheduleErrorListener() {
    final error = _scheduleProvider.error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scheduleProvider.removeListener(_scheduleErrorListener);

    // Dispose all controllers
    _nameController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _locationController.dispose();
    _roomVenueController.dispose();
    _annotationsController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      LocalScheduleProvider,
      MyAuthProvider,
      SelectionProvider,
      NavigationProvider
    >(
      builder:
          (
            context,
            scheduleProvider,
            myAuthProvider,
            selectionProvider,
            navigationProvider,
            child,
          ) {
            final textTheme = Theme.of(context).textTheme;

            return Scaffold(
              appBar: AppBar(
                leading: BackButton(
                  onPressed: () => navigationProvider.attemptPop(context),
                ),
                title: Text(
                  AppLocalizations.of(context)!.schedulePlaylist,
                  style: textTheme.titleMedium,
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // STEP INDICATOR
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.stepXofY(widget.creationStep, 3),
                      style: textTheme.titleLarge,
                    ),
                    // STEP INSTRUCTION
                    switch (widget.creationStep) {
                      1 => Text(
                        AppLocalizations.of(
                          context,
                        )!.selectPlaylistForScheduleInstruction,
                        style: textTheme.bodyLarge,
                      ),
                      2 => Text(
                        AppLocalizations.of(
                          context,
                        )!.fillScheduleDetailsInstruction,
                        style: textTheme.bodyLarge,
                      ),
                      3 => Text(
                        AppLocalizations.of(
                          context,
                        )!.createRolesAndAssignUsersInstruction,
                        style: textTheme.bodyLarge,
                      ),
                      _ => SizedBox.shrink(),
                    },
                    switch (widget.creationStep) {
                      1 => SizedBox(height: 16),
                      2 => SizedBox.shrink(),
                      3 => SizedBox(height: 16),
                      _ => SizedBox.shrink(),
                    },

                    // STEP CONTENT
                    switch (widget.creationStep) {
                      1 => Expanded(child: PlaylistLibraryScreen()),
                      2 => Expanded(
                        child: ScheduleForm(
                          scheduleId: -1,
                          nameController: _nameController,
                          dateController: _dateController,
                          startTimeController: _startTimeController,
                          locationController: _locationController,
                          roomVenueController: _roomVenueController,
                          annotationsController: _annotationsController,
                        ),
                      ),
                      3 => Expanded(child: RolesAndUsersForm(scheduleId: -1)),
                      _ => SizedBox.shrink(),
                    },

                    // CONTINUE / CREATE BUTTON
                    FilledTextButton(
                      text: switch (widget.creationStep) {
                        1 => AppLocalizations.of(context)!.keepGoing,
                        2 => AppLocalizations.of(context)!.keepGoing,
                        3 => AppLocalizations.of(context)!.createPlaceholder(
                          AppLocalizations.of(context)!.schedule,
                        ),
                        _ => 'ERROR',
                      },
                      onPressed: () {
                        switch (widget.creationStep) {
                          case 1:
                            // Cache Brand New Schedule
                            scheduleProvider.cacheBrandNewSchedule(
                              selectionProvider.selectedItemIds.first,
                              myAuthProvider.id!,
                            );

                            // Proceed to step 2
                            navigationProvider.push(
                              CreateScheduleScreen(creationStep: 2),
                              showBottomNavBar: true,
                            );
                          case 2:
                            // Cache Schedule Details
                            scheduleProvider.cacheScheduleDetails(
                              -1,
                              name: _nameController.text,
                              date: _dateController.text,
                              startTime: _startTimeController.text,
                              location: _locationController.text,
                              roomVenue: _roomVenueController.text,
                              annotations: _annotationsController.text,
                            );

                            // Proceed to step 3
                            navigationProvider.push(
                              CreateScheduleScreen(creationStep: 3),
                              showBottomNavBar: true,
                            );
                            break;
                          case 3:
                            // Create Schedule
                            scheduleProvider
                                .createFromCache(myAuthProvider.id!)
                                .then((success) {
                                  if (success && context.mounted) {
                                    navigationProvider.attemptPop(
                                      context,
                                      route: NavigationRoute.schedule,
                                    );
                                  }
                                });
                            break;
                          default:
                            null;
                        }
                      },
                      isDisabled: selectionProvider.selectedItemIds.length != 1,
                      isDark: true,
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}
