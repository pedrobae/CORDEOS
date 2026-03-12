import 'package:cordis/helpers/database.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/screens/settings/report_bug_screen.dart';
import 'package:cordis/services/cache_service.dart';
import 'package:cordis/utils/locale.dart';

import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/settings_provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';

import 'package:cordis/widgets/common/delete_confirmation.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_language_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqlite_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();

    return Consumer<SettingsProvider>(
      builder: (context, set, child) => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              AppLocalizations.of(context)!.settings,
              Icons.settings,
            ),
            SizedBox(),
            _buildThemeToggle(set),
            _buildColorVariantToggle(set),
            _buildLanguageButton(set),
            const SizedBox(height: 32),
            
            _buildSectionHeader(
              AppLocalizations.of(context)!.support,
              Icons.support_agent,
            ),
            SizedBox(),
            _buildDebugButton(nav),
            const SizedBox(height: 32),

            if (kDebugMode) ...[
              _buildSectionHeader(
                AppLocalizations.of(context)!.developmentTools,
                Icons.build,
              ),
              SizedBox(),
              _buildResetDatabaseButton(),
              _buildReloadInterfaceButton(),
              _buildDatabaseInfoButton(),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(SettingsProvider settings) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.surfaceContainer, width: 1),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.theme,
            style: textTheme.labelLarge,
          ),
          const Spacer(),
          Icon(
            settings.themeMode == ThemeMode.dark
                ? Icons.dark_mode
                : Icons.light_mode,
            color: colorScheme.primary,
          ),
          SizedBox(width: 8),
          Switch(
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (value) {
              context.read<SettingsProvider>().setThemeMode(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorVariantToggle(SettingsProvider settings) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.surfaceContainer, width: 1),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.colorVariant,
            style: textTheme.labelLarge,
          ),
          const Spacer(),
          Icon(
            settings.isColorVariant ? Icons.palette : Icons.palette_outlined,
            color: colorScheme.primary,
          ),
          SizedBox(width: 8),
          Switch(
            value: settings.isColorVariant,
            onChanged: (value) {
              context.read<SettingsProvider>().toggleColorVariant();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(SettingsProvider settings) {
    return LabeledLanguagePicker(
      language: LocaleUtils.getLanguageName(settings.locale, context),
      onLanguageChanged: (value) {
        final locale = LocaleUtils.getLocaleFromLanguageName(value, context);
        settings.setLocale(locale);
      },
      singleLine: true,
      isDiscrete: true,
    );
  }

  Widget _buildDebugButton(NavigationProvider nav) {
    return FilledTextButton(
      icon: Icons.feedback_outlined,
      text: AppLocalizations.of(context)!.reportBug,
      trailingIcon: Icons.chevron_right,
      onPressed: () {
        nav.pop();
        nav.push(
          () => const ReportBugScreen(),
          showAppBar: true,
          showBottomNavBar: true,
          showDrawerIcon: true,
        );
      },
      isDiscrete: true,
    );
  }

  Widget _buildResetDatabaseButton() {
    return FilledTextButton(
      icon: Icons.refresh,
      text: AppLocalizations.of(context)!.resetDatabase,
      tooltip: AppLocalizations.of(context)!.resetDatabaseSubtitle,
      trailingIcon: Icons.chevron_right,
      onPressed: () => showModalBottomSheet(
        context: context,
        builder: (context) {
          return DeleteConfirmationSheet(
            itemType: AppLocalizations.of(context)!.database,
            onConfirm: () => _resetDatabase(),
          );
        },
      ),
      isDangerous: true,
      isDiscrete: true,
    );
  }

  Widget _buildReloadInterfaceButton() {
    return FilledTextButton(
      icon: Icons.cached,
      text: AppLocalizations.of(context)!.reloadInterface,
      tooltip: AppLocalizations.of(context)!.reloadInterfaceSubtitle,
      trailingIcon: Icons.chevron_right,
      onPressed: _reloadAllData,
      isDiscrete: true,
    );
  }

  Widget _buildDatabaseInfoButton() {
    return FilledTextButton(
      icon: Icons.storage,
      text: AppLocalizations.of(context)!.databaseInformation,
      tooltip: AppLocalizations.of(context)!.databaseInfoSubtitle,
      onPressed: () => _showDatabaseInfo(),
      trailingIcon: Icons.chevron_right,
      isDiscrete: true,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 16,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
          softWrap: true,
        ),
      ],
    );
  }

  Future<void> _resetDatabase() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.resetDatabase();

      final cacheService = CacheService();
      await cacheService.clearAllCaches();

      if (mounted) {
        await context.read<UserProvider>().ensureUserExists(
          context.read<MyAuthProvider>().id!,
        );
      }

      await _reloadAllData();

      // Check mounted again after async operations
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Banco de dados resetado com sucesso!'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao resetar banco: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    final cacheService = CacheService();

    await cacheService.clearAllCaches();
  }

  Future<void> _reloadAllData() async {
    try {
      // Clear all provider caches first
      context.read<CipherProvider>().clearCache();
      context.read<PlaylistProvider>().clearCache();
      context.read<LocalVersionProvider>().clearCache();
      context.read<CloudVersionProvider>().clearCache();
      context.read<SectionProvider>().clearCache();
      context.read<UserProvider>().clearCache();
      context.read<FlowItemProvider>().clearCache();
      context.read<LocalScheduleProvider>().clearCache();
      context.read<SelectionProvider>().disableSelectionMode();
      context.read<CloudScheduleProvider>().clearCache();
      await _clearCache();
      if (!mounted) return;
      // Force reload all providers from database
      await Future.wait([
        context.read<CipherProvider>().loadCiphers(forceReload: true),
        context.read<CloudVersionProvider>().loadVersions(
          forceReload: true,
          localCiphers: context.read<CipherProvider>().ciphers.values.toList(),
        ),
        context.read<PlaylistProvider>().loadPlaylists(),
        context.read<UserProvider>().loadUsers(),
        context.read<LocalScheduleProvider>().loadSchedules(),
        context.read<CloudScheduleProvider>().loadSchedules(
          context.read<MyAuthProvider>().id!,
          forceFetch: true,
        ),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Interface e dados recarregados completamente!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao recarregar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showDatabaseInfo() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Get table counts
      final tables = [
        'tag',
        'cipher',
        'version',
        'section',
        'user',
        'playlist',
        'flow_item',
        'schedule',
        'role',
      ];
      final Map<String, int> tableCounts = {};

      for (final table in tables) {
        try {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM $table',
          );
          tableCounts[table] = result.first['count'] as int;
        } catch (e) {
          tableCounts[table] = -1; // Error indicator
        }
      }

      final int dbVersion = await db.getVersion();

      // Check mounted after async operations
      if (!mounted) return;

      final colorScheme = Theme.of(context).colorScheme;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          title: Text('${AppLocalizations.of(context)!.database}_v.$dbVersion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.recordsPerTable,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...tableCounts.entries.map((entry) {
                  final count = entry.value;
                  return GestureDetector(
                    onTap: count > 0
                        ? () {
                            _showTableData(entry.key);
                          }
                        : null,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border.all(
                          color: colorScheme.surfaceContainerHigh,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            count == -1 ? 'Erro' : count.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: count == -1
                                  ? colorScheme.error
                                  : (count > 0
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainerLow),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: count > 0
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerLow,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorMessage(
              AppLocalizations.of(context)!.databaseInformation,
              e.toString(),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _showTableData(String tableName) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final rows = await db.query(tableName, limit: 100);

      if (!mounted) return;

      final colorScheme = Theme.of(context).colorScheme;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          backgroundColor: colorScheme.surface,
          title: Text(AppLocalizations.of(context)!.tableData(tableName)),
          content: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.surfaceContainer,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(0),
              ),
              width: double.maxFinite,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 8,
                  columns: rows.first.keys
                      .map(
                        (column) =>
                            DataColumn(label: Text(column.toUpperCase())),
                      )
                      .toList(),
                  rows: rows
                      .map(
                        (row) => DataRow(
                          cells: row.values
                              .map(
                                (value) => DataCell(
                                  Text(
                                    value?.toString() ?? 'null',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorMessage(
              AppLocalizations.of(context)!.tableData(tableName),
              e.toString(),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
