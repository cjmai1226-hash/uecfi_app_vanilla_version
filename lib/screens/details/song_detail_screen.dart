import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/settings_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../widgets/chord_diagram.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/chatgpt_design_system.dart';

class SongDetailScreen extends StatefulWidget {
  final Map<String, dynamic> song;

  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  bool _isChordsView = false;
  int _transposeOffset = 0;
  bool _isProjectMode = false;

  void _showChordShapeDialog(String chord, String instrument) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: colorScheme.surface,
          title: Text(
            '$chord ($instrument)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: ChordDiagram(instrument: instrument, chordName: chord),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  String _transposeChord(String chord, int steps) {
    if (steps == 0) return chord;

    final List<String> notes = [
      'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
    ];
    final Map<String, String> flatsToSharps = {
      'Db': 'C#', 'Eb': 'D#', 'Gb': 'F#', 'Ab': 'G#', 'Bb': 'A#',
    };

    final match = RegExp(r'^([A-G][#b]?)(.*)$').firstMatch(chord);
    if (match == null) return chord;

    String root = match.group(1)!;
    String suffix = match.group(2)!;

    if (flatsToSharps.containsKey(root)) {
      root = flatsToSharps[root]!;
    }

    int index = notes.indexOf(root);
    if (index == -1) return chord;

    int newIndex = (index + steps) % 12;
    if (newIndex < 0) newIndex += 12;

    String newRoot = notes[newIndex];

    if (suffix.contains('/')) {
      final slashParts = suffix.split('/');
      if (slashParts.length == 2) {
        String bassNote = slashParts[1];
        String transposedBass = _transposeChord(bassNote, steps);
        suffix = '${slashParts[0]}/$transposedBass';
      }
    }

    return '$newRoot$suffix';
  }

  List<TextSpan> _buildParsedSpans(
    String text,
    Color textColor,
    Color primaryColor,
    double fontSize,
    SettingsProvider settings, {
    bool useMonoFont = false,
  }) {
    final showChords = settings.showChords;
    final showChordShapes = settings.showChordShapes;
    final instrument = settings.chordInstrument;
    final processedText = text.replaceAll('\t', '    ');

    final wordsToBold = [
      'Repeat Coro', 'Repeat Chorus', 'Repeat Koro',
      'Coro', 'Chorus', 'Koro',
    ];

    final voicePattern = RegExp(
      r'(' + wordsToBold.join('|') + r')',
      caseSensitive: false,
    );

    final chordPattern = RegExp(r'(\S+)');
    final List<TextSpan> spans = [];
    final lines = processedText.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      final trimmed = line.trim();

      if (trimmed.startsWith('>')) {
        final gtIndex = line.indexOf('>');
        final prefix = line.substring(0, gtIndex);
        final content = line.substring(gtIndex + 1);

        if (prefix.isNotEmpty) {
          spans.add(
            TextSpan(
              text: prefix,
              style: useMonoFont
                  ? GoogleFonts.robotoMono(color: textColor.withValues(alpha: 0.5), fontSize: fontSize)
                  : TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: fontSize),
            ),
          );
        }

        content.splitMapJoin(
          chordPattern,
          onMatch: (Match m) {
            String chordText = m.group(0)!;
            if (_isChordsView && showChords && _transposeOffset != 0) {
              chordText = chordText
                  .split(' ')
                  .map((c) => _transposeChord(c, _transposeOffset))
                  .join(' ');
            }

            final chordStyle = useMonoFont
                ? GoogleFonts.robotoMono(
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    fontSize: fontSize,
                  )
                : TextStyle(
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    fontSize: fontSize,
                  );

            if (_isChordsView && showChords && showChordShapes && !_isProjectMode) {
              spans.add(
                TextSpan(
                  text: chordText,
                  style: chordStyle,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      _showChordShapeDialog(chordText, instrument);
                    },
                ),
              );
            } else {
              spans.add(TextSpan(text: chordText, style: chordStyle));
            }
            return '';
          },
          onNonMatch: (String n) {
            spans.add(
              TextSpan(
                text: n,
                style: useMonoFont
                    ? GoogleFonts.robotoMono(color: textColor, fontSize: fontSize)
                    : TextStyle(color: textColor, fontSize: fontSize),
              ),
            );
            return '';
          },
        );
      } else {
        line.splitMapJoin(
          voicePattern,
          onMatch: (Match m) {
            spans.add(
              TextSpan(
                text: m.group(0),
                style: useMonoFont
                    ? GoogleFonts.robotoMono(
                        fontWeight: FontWeight.w800,
                        color: textColor.withValues(alpha: 0.8),
                        fontSize: fontSize,
                        letterSpacing: 0.5,
                      )
                    : TextStyle(
                        fontWeight: FontWeight.w800,
                        color: textColor.withValues(alpha: 0.8),
                        fontSize: fontSize,
                        letterSpacing: 0.5,
                      ),
              ),
            );
            return '';
          },
          onNonMatch: (String n) {
            spans.add(
              TextSpan(
                text: n,
                style: useMonoFont
                    ? GoogleFonts.robotoMono(color: textColor, fontSize: fontSize, height: 1.5)
                    : TextStyle(color: textColor, fontSize: fontSize, height: 1.5),
              ),
            );
            return '';
          },
        );
      }
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final bookmarks = context.watch<BookmarkProvider>();

    final title = widget.song['title'] ?? 'Untitled';
    final lyricsContent =
        widget.song['content'] ??
        widget.song['lyrics'] ??
        'No lyrics available';
    final chordsContent = widget.song['chords'] ?? 'No chords available';
    final hasChords = widget.song['chords'] != null &&
        widget.song['chords'].toString().trim().isNotEmpty &&
        widget.song['chords'].toString() != 'No chords available';
    final category = widget.song['category'] ?? 'Uncategorized';
    final author = widget.song['author'] ?? 'N/A';

    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;
    final primaryColor = colorScheme.primary;

    final displayContent = (_isChordsView && settings.showChords)
        ? chordsContent
        : lyricsContent;
    final isBookmarked = bookmarks.isBookmarked(title.toString());

    return Scaffold(
      appBar: _isProjectMode
          ? null
          : MainAppBar(
              title: 'Song Detail',
              showBackButton: true,
              actions: [
                if (settings.showChords && hasChords && _isChordsView)
                  _buildCompactTransposeControl(colorScheme),
              ],
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: _isProjectMode
              ? const EdgeInsets.symmetric(horizontal: 40, vertical: 64)
              : const EdgeInsets.fromLTRB(24, 24, 24, 48),
          child: Column(
            crossAxisAlignment: _isProjectMode
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (!_isProjectMode) ...[
                // Category & Meta Row
                Row(
                  children: [
                    ChatGPTTag(
                      label: category.toString().toUpperCase(),
                      fontSize: 9,
                    ),
                    const SizedBox(width: 8),
                    if (author.toString() != 'N/A')
                      Expanded(
                        child: Text(
                          'by ${author.toString()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  title.toString(),
                  style: TextStyle(
                    fontSize: settings.fontSize * 1.8,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 32),
              ],
              // Content Container
              Container(
                width: double.infinity,
                padding: _isProjectMode ? const EdgeInsets.all(8.0) : EdgeInsets.zero,
                child: RichText(
                  textAlign: (_isProjectMode && !(_isChordsView && settings.showChords))
                      ? TextAlign.center
                      : TextAlign.left,
                  text: TextSpan(
                    style: (_isChordsView && settings.showChords)
                        ? GoogleFonts.robotoMono(height: 1.5)
                        : const TextStyle(height: 1.6),
                    children: _buildParsedSpans(
                      displayContent.toString(),
                      textColor,
                      primaryColor,
                      _isProjectMode
                          ? settings.fontSize * 2.8
                          : settings.fontSize * 1.05,
                      settings,
                      useMonoFont: _isChordsView && settings.showChords,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isProjectMode
          ? null
          : BottomAppBar(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (settings.showChords) ...[
                      FilledButton.icon(
                        onPressed: hasChords
                            ? () {
                                setState(() {
                                  _isChordsView = !_isChordsView;
                                  if (!_isChordsView) _transposeOffset = 0;
                                });
                              }
                            : null,
                        icon: Icon(
                          _isChordsView
                              ? Icons.notes_rounded
                              : Icons.music_note_rounded,
                        ),
                        label: Text(_isChordsView ? 'Lyrics' : 'Chords'),
                        style: FilledButton.styleFrom(
                          shape: const StadiumBorder(),
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F0F0F),
                          foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F0F0F) : Colors.white,
                          disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          disabledForegroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      tooltip: isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_add_outlined,
                        color: isBookmarked ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white) : null,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: isBookmarked
                            ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F0F0F))
                            : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D2D2D) : const Color(0xFFEFEFEF)),
                        foregroundColor: isBookmarked
                            ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)
                            : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                      ),
                      onPressed: () {
                        context.read<BookmarkProvider>().toggleBookmark(
                              title.toString(),
                            );
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isBookmarked
                                  ? 'Removed Bookmark'
                                  : 'Added to Bookmarks',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    IconButton(
                      tooltip: 'Projector Mode',
                      icon: const Icon(Icons.cast_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D2D2D) : const Color(0xFFEFEFEF),
                        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => setState(() => _isProjectMode = true),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: _isProjectMode
          ? FloatingActionButton.large(
              heroTag: 'song_project_exit',
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F0F0F),
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F0F0F) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              onPressed: () => setState(() => _isProjectMode = false),
              child: const Icon(Icons.close_rounded),
            )
          : null,
    );
  }

  Widget _buildCompactTransposeControl(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_rounded, size: 16),
          onPressed: _transposeOffset > -6 ? () => setState(() => _transposeOffset--) : null,
          style: IconButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEFEFEF),
            foregroundColor: isDark ? Colors.white : Colors.black,
            disabledBackgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            disabledForegroundColor: isDark ? Colors.white24 : Colors.black26,
          ),
        ),
        SizedBox(
          width: 32,
          child: Center(
            child: Text(
              _transposeOffset > 0 ? '+$_transposeOffset' : '$_transposeOffset',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_rounded, size: 16),
          onPressed: _transposeOffset < 6 ? () => setState(() => _transposeOffset++) : null,
          style: IconButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEFEFEF),
            foregroundColor: isDark ? Colors.white : Colors.black,
            disabledBackgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            disabledForegroundColor: isDark ? Colors.white24 : Colors.black26,
          ),
        ),
      ],
    );
  }


}
