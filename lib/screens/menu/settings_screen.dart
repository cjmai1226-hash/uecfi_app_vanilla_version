import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ad_service.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/main_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ── Color options ────────────────────────────────────────────────────────────
  static const Map<String, Color> _accentColors = {
    'Default': Colors.blueAccent,
    'Blue': Color(0xFF007FFF),
    'Green': Colors.green,
    'Yellow': Color(0xFFFFCA28),
    'Pink': Colors.pink,
    'Orange': Colors.orange,
  };

  // ── Font size options ────────────────────────────────────────────────────────
  static const Map<String, double> _fontSizes = {
    'Small': 14.0,
    'Medium': 16.0,
    'Large': 18.0,
    'Extra Large': 20.0,
  };

  String _colorName(Color color) {
    for (final e in _accentColors.entries) {
      if (e.value.toARGB32() == color.toARGB32()) return e.key;
    }
    return 'Custom';
  }

  String _fontSizeName(double size) {
    for (final e in _fontSizes.entries) {
      if (e.value == size) return e.key;
    }
    return 'Medium';
  }

  // ── Generic options bottom sheet ─────────────────────────────────────────────
  void _showOptionsSheet(
    BuildContext context, {
    required String title,
    required List<String> items,
    required String selected,
    required void Function(String) onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ...items.map(
                (item) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(
                    item,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selected == item
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: selected == item
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  trailing: selected == item
                      ? Icon(
                          Icons.check_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    onSelected(item);
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Accent color bottom sheet ────────────────────────────────────────────────
  void _showColorSheet(
    BuildContext context,
    Color currentColor,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  'Accent Color',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: _accentColors.entries.map((entry) {
                  final isSelected =
                      entry.value.toARGB32() == currentColor.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      context.read<SettingsProvider>().updateColorSeed(
                        entry.value,
                      );
                      Navigator.pop(ctx);
                    },
                    child: SizedBox(
                      width: 60,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: entry.value,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: colorScheme.onSurface,
                                      width: 3,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: entry.value.withValues(
                                          alpha: 0.45,
                                        ),
                                        blurRadius: 14,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.key,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final colorName = _colorName(settings.colorSeed);
    final fontSizeName = _fontSizeName(settings.fontSize);

    return Scaffold(
      appBar: const MainAppBar(title: 'Settings', showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Appearance ───────────────────────────────────────────────────────
          _buildSectionHeader('Appearance', colorScheme),
          _buildCard(
            context,
            children: [
              _buildChevronTile(
                context,
                icon: Icons.brightness_6_rounded,
                title: 'Appearance',
                subtitle: settings.themeModeLabel,
                colorScheme: colorScheme,
                onTap: () => _showOptionsSheet(
                  context,
                  title: 'Appearance',
                  items: const ['System (Default)', 'Light', 'Dark'],
                  selected: settings.themeModeLabel,
                  onSelected: (v) =>
                      context.read<SettingsProvider>().updateThemeMode(v),
                ),
              ),
              _buildDivider(colorScheme),
              _buildChevronTile(
                context,
                icon: Icons.palette_rounded,
                title: 'Accent Color',
                subtitle: colorName,
                subtitleDot: settings.colorSeed,
                colorScheme: colorScheme,
                onTap: () =>
                    _showColorSheet(context, settings.colorSeed, colorScheme),
              ),
              _buildDivider(colorScheme),
              _buildChevronTile(
                context,
                icon: Icons.format_size_rounded,
                title: 'Font Size',
                subtitle: fontSizeName,
                colorScheme: colorScheme,
                onTap: () => _showOptionsSheet(
                  context,
                  title: 'Font Size',
                  items: const ['Small', 'Medium', 'Large', 'Extra Large'],
                  selected: fontSizeName,
                  onSelected: (v) => context
                      .read<SettingsProvider>()
                      .updateFontSize(_fontSizes[v]!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── App Preferences ──────────────────────────────────────────────────
          _buildSectionHeader('App Preferences', colorScheme),
          _buildCard(
            context,
            children: [
              _buildChevronTile(
                context,
                icon: Icons.language_rounded,
                title: 'Prayer Language',
                subtitle: settings.prayerLanguage,
                colorScheme: colorScheme,
                onTap: () => _showOptionsSheet(
                  context,
                  title: 'Prayer Language',
                  items: const ['Ilocano', 'Tagalog'],
                  selected: settings.prayerLanguage,
                  onSelected: (v) =>
                      context.read<SettingsProvider>().updatePrayerLanguage(v),
                ),
              ),
              _buildDivider(colorScheme),
              _buildSwitchTile(
                context,
                icon: Icons.music_note_rounded,
                title: 'Show Chords',
                colorScheme: colorScheme,
                value: settings.showChords,
                seedColor: settings.colorSeed,
                onChanged: (val) {
                  if (val) {
                    AdService().showRewardedAdDialog(
                      context: context,
                      title: 'Enable Show Chords',
                      content: 'Watch a short ad to unlock chord views?',
                      onReward: () => context
                          .read<SettingsProvider>()
                          .toggleShowChords(true),
                    );
                  } else {
                    context.read<SettingsProvider>().toggleShowChords(false);
                  }
                },
              ),
              _buildDivider(colorScheme),
              _buildSwitchTile(
                context,
                icon: Icons.grid_view_rounded,
                title: 'Chord Shapes',
                colorScheme: colorScheme,
                value: settings.showChordShapes,
                seedColor: settings.colorSeed,
                isEnabled: settings.showChords,
                onChanged: (val) {
                  if (!settings.showChords) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enable Show Chords first'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  context.read<SettingsProvider>().toggleShowChordShapes(val);
                },
              ),
              _buildDivider(colorScheme),
              _buildChevronTile(
                context,
                icon: Icons.music_note_rounded,
                title: 'Chord Instrument',
                subtitle: settings.chordInstrument,
                colorScheme: colorScheme,
                onTap: () => _showOptionsSheet(
                  context,
                  title: 'Chord Instrument',
                  items: const ['Guitar', 'Ukulele'],
                  selected: settings.chordInstrument,
                  onSelected: (v) =>
                      context.read<SettingsProvider>().updateChordInstrument(v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          _buildSystemInfo(colorScheme),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
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

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      indent: 68,
      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }

  Widget _buildChevronTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
    Color? subtitleDot,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitleDot != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: subtitleDot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
        size: 22,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
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
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isEnabled
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeTrackColor: seedColor,
        onChanged: isEnabled ? onChanged : null,
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
          'Version 2.0.2 • Build 35',
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
}
