import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/ad_service.dart';
import '../menu/edit_profile_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submitPost() {
    final settings = context.read<SettingsProvider>();
    if (!settings.isProfileSetup) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Account Setup Required'),
          content: const Text(
            'To maintain community trust, please set up your nickname and email in your profile before publishing a post.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
              child: const Text('Go to Profile'),
            ),
          ],
        ),
      );
      return;
    }

    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill out all fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    AdService().showRewardedAdDialog(
      context: context,
      title: 'Publish Post',
      content: 'Watch a short ad to publish your post?',
      onReward: () => _executePublish(),
    );
  }

  Future<void> _executePublish() async {

    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill out all fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final settings = context.read<SettingsProvider>();
      
      await FirestoreService().submitCommunityPost(
        content: '${_titleController.text}\n\n${_contentController.text}',
        authorEmail: settings.email,
        authorNickname: settings.nickname,
        avatarIndex: settings.avatarIndex,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post submitted successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit post: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildModernField(
    TextEditingController controller,
    String label,
    IconData icon,
    Color textColor, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 22),
          filled: true,
          fillColor: textColor.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        centerTitle: true,
        elevation: 0,
        actions: [
          _isSubmitting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _submitPost,
                  child: Text(
                    'Publish',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernField(
                    _titleController,
                    'Post Title',
                    Icons.title_rounded,
                    textColor,
                  ),
                  _buildModernField(
                    _contentController,
                    'What do you want to share?',
                    Icons.edit_note_rounded,
                    textColor,
                    maxLines: 12,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: textColor.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: This post will be automatically deleted after 5 days. This ensures that the community feed is not crowded with old posts.',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


