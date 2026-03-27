import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/ad_service.dart';

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
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Title and Content are required'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

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

  Widget _buildModernField(
    TextEditingController controller,
    String label,
    IconData icon,
    Color textColor, {
    int maxLines = 1,
    bool useMonospace = false,
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
          fontFamily: useMonospace ? 'monospace' : null,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
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
        title: const Text('Submit Song'),
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
                  onPressed: _submitSong,
                  child: Text(
                    'Submit',
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
                    'Song Title',
                    Icons.music_note_rounded,
                    textColor,
                  ),
                  _buildModernField(
                    _authorController,
                    'Author / Composer',
                    Icons.person_outline_rounded,
                    textColor,
                  ),
                  _buildModernField(
                    _categoryController,
                    'Category (e.g. Worship, Praise)',
                    Icons.category_outlined,
                    textColor,
                  ),
                  _buildModernField(
                    _contentController,
                    'Lyrics here...',
                    Icons.lyrics_outlined,
                    textColor,
                    maxLines: 15,
                    useMonospace: true,
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
