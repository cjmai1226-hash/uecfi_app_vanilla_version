import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/main_app_bar.dart';

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

  Widget _buildModernField(
    TextEditingController controller,
    String label,
    IconData icon,
    ColorScheme colorScheme, {
    int maxLines = 1,
    bool useMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: useMonospace
            ? GoogleFonts.robotoMono(fontSize: 14, fontWeight: FontWeight.w500)
            : const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: colorScheme.primary, size: 22),
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: MainAppBar(
        title: 'Submit Song',
        showBackButton: true,
        actions: [
          _isSubmitting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton.filledTonal(
                  tooltip: 'Submit',
                  icon: const Icon(Icons.check_rounded, size: 18),
                  onPressed: _submitSong,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModernField(_titleController, 'Song Title', Icons.music_note_rounded, colorScheme),
                _buildModernField(_authorController, 'Author / Composer', Icons.person_rounded, colorScheme),
                _buildModernField(_categoryController, 'Category (e.g. Worship)', Icons.category_rounded, colorScheme),
                _buildModernField(
                  _contentController,
                  'Lyrics here...',
                  Icons.text_fields_rounded,
                  colorScheme,
                  maxLines: 12,
                  useMonospace: true,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Note: Your submission will be reviewed by administrators before being added to the database.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
