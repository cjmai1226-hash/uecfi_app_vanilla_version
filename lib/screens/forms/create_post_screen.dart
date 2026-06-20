import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/ad_service.dart';
import '../menu/profile_screen.dart';
import '../../widgets/chatgpt_design_system.dart';

class CreatePostScreen extends StatefulWidget {
  final Map<String, dynamic>? postToEdit;

  const CreatePostScreen({super.key, this.postToEdit});

  /// Opens the Create/Edit Post as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? postToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePostScreen(postToEdit: postToEdit),
    );
  }

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.postToEdit != null) {
      _contentController.text = widget.postToEdit!['content'] ?? '';
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _submitPost() {
    final settings = context.read<SettingsProvider>();
    if (!settings.isProfileSetup) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text(
            'Account Setup Required',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'To maintain community trust, please set up your nickname and email in your profile before publishing a post.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: const Text(
                'Go to Profile',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter some content for your post'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    AdService().showRewardedAdDialog(
      context: context,
      title: widget.postToEdit != null ? 'Update Post' : 'Publish Post',
      content: widget.postToEdit != null
          ? 'Watch a short ad to update your post?'
          : 'Watch a short ad to publish your post?',
      onReward: () => _executePublish(),
    );
  }

  Future<void> _executePublish() async {
    if (_contentController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final settings = context.read<SettingsProvider>();
      final combinedContent = _contentController.text.trim();

      if (widget.postToEdit != null) {
        await FirestoreService().updateCommunityPost(
          postId: widget.postToEdit!['id'],
          newContent: combinedContent,
          previousContent: widget.postToEdit!['content'],
        );
      } else {
        await FirestoreService().submitCommunityPost(
          content: combinedContent,
          authorEmail: settings.email,
          authorNickname: settings.nickname,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.postToEdit != null
                  ? 'Post updated successfully!'
                  : 'Post submitted successfully!',
            ),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171717) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                ChatGPTTextField(
                  controller: _contentController,
                  label: 'What do you want to share with the community?',
                  maxLines: 8,
                ),
                const SizedBox(height: 8),
                ChatGPTCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Note: This post will be automatically deleted after 5 days to keep the community feed fresh.',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ChatGPTButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  isLoading: _isSubmitting,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.postToEdit != null
                            ? Icons.check_rounded
                            : Icons.send_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.postToEdit != null ? 'Update Post' : 'Publish Post',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
