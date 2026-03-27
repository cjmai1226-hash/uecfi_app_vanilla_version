import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/prayers_screen.dart';
import '../screens/songs_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/search_screen.dart'; // Import search screen

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PrayersScreen(),
    SongsScreen(),
    MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Detect screen width for responsive layout
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Row(
        children: [
          if (!isSmallScreen)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                child: FloatingActionButton(
                  elevation: 0,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    );
                  },
                  child: const Icon(Icons.search),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: Text('Prayers'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.music_note_outlined),
                  selectedIcon: Icon(Icons.music_note),
                  label: Text('Songs'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_rounded),
                  selectedIcon: Icon(Icons.menu),
                  label: Text('Menu'),
                ),
              ],
            ),
          if (!isSmallScreen)
            const VerticalDivider(thickness: 1, width: 1),
            
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isSmallScreen
          ? NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Prayers',
                ),
                NavigationDestination(
                  icon: Icon(Icons.music_note_outlined),
                  selectedIcon: Icon(Icons.music_note),
                  label: 'Songs',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_rounded),
                  selectedIcon: Icon(Icons.menu),
                  label: 'Menu',
                ),
              ],
            )
          : null,
      floatingActionButton: isSmallScreen
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: const Icon(Icons.search),
            )
          : null,
    );
  }
}
