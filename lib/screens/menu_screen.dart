import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import 'menu/settings_screen.dart'; // import the new settings screen
import 'menu/bookmarks_screen.dart';
import 'menu/edit_profile_screen.dart';
import 'menu/bylaws_screen.dart';
import 'menu/centers_screen.dart';
import 'forms/create_post_screen.dart';
import 'forms/submit_song_screen.dart';
import 'menu/contact_us_screen.dart';
import 'menu/terms_agreements_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset('assets/images/image.png'),
        ),
        title: const Text('Menu'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // User Profile Card
          _buildFormGroup(
            context: context,
            surfaceColor: surfaceColor,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    SettingsProvider.avatarIcons[settings.avatarIndex %
                        SettingsProvider.avatarIcons.length],
                    size: 32,
                    color: primaryColor,
                  ),
                ),
                title: Text(
                  settings.nickname,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  settings.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: textColor.withValues(alpha: 0.3),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildFormGroup(
            context: context,
            surfaceColor: surfaceColor,
            children: [
              ListTile(
                leading: Icon(Icons.bookmark_outline, color: textColor),
                title: Text(
                  'Bookmarks',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookmarksScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.location_on_outlined, color: textColor),
                title: Text(
                  'Centers',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CentersScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.gavel_outlined, color: textColor),
                title: Text(
                  'ByLaws',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BylawsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildFormGroup(
            context: context,
            surfaceColor: surfaceColor,
            children: [
              ListTile(
                leading: Icon(Icons.post_add_outlined, color: textColor),
                title: Text(
                  'Create Post',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePostScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.queue_music_outlined, color: textColor),
                title: Text(
                  'Submit Song',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubmitSongScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildFormGroup(
            context: context,
            surfaceColor: surfaceColor,
            children: [
              ListTile(
                leading: Icon(Icons.description_outlined, color: textColor),
                title: Text(
                  'Terms and Agreements',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsAgreementsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.contact_support_outlined, color: textColor),
                title: Text(
                  'Contact Us',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactUsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildFormGroup(
            context: context,
            surfaceColor: surfaceColor,
            children: [
              ListTile(
                leading: Icon(Icons.settings_outlined, color: textColor),
                title: Text(
                  'Settings',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.facebook_outlined, color: primaryColor),
                title: Text(
                  'Follow us on Facebook',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
                onTap: () async {
                  final Uri url = Uri.parse(
                    'https://www.facebook.com/profile.php?id=61582048631893',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
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
}
