import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ad_service.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final List<Color> _colorChoices = const [
    Colors.blueAccent,
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
    Color surfaceColor,
    Color textColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 24.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'Choose Color Seed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Center(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
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
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: textColor, width: 3)
                                : null,
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Appearance Group
          _buildFormGroup(
            context: context,
            surfaceColor: surfaceColor,
            children: [
              _buildSwitchTile(
                title: 'Dark Mode',
                icon: Icons.dark_mode_outlined,
                value: settings.isDarkMode,
                onChanged: (val) =>
                    context.read<SettingsProvider>().toggleDarkMode(val),
                textColor: textColor,
                seedColor: settings.colorSeed,
              ),
              _buildColorSeedTile(
                context: context,
                textColor: textColor,
                surfaceColor: surfaceColor,
                currentColor: settings.colorSeed,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Typography Group
          _buildFormGroup(
            context: context,
            surfaceColor: surfaceColor,
            children: [
              _buildDropdownTile(
                title: 'Font Style',
                icon: Icons.font_download_outlined,
                value: settings.fontStyle,
                items: ['Inter', 'Roboto', 'Open Sans', 'System'],
                onChanged: (val) =>
                    context.read<SettingsProvider>().updateFontStyle(val!),
                textColor: textColor,
              ),
              _buildSliderTile(
                title: 'Font Size',
                icon: Icons.format_size_outlined,
                value: settings.fontSize,
                min: 12.0,
                max: 30.0,
                onChanged: (val) =>
                    context.read<SettingsProvider>().updateFontSize(val),
                textColor: textColor,
                seedColor: settings.colorSeed,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // App Preferences Group
          _buildFormGroup(
            context: context,
            surfaceColor: surfaceColor,
            children: [
              _buildDropdownTile(
                title: 'Prayer Language',
                icon: Icons.language_outlined,
                value: settings.prayerLanguage,
                items: ['Ilocano', 'Tagalog'],
                onChanged: (val) =>
                    context.read<SettingsProvider>().updatePrayerLanguage(val!),
                textColor: textColor,
              ),
              _buildSwitchTile(
                title: 'Show Chords',
                icon: Icons.music_note_outlined,
                value: settings.showChords,
                onChanged: (val) {
                  if (val) {
                    AdService().showRewardedAdDialog(
                      context: context,
                      title: 'Enable Show Chords',
                      content: 'Watch a short ad to unlock chord views?',
                      onReward: () {
                        context.read<SettingsProvider>().toggleShowChords(true);
                      },
                    );
                  } else {
                    context.read<SettingsProvider>().toggleShowChords(false);
                  }
                },
                textColor: textColor,
                seedColor: settings.colorSeed,
              ),
              _buildSwitchTile(
                title: 'Chord Shapes',
                icon: Icons.grid_view_outlined,
                value: settings.showChordShapes,
                onChanged: (val) {
                  if (!settings.showChords) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enable Show Chords first'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  context.read<SettingsProvider>().toggleShowChordShapes(val);
                },
                textColor: settings.showChords
                    ? textColor
                    : textColor.withValues(alpha: 0.5),
                seedColor: settings.colorSeed,
              ),
              _buildDropdownTile(
                title: 'Chord Instrument',
                icon: Icons.music_note_outlined,
                value: settings.chordInstrument,
                items: ['Guitar', 'Ukulele'],
                onChanged: (val) => context
                    .read<SettingsProvider>()
                    .updateChordInstrument(val!),
                textColor: textColor,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // About Group
          _buildFormGroup(
            context: context,
            surfaceColor: surfaceColor,
            children: [
              _buildActionTile(
                title: 'Rate this app',
                icon: Icons.star_outline,
                iconColor: Colors.amber,
                onTap: () async {
                  final InAppReview inAppReview = InAppReview.instance;
                  if (await inAppReview.isAvailable()) {
                    inAppReview.requestReview();
                  } else {
                    // Fallback to store page if native dialog is unavailable
                    inAppReview.openStoreListing(
                      appStoreId: 'replace_with_your_ios_app_id',
                    );
                  }
                },
                textColor: textColor,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Vanilla 1.0.0',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFormGroup({
    required BuildContext context,
    required List<Widget> children,
    required Color surfaceColor,
  }) {
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: ListTile.divideTiles(
          context: context,
          tiles: children,
        ).toList(),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color seedColor,
  }) {
    return _buildBaseTile(
      title: title,
      icon: icon,
      trailing: Switch(
        value: value,
        activeThumbColor: seedColor,
        activeTrackColor: seedColor.withValues(alpha: 0.5),
        onChanged: onChanged,
      ),
      textColor: textColor,
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Color textColor,
  }) {
    return _buildBaseTile(
      title: title,
      icon: icon,
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        dropdownColor: textColor == Colors.white
            ? Colors.grey[850]
            : Colors.white,
        icon: const Icon(Icons.unfold_more, color: Colors.grey),
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: TextStyle(fontSize: 14, color: textColor)),
          );
        }).toList(),
      ),
      textColor: textColor,
    );
  }

  Widget _buildSliderTile({
    required String title,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required Color textColor,
    required Color seedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(fontSize: 16, color: textColor)),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: seedColor,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 24, // Keeps the row from jittering while sliding numbers
            child: Text(
              '${value.toInt()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSeedTile({
    required BuildContext context,
    required Color textColor,
    required Color surfaceColor,
    required Color currentColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(Icons.color_lens_outlined, color: textColor),
      title: Text(
        'Color Seed',
        style: TextStyle(fontSize: 16, color: textColor),
      ),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: currentColor, shape: BoxShape.circle),
      ),
      onTap: () => _showColorPickerBottomSheet(
        context,
        currentColor,
        surfaceColor,
        textColor,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color textColor,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: iconColor ?? textColor),
      title: Text(title, style: TextStyle(fontSize: 16, color: textColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildBaseTile({
    required String title,
    required IconData icon,
    required Widget trailing,
    required Color textColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(fontSize: 16, color: textColor)),
      trailing: trailing,
    );
  }
}
