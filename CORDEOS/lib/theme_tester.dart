import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/schedule.dart';
import 'package:cordeos/widgets/common/cloud_download_indicator.dart';
import 'package:cordeos/utils/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie_native/lottie_native.dart';
import 'package:cordeos/widgets/schedule/status_chip.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';

void main() {
  runApp(const ThemeTesterApp());
}

class ThemeTesterApp extends StatefulWidget {
  const ThemeTesterApp({super.key});

  @override
  State<ThemeTesterApp> createState() => _ThemeTesterAppState();
}

class _ThemeTesterAppState extends State<ThemeTesterApp> {
  bool _isDark = false;
  bool _isVariant = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = _isDark ? ThemeMode.dark : ThemeMode.light;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.getTheme(_isVariant, false),
      darkTheme: AppTheme.getTheme(_isVariant, true),
      themeMode: themeMode,
      home: ThemeTesterScreen(
        isDark: _isDark,
        isVariant: _isVariant,
        onDarkChanged: (value) => setState(() => _isDark = value),
        onVariantChanged: (value) => setState(() => _isVariant = value),
      ),
    );
  }
}

class ThemeTesterScreen extends StatelessWidget {
  final bool isDark;
  final bool isVariant;
  final ValueChanged<bool> onDarkChanged;
  final ValueChanged<bool> onVariantChanged;

  const ThemeTesterScreen({
    super.key,
    required this.isDark,
    required this.isVariant,
    required this.onDarkChanged,
    required this.onVariantChanged,
  });

  Widget _buildAssetsPreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text('Lottie', style: theme.textTheme.titleSmall),
            Container(
              width: double.infinity,
              color: colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 120,
                child: LottieView.fromAsset(
                  filePath: 'assets/animations/iconLoad.json',
                ),
              ),
            ),
            Text('PNG / SVG', style: theme.textTheme.titleSmall),
            Container(
              width: double.infinity,
              color: colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Image.asset(
                    'assets/logos/app_icon.png',
                    width: 84,
                    height: 84,
                  ),
                  Image.asset(
                    'assets/logos/app_icon_transparent.png',
                    width: 84,
                    height: 84,
                  ),
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.asset(
                      'assets/logos/nh_colored_white.svg',
                      width: 120,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.developmentTools}: Theme Tester')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.theme, style: theme.textTheme.titleMedium),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark mode'),
                    value: isDark,
                    onChanged: onDarkChanged,
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.colorVariant),
                    value: isVariant,
                    onChanged: onVariantChanged,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Typography', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                spacing: 6,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Headline Small', style: theme.textTheme.headlineSmall),
                  Text('Title Medium', style: theme.textTheme.titleMedium),
                  Text('Body Medium', style: theme.textTheme.bodyMedium),
                  Text('Label Large', style: theme.textTheme.labelLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Buttons', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
              FilledButton(onPressed: () {}, child: const Text('Filled')),
              FilledButton.tonal(onPressed: () {}, child: const Text('Tonal')),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
            ],
          ),
          const SizedBox(height: 12),
          Text('Surface Containers', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          _SurfaceTile(label: 'surface', color: colors.surface),
          _SurfaceTile(
            label: 'surfaceContainerLowest',
            color: colors.surfaceContainerLowest,
          ),
          _SurfaceTile(
            label: 'surfaceContainerLow',
            color: colors.surfaceContainerLow,
          ),
          _SurfaceTile(
            label: 'surfaceContainer',
            color: colors.surfaceContainer,
          ),
          _SurfaceTile(
            label: 'surfaceContainerHigh',
            color: colors.surfaceContainerHigh,
          ),
          _SurfaceTile(
            label: 'surfaceContainerHighest',
            color: colors.surfaceContainerHighest,
          ),
          const SizedBox(height: 12),
          Text('Main Roles', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          _MainRoleTile(
            label: 'primary / onPrimary',
            bg: colors.primary,
            fg: colors.onPrimary,
          ),
          _MainRoleTile(
            label: 'secondary / onSecondary',
            bg: colors.secondary,
            fg: colors.onSecondary,
          ),
          const SizedBox(height: 12),
          Text(l10n.library, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Stack(
            children: [
              Positioned(
                right: -5,
                bottom: -25,
                child: SvgPicture.asset(
                  'assets/logos/nh_colored_white.svg',
                  colorFilter: ColorFilter.mode(
                    colors.surfaceTint,
                    BlendMode.srcIn,
                  ),
                  height: 120,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.surfaceContainerLowest),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        spacing: 2.0,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TITLE
                          Text(
                            'Song Title',
                            style: theme.textTheme.titleMedium,
                          ),

                          // INFO
                          Row(
                            spacing: 16.0,
                            children: [
                              Text(
                                '${AppLocalizations.of(context)!.musicKey}: C',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.bpmWithPlaceholder('120'),
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.durationWithPlaceholder('3:45'),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const CloudDownloadIndicator(),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.cloud_download),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: Stack(
              children: [
                // CLOUD WATERMARK
                Positioned(
                  right: -20,
                  bottom: -50,
                  child: Icon(
                    Icons.cloud,
                    size: 250,
                    color: colors.surfaceTint,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colors.surfaceContainerLowest,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // SCHEDULE NAME
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    Text(
                                      'Schedule Name',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    StatusChip(
                                      schedule: Schedule(
                                        id: -1,
                                        ownerFirebaseId: '',
                                        name: '',
                                        date: DateTime.now(),
                                        location: '',
                                        playlistId: -1,
                                        roles: [],
                                        shareCode: '',
                                      ),
                                    ),
                                  ],
                                ),

                                // WHEN & WHERE
                                Wrap(
                                  spacing: 16.0,
                                  children: [
                                    Text(
                                      '10/10/2024',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      '10:00 AM',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      'Location',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),

                                // PLAYLIST INFO
                                Text(
                                  '${AppLocalizations.of(context)!.playlist}: Playlist Name',
                                  style: theme.textTheme.bodyMedium,
                                ),

                                // YOUR ROLE INFO
                                Text(
                                  '${AppLocalizations.of(context)!.role}: Musician',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const CloudDownloadIndicator(),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.more_vert),
                          ),
                        ],
                      ),

                      // BOTTOM BUTTONS
                      FilledTextButton(
                        isDark: true,
                        isDense: true,
                        onPressed: () {},
                        text: AppLocalizations.of(context)!.play,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildAssetsPreview(context),
        ],
      ),
    );
  }
}

class _SurfaceTile extends StatelessWidget {
  final String label;
  final Color color;

  const _SurfaceTile({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '#${color.toARGB32().toRadixString(16).toUpperCase()}',
            style: TextStyle(color: onSurface),
          ),
        ],
      ),
    );
  }
}

class _MainRoleTile extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _MainRoleTile({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '#${bg.toARGB32().toRadixString(16).toUpperCase()}',
            style: TextStyle(color: fg),
          ),
        ],
      ),
    );
  }
}
