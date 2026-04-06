import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../screens/menu/settings_screen.dart';
import '../screens/menu/bookmarks_screen.dart';
import '../screens/forms/submit_song_screen.dart';
import '../screens/menu/help_feedback_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onSelectNavigation,
  });

  final int currentIndex;
  final ValueChanged<int> onSelectNavigation;

  Future<void> _handleRateApp(BuildContext context) async {
    final InAppReview inAppReview = InAppReview.instance;
    final messenger = ScaffoldMessenger.of(context);

    // Provide immediate visual feedback
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Opening Rating Dialog...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing(
          // Replace with your real iOS App Store ID if applicable
          appStoreId: 'replace_with_your_ios_app_id',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open rating: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.60,
      child: Column(
        children: [
          // ── Scrollable Menu Content ─────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 12,
                right: 12,
                bottom: 8,
              ),
              children: [
                _buildSectionLabel(context, 'MENU'),
                _DrawerTile(
                  icon: currentIndex == 0
                      ? Icons.home_rounded
                      : Icons.home_outlined,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectNavigation(0);
                  },
                ),
                _DrawerTile(
                  icon: currentIndex == 1
                      ? Icons.menu_book_rounded
                      : Icons.menu_book_outlined,
                  label: 'Prayers',
                  isSelected: currentIndex == 1,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectNavigation(1);
                  },
                ),
                _DrawerTile(
                  icon: currentIndex == 2
                      ? Icons.music_note_rounded
                      : Icons.music_note_outlined,
                  label: 'Songs',
                  isSelected: currentIndex == 2,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectNavigation(2);
                  },
                ),
                _DrawerTile(
                  icon: currentIndex == 3
                      ? Icons.location_on_rounded
                      : Icons.location_on_outlined,
                  label: 'Centers',
                  isSelected: currentIndex == 3,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectNavigation(3);
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Divider(),
                ),

                _buildSectionLabel(context, 'TOOLS & CONTENT'),
                _DrawerTile(
                  icon: Icons.bookmarks_outlined,
                  label: 'Bookmarks',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BookmarksScreen(),
                      ),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.queue_music_rounded,
                  label: 'Submit Song',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubmitSongScreen(),
                      ),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.star_outline_rounded,
                  label: 'Rate this app',
                  onTap: () => _handleRateApp(context),
                ),
                _DrawerTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Feedback',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpFeedbackScreen(),
                      ),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Fixed Footer ───────────────────────────────────────────
          _buildFixedFooter(context),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildFixedFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UECFI App',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                'Alrights Reserved 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
