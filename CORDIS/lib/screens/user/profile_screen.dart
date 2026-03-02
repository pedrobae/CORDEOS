import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/settings_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/providers/app_info_provider.dart';
import 'package:cordis/screens/user/new_password_screen.dart';
import 'package:cordis/utils/locale.dart';
import 'package:cordis/widgets/common/delete_confirmation.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_country_picker.dart';
import 'package:cordis/widgets/common/labeled_language_picker.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
import 'package:cordis/widgets/common/labeled_timezone_picker.dart';
import 'package:cordis/widgets/sheet_reauthenticate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<MyAuthProvider>();

      emailController.text = authProvider.userEmail ?? '';
      usernameController.text =
          authProvider.userName ?? AppLocalizations.of(context)!.guest;

      usernameController.addListener(_usernameListener());
    });
  }

  VoidCallback _usernameListener() {
    return () {
      final userProvider = context.read<UserProvider>();
      final authProvider = context.read<MyAuthProvider>();
      userProvider.cacheUsername(authProvider.id!, usernameController.text);
    };
  }

  @override
  void dispose() {
    usernameController.removeListener(_usernameListener());
    emailController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer5<
      NavigationProvider,
      MyAuthProvider,
      UserProvider,
      SettingsProvider,
      AppInfoProvider
    >(
      builder:
          (
            context,
            navProvider,
            authProvider,
            userProvider,
            settingsProvider,
            appInfoProvider,
            child,
          ) {
            if (authProvider.error != null &&
                authProvider.error!.contains('requires-recent-login')) {
              // If the error indicates that re-authentication is required, show the re-authentication sheet
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return BottomSheet(
                      onClosing: () {
                        authProvider.clearError();
                      },
                      shape: ContinuousRectangleBorder(),
                      builder: (BuildContext context) {
                        return ReAuthSheet(
                          onReAuthSuccess: () {
                            authProvider.deleteAccount();
                            userProvider.deleteUserData(authProvider.id!);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  },
                );
              });
            }
            return Scaffold(
              appBar: AppBar(
                leading: BackButton(
                  onPressed: () {
                    navProvider.attemptPop(context);
                  },
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LabeledTextField(
                      label: AppLocalizations.of(context)!.email,
                      isEnabled: false,
                      controller: emailController,
                    ),
                    LabeledTextField(
                      label: AppLocalizations.of(context)!.username,
                      controller: usernameController,
                    ),
                    LabeledCountryPicker(
                      countryCode:
                          authProvider.userCountry ?? settingsProvider.country,
                      onCountryChanged: (value) {
                        settingsProvider.setCountry(value.countryCode);
                        userProvider.cacheUserCountry(
                          authProvider.id!,
                          value.countryCode,
                        );
                      },
                    ),
                    LabeledLanguagePicker(
                      language:
                          authProvider.userLanguage ??
                          LocaleUtils.getLanguageName(
                            settingsProvider.locale,
                            context,
                          ),
                      onLanguageChanged: (value) {
                        settingsProvider.setLocale(
                          LocaleUtils.getLocaleFromLanguageName(value, context),
                        );
                        userProvider.cacheUserLanguage(
                          authProvider.id!,
                          LocaleUtils.getLocaleFromLanguageName(
                            value,
                            context,
                          ).languageCode,
                        );
                      },
                    ),
                    LabeledTimezonePicker(
                      timezone:
                          authProvider.userTimeZone ??
                          settingsProvider.timeZone,
                      onTimezoneChanged: (value) {
                        settingsProvider.setTimeZone(value);
                        userProvider.cacheUserTimeZone(authProvider.id!, value);
                      },
                    ),
                    Spacer(),
                    FilledTextButton(
                      text: AppLocalizations.of(context)!.save,
                      isDark: true,
                      onPressed: () async {
                        await userProvider.save(authProvider.id!);
                        if ((userProvider.error == null ||
                                userProvider.error!.isEmpty) &&
                            context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.profileSavedSuccessfully,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    FilledTextButton(
                      text: AppLocalizations.of(context)!.changePassword,
                      onPressed: () {
                        navProvider.push(
                          NewPasswordScreen(),
                          showBottomNavBar: true,
                        );
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return DeleteConfirmationSheet(
                              itemType: AppLocalizations.of(context)!.account,
                              onConfirm: () async {
                                await authProvider.deleteAccount();
                                if (authProvider.error == null &&
                                    context.mounted) {
                                  userProvider.deleteUserData(authProvider.id!);
                                }
                              },
                            );
                          },
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: BorderDirectional(
                            bottom: BorderSide(color: colorScheme.error),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.deleteAccountRequest,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.appVersion(appInfoProvider.appVersion),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.surfaceContainerLow,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}
