import 'package:cordis/helpers/database.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/settings/secret_settings_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/screens/settings/report_bug_screen.dart';
import 'package:cordis/services/cache_service.dart';
import 'package:cordis/utils/locale.dart';

import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/settings/settings_provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';

import 'package:cordis/widgets/common/delete_confirmation.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_language_picker.dart';
import 'package:cordis/widgets/settings/settings_section_header.dart';
import 'package:cordis/widgets/settings/settings_switch_tile.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqlite_api.dart';

class SettingsScreen extends StatefulWidget {
  final bool showSecrets;
  const SettingsScreen({super.key, this.showSecrets = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();

    return Consumer2<SettingsProvider, SecretSetProvider>(
      builder: (context, set, secSet, child) => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(
              title: AppLocalizations.of(context)!.settings,
              icon: Icons.settings,
            ),
            SizedBox(),
            SettingsSwitchTile(
              label: AppLocalizations.of(context)!.theme,
              icon: set.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              value: set.themeMode == ThemeMode.dark,
              onChanged: (value) {
                context.read<SettingsProvider>().setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
            SettingsSwitchTile(
              label: AppLocalizations.of(context)!.colorVariant,
              icon: set.isColorVariant ? Icons.palette : Icons.palette_outlined,
              value: set.isColorVariant,
              onChanged: (_) {
                context.read<SettingsProvider>().toggleColorVariant();
              },
            ),
            _buildLanguageButton(set),
            const SizedBox(height: 32),

            SettingsSectionHeader(
              title: AppLocalizations.of(context)!.support,
              icon: Icons.support_agent,
            ),
            SizedBox(),
            _buildDebugButton(nav),
            const SizedBox(height: 32),

            if (widget.showSecrets) ...[
              SettingsSectionHeader(
              title: AppLocalizations.of(context)!.advancedSettings,
              icon: Icons.settings,
            ),
            SizedBox(),
            SettingsSwitchTile(
              label: AppLocalizations.of(context)!.denseCipherCard,
              icon: secSet.denseCipherCard ? Icons.grid_on : Icons.grid_off,
              value: secSet.denseCipherCard,
              onChanged: (value) {
                secSet.toggleDenseCipherCard();
              },
            )
            ],

            if (kDebugMode) ...[
              SettingsSectionHeader(
                title: AppLocalizations.of(context)!.developmentTools,
                icon: Icons.build,
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
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.databaseResetSuccess),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorMessage(
              AppLocalizations.of(context)!.resetDatabase,
              e.toString(),
            ),
          ),
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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.reloadInterfaceSuccess),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(
                AppLocalizations.of(context)!.reloadInterface,
                e.toString(),
              ),
            ),
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
      const tables = [
        'tag',
        'cipher',
        'cipher_tags',
        'version',
        'section',
        'user',
        'playlist',
        'playlist_version',
        'user_playlist',
        'flow_item',
        'schedule',
        'role',
        'role_member',
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
      final size = MediaQuery.of(context).size;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          backgroundColor: colorScheme.surface,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          title: Text('${AppLocalizations.of(context)!.database}_v.$dbVersion'),
          content: SizedBox(
            width: size.width * 0.95,
            height: size.height * 0.75,
            child: SingleChildScrollView(
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
                    final canOpen = count >= 0;
                    return GestureDetector(
                      onTap: canOpen
                          ? () {
                              Navigator.of(context).pop();
                              _showTableData(entry.key);
                            }
                          : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
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
                              count == -1
                                  ? AppLocalizations.of(context)!.error
                                  : count.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: count == -1
                                    ? colorScheme.error
                                    : (count > 0
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: canOpen
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
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
      const allowedTables = {
        'tag',
        'cipher',
        'cipher_tags',
        'version',
        'section',
        'user',
        'playlist',
        'playlist_version',
        'user_playlist',
        'flow_item',
        'schedule',
        'role',
        'role_member',
      };

      if (!allowedTables.contains(tableName)) {
        throw Exception('Table not allowed: $tableName');
      }

      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      List<Map<String, Object?>> rows = await db.query(tableName, limit: 100);

      if (!mounted) return;

      final colorScheme = Theme.of(context).colorScheme;
      final size = MediaQuery.of(context).size;

      Future<void> refreshRows(StateSetter setState) async {
        final refreshedRows = await db.query(tableName, limit: 100);
        if (!mounted) return;
        setState(() {
          rows = refreshedRows;
        });
      }

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            backgroundColor: colorScheme.surface,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.tableData(tableName),
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.reloadInterface,
                  onPressed: () => refreshRows(setState),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            content: SizedBox(
              width: size.width * 0.96,
              height: size.height * 0.8,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.surfaceContainer,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: rows.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.noRowsInTable,
                        ),
                      )
                    : SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 8,
                            columns: [
                              ...rows.first.keys.map(
                                (column) => DataColumn(
                                  label: Text(column.toUpperCase()),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  AppLocalizations.of(context)!.actions,
                                ),
                              ),
                            ],
                            rows: rows.map((row) {
                              final dynamic rowId = row['id'];
                              final bool canDelete = rowId != null;
                              return DataRow(
                                cells: [
                                  ...row.values.map(
                                    (value) => DataCell(
                                      Text(
                                        value?.toString() ?? 'null',
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      tooltip: canDelete
                                          ? AppLocalizations.of(
                                              context,
                                            )!.deleteRow
                                          : AppLocalizations.of(
                                              context,
                                            )!.rowHasNoId,
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: canDelete
                                            ? colorScheme.error
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                      onPressed: canDelete
                                          ? () async {
                                              final bool?
                                              confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.deleteRowQuestion,
                                                  ),
                                                  content: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.deleteRowQuestionBody(
                                                      rowId.toString(),
                                                      tableName,
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(false),
                                                      child: Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.cancel,
                                                      ),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(true),
                                                      style:
                                                          FilledButton.styleFrom(
                                                            backgroundColor:
                                                                colorScheme
                                                                    .error,
                                                          ),
                                                      child: Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.delete,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirmed != true) return;

                                              await db.delete(
                                                tableName,
                                                where: 'id = ?',
                                                whereArgs: [rowId],
                                              );

                                              await refreshRows(setState);

                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.rowDeletedFromTable(
                                                      rowId.toString(),
                                                      tableName,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          : null,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
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
