import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/home_screen.dart';
import '../screens/prayers_screen.dart';
import '../screens/songs_screen.dart';
import '../screens/menu/centers_screen.dart';
import '../widgets/app_drawer.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
      PrayersScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      SongsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
      CentersScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. If we are not on Home (index 0), go back to Home
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        // 2. If we ARE on Home, show the exit confirmation dialog
        final shouldExit = await _showExitDialog(context);
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(
          currentIndex: _currentIndex,
          onSelectNavigation: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        body: IndexedStack(index: _currentIndex, children: screens),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Icon(Icons.logout_rounded, color: colorScheme.primary),
        title: const Text(
          'Exit App?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Do you really want to exit the UECFI App?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
            ),
            child: const Text(
              'Exit',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
