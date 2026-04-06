import 'package:flutter/material.dart';
import '../screens/menu/settings_screen.dart';
import '../screens/menu/help_feedback_screen.dart';

class MainAppBarMenu extends StatelessWidget {
  const MainAppBarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        if (value == 'settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        } else if (value == 'help') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HelpFeedbackScreen(),
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'help',
          child: Row(
            children: [
              Icon(Icons.help_outline_rounded, size: 20),
              SizedBox(width: 12),
              Text('Help & Feedback'),
            ],
          ),
        ),
      ],
    );
  }
}
