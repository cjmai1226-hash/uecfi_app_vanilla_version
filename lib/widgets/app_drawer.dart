import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_review/in_app_review.dart';
import '../providers/settings_provider.dart';
import '../utils/color_utils.dart';
import '../screens/menu/profile_screen.dart';
import '../screens/menu/settings_screen.dart';
import '../screens/menu/bookmarks_screen.dart';
import '../screens/forms/submit_song_screen.dart';
import '../screens/menu/help_feedback_screen.dart';
import '../screens/menu/bylaws_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
  });

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
    final colorScheme = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.80,
      child: SafeArea(
        child: Column(
          children: [
          // ── Scrollable Menu Content ─────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(
                top: 16,
                left: 12,
                right: 12,
                bottom: 8,
              ),
              children: [
                _buildProfileHeader(context, settings, colorScheme),
                const SizedBox(height: 8),
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
                  icon: Icons.gavel_rounded,
                  label: 'Church Bylaws',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BylawsScreen(),
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
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: ColorUtils.getAvatarColor(settings.nickname),
              child: Text(
                settings.nickname.isNotEmpty
                    ? settings.nickname[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.nickname,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    settings.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () {},
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ],
        ),
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
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
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
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
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
