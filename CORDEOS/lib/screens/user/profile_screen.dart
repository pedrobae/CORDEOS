import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/settings/settings_provider.dart';
import 'package:cordeos/providers/user/user_provider.dart';
import 'package:cordeos/providers/settings/app_info_provider.dart';
import 'package:cordeos/screens/user/login_screen.dart';
import 'package:cordeos/screens/user/new_password_screen.dart';
import 'package:cordeos/utils/locale.dart';
import 'package:cordeos/widgets/common/delete_confirmation.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/common/labeled_country_picker.dart';
import 'package:cordeos/widgets/common/labeled_language_picker.dart';
import 'package:cordeos/widgets/common/labeled_text_field.dart';
import 'package:cordeos/widgets/common/labeled_timezone_picker.dart';
import 'package:cordeos/widgets/sheet_reauthenticate.dart';
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
      final auth = context.read<MyAuthProvider>();
      final user = context.read<UserProvider>();
      final settings = context.read<SettingsProvider>();

      emailController.text = auth.userEmail ?? '';
      usernameController.text =
          auth.userName ?? AppLocalizations.of(context)!.guest;

      if (auth.userCountry == null) {
        user.cacheUserCountry(auth.id!, settings.country);
      }
      if (auth.userLanguage == null) {
        user.cacheUserLanguage(auth.id!, settings.locale.languageCode);
      }
      if (auth.userTimeZone == null) {
        user.cacheUserTimeZone(auth.id!, settings.timeZone);
      }

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
    return Consumer3<MyAuthProvider, UserProvider, SettingsProvider>(
      builder: (context, auth, user, settings, child) {
        _handleReauthIfNeeded(auth, user);
        _handleSignOutIfNeeded(auth);
        final nav = context.read<NavigationProvider>();

        return Scaffold(
          appBar: _buildAppBar(nav),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEmailField(auth),
                  _buildUsernameField(),
                  _buildCountryPicker(auth, settings, user),
                  _buildLanguagePicker(auth, settings, user),
                  _buildTimezonePicker(auth, settings, user),
                  _buildSaveButton(user, auth),
                  _buildChangePasswordButton(nav),
                  _buildDeleteAccountButton(auth, user),
                  _buildAppVersionText(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleReauthIfNeeded(MyAuthProvider auth, UserProvider user) {
    if (auth.error != null && auth.error!.contains('requires-recent-login')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return BottomSheet(
              onClosing: () {
                auth.clearError();
              },
              shape: ContinuousRectangleBorder(),
              builder: (BuildContext context) {
                return ReAuthSheet(onReAuthSuccess: () {});
              },
            );
          },
        );
      });
    }
  }

  void _handleSignOutIfNeeded(MyAuthProvider auth) {
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      });
    }
  }

  AppBar _buildAppBar(NavigationProvider nav) {
    return AppBar(
      leading: BackButton(
        onPressed: () {
          nav.attemptPop(context);
        },
      ),
    );
  }

  Widget _buildEmailField(MyAuthProvider auth) {
    return LabeledTextField(
      label: AppLocalizations.of(context)!.email,
      isEnabled: false,
      controller: emailController,
    );
  }

  Widget _buildUsernameField() {
    return LabeledTextField(
      label: AppLocalizations.of(context)!.username,
      controller: usernameController,
    );
  }

  Widget _buildCountryPicker(
    MyAuthProvider auth,
    SettingsProvider settings,
    UserProvider user,
  ) {
    return Selector<UserProvider, String>(
      selector: (_, user) =>
          user.getUserByFirebaseId(auth.id!)?.country ?? settings.country,
      builder: (context, country, child) {
        return LabeledCountryPicker(
          countryCode: country,
          onCountryChanged: (value) {
            settings.setCountry(value.countryCode);
            user.cacheUserCountry(auth.id!, value.countryCode);
          },
        );
      },
    );
  }

  Widget _buildLanguagePicker(
    MyAuthProvider auth,
    SettingsProvider settings,
    UserProvider user,
  ) {
    return Selector<UserProvider, String>(
      selector: (_, user) =>
          user.getUserByFirebaseId(auth.id!)?.language ??
          LocaleUtils.getLanguageName(settings.locale, context),
      builder: (context, language, child) {
        return LabeledLanguagePicker(
          language: language,
          onLanguageChanged: (value) {
            final locale = LocaleUtils.getLocaleFromLanguageName(
              value,
              context,
            );
            settings.setLocale(locale);
            user.cacheUserLanguage(auth.id!, locale.languageCode);
          },
        );
      },
    );
  }

  Widget _buildTimezonePicker(
    MyAuthProvider auth,
    SettingsProvider settings,
    UserProvider user,
  ) {
    return Selector<UserProvider, String>(
      selector: (_, user) =>
          user.getUserByFirebaseId(auth.id!)?.timeZone ?? settings.timeZone,
      builder: (context, timeZone, child) {
        return LabeledTimezonePicker(
          timezone: timeZone,
          onTimezoneChanged: (value) {
            settings.setTimeZone(value);
            user.cacheUserTimeZone(auth.id!, value);
          },
        );
      },
    );
  }

  Widget _buildSaveButton(UserProvider user, MyAuthProvider auth) {
    return FilledTextButton(
      text: AppLocalizations.of(context)!.save,
      isDark: true,
      onPressed: () async {
        await user.save(auth.id!);
        if ((user.error == null || user.error!.isEmpty) && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.profileSavedSuccessfully,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildChangePasswordButton(NavigationProvider nav) {
    return FilledTextButton(
      text: AppLocalizations.of(context)!.changePassword,
      onPressed: () {
        nav.push(() => NewPasswordScreen(), showBottomNavBar: true);
      },
    );
  }

  Widget _buildDeleteAccountButton(MyAuthProvider auth, UserProvider user) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return DeleteConfirmationSheet(
              itemType: AppLocalizations.of(context)!.account,
              onConfirm: () async {
                await auth.deleteAccount();
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
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildAppVersionText() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Selector<AppInfoProvider, (bool, String)>(
      selector: (_, info) => (info.isLoading, info.appVersion),
      builder: (context, data, child) {
        final (isLoading, appVersion) = data;
        if (isLoading) {
          return const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        return Text(
          appVersion,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.surfaceContainerLow,
          ),
        );
      },
    );
  }
}
