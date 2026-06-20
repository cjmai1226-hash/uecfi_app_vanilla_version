import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/chatgpt_design_system.dart';

class SubmitSongScreen extends StatefulWidget {
  const SubmitSongScreen({super.key});

  @override
  State<SubmitSongScreen> createState() => _SubmitSongScreenState();
}

class _SubmitSongScreenState extends State<SubmitSongScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submitSong() {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Title and Content are required'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    AdService().showRewardedAdDialog(
      context: context,
      title: 'Submit Song',
      content: 'Watch a short ad to submit your song?',
      onReward: () => _executeSubmitSong(),
    );
  }

  Future<void> _executeSubmitSong() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final settings = context.read<SettingsProvider>();

      await FirestoreService().submitSongSuggestion(
        title: _titleController.text,
        author: _authorController.text,
        category: _categoryController.text,
        lyrics: _contentController.text,
        chords: '',
        submittedByEmail: settings.email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song submitted for review!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit song: $e'),
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

    return Scaffold(
      appBar: const MainAppBar(
        title: 'Submit Song',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChatGPTTextField(
              controller: _titleController,
              label: 'Song Title',
              icon: Icons.music_note_rounded,
            ),
            ChatGPTTextField(
              controller: _authorController,
              label: 'Author / Composer',
              icon: Icons.person_rounded,
            ),
            ChatGPTTextField(
              controller: _categoryController,
              label: 'Category (e.g. Worship)',
              icon: Icons.category_rounded,
            ),
            ChatGPTTextField(
              controller: _contentController,
              label: 'Lyrics',
              hintText: 'Lyrics here...',
              icon: Icons.text_fields_rounded,
              maxLines: 12,
              style: GoogleFonts.robotoMono(fontSize: 14, fontWeight: FontWeight.w500),
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
                      'Note: Your submission will be reviewed by administrators before being added to the database.',
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
              onPressed: _isSubmitting ? null : _submitSong,
              isLoading: _isSubmitting,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Submit Song',
                    style: TextStyle(
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
    );
  }
}
