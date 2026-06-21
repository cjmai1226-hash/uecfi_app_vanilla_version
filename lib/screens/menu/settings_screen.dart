import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ad_service.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/chatgpt_design_system.dart';

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

  String _colorName(Color color) {
    for (final e in _accentColors.entries) {
      if (e.value.toARGB32() == color.toARGB32()) return e.key;
    }
    return 'Custom';
  }

  String _fontSizeName(double size) {
    return '${size.round()}';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF171717) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) {
                  final isSelected = selected == item;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(
                        item,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: isDark ? Colors.white : Colors.black,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        onSelected(item);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Font size bottom sheet ──────────────────────────────────────────────────
  void _showFontSizeSheet(BuildContext context, SettingsProvider settings) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF171717) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
            final currentSize = settings.fontSize;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ADJUST FONT SIZE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'A',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: currentSize.clamp(14.0, 26.0),
                            min: 14.0,
                            max: 26.0,
                            divisions: 12,
                            label: _fontSizeName(currentSize),
                            onChanged: (value) {
                              context.read<SettingsProvider>().updateFontSize(value);
                              setModalState(() {});
                            },
                          ),
                        ),
                        Text(
                          'A',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Preview text (${_fontSizeName(currentSize)})',
                        style: TextStyle(
                          fontSize: currentSize,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Accent color bottom sheet ────────────────────────────────────────────────
  void _showColorSheet(
    BuildContext context,
    Color currentColor,
    ColorScheme colorScheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF171717) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Accent Color',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _accentColors.entries.map((entry) {
                  final isSelected = entry.value.toARGB32() == currentColor.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      context.read<SettingsProvider>().updateColorSeed(entry.value);
                      Navigator.pop(ctx);
                    },
                    child: SizedBox(
                      width: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: entry.value,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: isDark ? Colors.white : Colors.black,
                                      width: 3,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: entry.value.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check_rounded,
                                    color: isDark ? Colors.black : Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.key,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ── Appearance ───────────────────────────────────────────────────────
          _buildSectionHeader('Appearance', colorScheme),
          _buildCard(
            context,
            children: [
              _buildChevronTile(
                context,
                icon: Icons.brightness_6_outlined,
                title: 'Appearance',
                subtitle: settings.themeModeLabel,
                colorScheme: colorScheme,
                onTap: () => _showOptionsSheet(
                  context,
                  title: 'Appearance',
                  items: const ['System (Default)', 'Light', 'Dark'],
                  selected: settings.themeModeLabel,
                  onSelected: (v) => context.read<SettingsProvider>().updateThemeMode(v),
                ),
              ),
              _buildDivider(colorScheme),
              _buildChevronTile(
                context,
                icon: Icons.palette_outlined,
                title: 'Accent Color',
                subtitle: colorName,
                subtitleDot: settings.colorSeed,
                colorScheme: colorScheme,
                onTap: () => _showColorSheet(context, settings.colorSeed, colorScheme),
              ),
              _buildDivider(colorScheme),
              _buildChevronTile(
                context,
                icon: Icons.format_size_rounded,
                title: 'Font Size',
                subtitle: fontSizeName,
                colorScheme: colorScheme,
                onTap: () => _showFontSizeSheet(context, settings),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── App Preferences ──────────────────────────────────────────────────
          _buildSectionHeader('App Preferences', colorScheme),
          _buildCard(
            context,
            children: [
              _buildSwitchTile(
                context,
                icon: Icons.notifications_active_outlined,
                title: 'Prayer & Worship Reminders',
                colorScheme: colorScheme,
                value: settings.remindersEnabled,
                seedColor: settings.colorSeed,
                onChanged: (val) {
                  context.read<SettingsProvider>().toggleReminders(val);
                },
              ),
              _buildDivider(colorScheme),

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
                  onSelected: (v) => context.read<SettingsProvider>().updatePrayerLanguage(v),
                ),
              ),
              _buildDivider(colorScheme),
              _buildSwitchTile(
                context,
                icon: Icons.music_note_outlined,
                title: 'Show Chords & Shapes',
                subtitle: 'Displays chord names and diagrams on songs',
                colorScheme: colorScheme,
                value: settings.showChords,
                seedColor: settings.colorSeed,
                onChanged: (val) {
                  if (val) {
                    AdService().showRewardedAdDialog(
                      context: context,
                      title: 'Enable Chords & Shapes',
                      content: 'Watch a short ad to unlock chord views?',
                      onReward: () => context.read<SettingsProvider>().toggleShowChordsAndShapes(true),
                    );
                  } else {
                    context.read<SettingsProvider>().toggleShowChordsAndShapes(false);
                  }
                },
              ),
              _buildDivider(colorScheme),
              _buildChevronTile(
                context,
                icon: Icons.music_note_outlined,
                title: 'Chord Instrument',
                subtitle: settings.chordInstrument,
                colorScheme: colorScheme,
                onTap: () => _showOptionsSheet(
                  context,
                  title: 'Chord Instrument',
                  items: const ['Guitar', 'Ukulele'],
                  selected: settings.chordInstrument,
                  onSelected: (v) => context.read<SettingsProvider>().updateChordInstrument(v),
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
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    return ChatGPTCard(
      child: Column(children: children),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 60,
      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: colorScheme.onSurface, size: 20),
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
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
    String? subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled
              ? (isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEFEFEF))
              : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isEnabled
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          size: 20,
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
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            )
          : null,
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
        const SizedBox(height: 16),
        Text(
          'UECFI App',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Version 2.0.2 • Build 35',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '© 2026 DevChristian. All rights reserved.',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

