import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ad_service.dart';
import '../../providers/settings_provider.dart';
import '../../utils/color_utils.dart';
import '../../widgets/main_app_bar.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final List<Color> _colorChoices = const [
    Colors.blueAccent,
    Color(0xFF007FFF), // Azure Blue
    Colors.redAccent,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  void _showColorPickerBottomSheet(
    BuildContext context,
    Color currentColor,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Theme Color',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick a color to personalize your application experience.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: _colorChoices.map((color) {
                      final isSelected =
                          currentColor.toARGB32() == color.toARGB32();
                      return GestureDetector(
                        onTap: () {
                          context.read<SettingsProvider>().updateColorSeed(
                            color,
                          );
                          Navigator.pop(ctx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: colorScheme.onSurface,
                                    width: 4,
                                  )
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      spreadRadius: 4,
                                    ),
                                  ]
                                : [],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: colorScheme.onSurface,
                                  size: 32,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const MainAppBar(title: 'Settings', showBackButton: true),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _buildProfileHeader(context, settings, colorScheme),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Appearance', colorScheme),
                  _buildSettingsCard(
                    context,
                    children: [
                      _buildSwitchTile(
                        title: 'Dark Mode',
                        subtitle:
                            'Use a darker color palette for a more comfortable night-time experience',
                        icon: Icons.dark_mode_rounded,
                        value: settings.isDarkMode,
                        onChanged: (val) => context
                            .read<SettingsProvider>()
                            .toggleDarkMode(val),
                        colorScheme: colorScheme,
                        seedColor: settings.colorSeed,
                      ),
                      _buildColorSeedTile(
                        context: context,
                        colorScheme: colorScheme,
                        currentColor: settings.colorSeed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Typography', colorScheme),
                  _buildSettingsCard(
                    context,
                    children: [
                      _buildDropdownTile(
                        title: 'Font Style',
                        subtitle:
                            'Choose your preferred typeface for the entire application',
                        icon: Icons.font_download_rounded,
                        value: settings.fontStyle,
                        items: ['Inter', 'Roboto', 'Open Sans', 'System'],
                        onChanged: (val) => context
                            .read<SettingsProvider>()
                            .updateFontStyle(val!),
                        colorScheme: colorScheme,
                      ),
                      _buildSliderTile(
                        title: 'Font Size',
                        subtitle:
                            'Adjust the text scale to improve readability across all screens',
                        icon: Icons.format_size_rounded,
                        value: settings.fontSize,
                        min: 12.0,
                        max: 30.0,
                        onChanged: (val) => context
                            .read<SettingsProvider>()
                            .updateFontSize(val),
                        colorScheme: colorScheme,
                        seedColor: settings.colorSeed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('App Preferences', colorScheme),
                  _buildSettingsCard(
                    context,
                    children: [
                      _buildDropdownTile(
                        title: 'Prayer Language',
                        subtitle:
                            'Select the primary language for prayers and religious content',
                        icon: Icons.language_rounded,
                        value: settings.prayerLanguage,
                        items: ['Ilocano', 'Tagalog'],
                        onChanged: (val) => context
                            .read<SettingsProvider>()
                            .updatePrayerLanguage(val!),
                        colorScheme: colorScheme,
                      ),
                      _buildSwitchTile(
                        title: 'Show Chords',
                        subtitle:
                            'Enable interactive chord views for songs and hymns',
                        icon: Icons.music_note_rounded,
                        value: settings.showChords,
                        onChanged: (val) {
                          if (val) {
                            AdService().showRewardedAdDialog(
                              context: context,
                              title: 'Enable Show Chords',
                              content:
                                  'Watch a short ad to unlock chord views?',
                              onReward: () => context
                                  .read<SettingsProvider>()
                                  .toggleShowChords(true),
                            );
                          } else {
                            context.read<SettingsProvider>().toggleShowChords(
                              false,
                            );
                          }
                        },
                        colorScheme: colorScheme,
                        seedColor: settings.colorSeed,
                      ),
                      _buildSwitchTile(
                        title: 'Chord Shapes',
                        subtitle:
                            'Display visual finger positions for the selected instrument',
                        icon: Icons.grid_view_rounded,
                        value: settings.showChordShapes,
                        onChanged: (val) {
                          if (!settings.showChords) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enable Show Chords first',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          context
                              .read<SettingsProvider>()
                              .toggleShowChordShapes(val);
                        },
                        colorScheme: colorScheme,
                        seedColor: settings.colorSeed,
                        isEnabled: settings.showChords,
                      ),
                      _buildDropdownTile(
                        title: 'Chord Instrument',
                        subtitle:
                            'Choose between Guitar or Ukulele for chord diagrams',
                        icon: Icons.music_note_rounded,
                        value: settings.chordInstrument,
                        items: ['Guitar', 'Ukulele'],
                        onChanged: (val) => context
                            .read<SettingsProvider>()
                            .updateChordInstrument(val!),
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildSystemInfo(colorScheme),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    SettingsProvider settings,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: ColorUtils.getAvatarColor(settings.nickname),
              child: Text(
                settings.nickname.isNotEmpty
                    ? settings.nickname[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.nickname,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    settings.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () {}, // This could link to profile edit if needed
              icon: const Icon(Icons.qr_code_2_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfo(ColorScheme colorScheme) {
    return Column(
      children: [
        const Divider(height: 1),
        const SizedBox(height: 24),
        Text(
          'UECFI App',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Version 2.4.0 • Build 2026',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '© 2026 DevChristian. All rights reserved.',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
    required Color seedColor,
    bool isEnabled = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled
              ? colorScheme.primaryContainer.withValues(alpha: 0.4)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isEnabled
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isEnabled
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
          height: 1.3,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeTrackColor: seedColor,
        onChanged: isEnabled ? onChanged : null,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
          height: 1.3,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          dropdownColor: colorScheme.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.primary,
            size: 18,
          ),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required ColorScheme colorScheme,
    required Color seedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: seedColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildColorSeedTile({
    required BuildContext context,
    required ColorScheme colorScheme,
    required Color currentColor,
  }) {
    return ListTile(
      leading: Icon(Icons.palette_rounded, color: colorScheme.primary),
      title: const Text(
        'Theme Color',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outlineVariant, width: 2),
        ),
      ),
      onTap: () =>
          _showColorPickerBottomSheet(context, currentColor, colorScheme),
    );
  }
}
