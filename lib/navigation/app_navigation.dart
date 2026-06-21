import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/home_screen.dart';
import '../screens/prayers_screen.dart';
import '../screens/songs_screen.dart';
import '../screens/menu/centers_screen.dart';
import '../services/ad_service.dart';
import '../widgets/app_drawer.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      PrayersScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      SongsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
      CentersScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Only block back when we're at the root (no pushed routes to pop).
      // When inside a sub-screen (e.g. Settings, Bible) allow the gesture
      // to pop normally — matching the AppBar back button behaviour.
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async {
        // If canPop was true a route was already popped — nothing else to do.
        if (didPop) return;

        // We're at the root. If not on Home, go back to Home tab.
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        // Already on Home — show exit dialog.
        final shouldExit = await _showExitDialog(context);
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: MediaQuery.of(context).viewInsets.bottom > 0
            ? null
            : NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  // Show interstitial at natural tab transitions.
                  // AdService enforces a 60-second cooldown internally.
                  if (index != _currentIndex) {
                    AdService().showInterstitialIfReady();
                  }
                  setState(() {
                    _currentIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.favorite_border_rounded),
                    selectedIcon: Icon(Icons.favorite_rounded),
                    label: 'Prayers',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.music_note_outlined),
                    selectedIcon: Icon(Icons.music_note_rounded),
                    label: 'Songs',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.location_on_outlined),
                    selectedIcon: Icon(Icons.location_on_rounded),
                    label: 'Centers',
                  ),
                ],
              ),
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
