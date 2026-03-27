import 'package:flutter/material.dart';
import '../../services/ad_service.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/settings_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../widgets/chord_diagram.dart';

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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            '$chord Shape ($instrument)',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 180,
                width: 180,
                child: ChordDiagram(instrument: instrument, chordName: chord),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _transposeChord(String chord, int steps) {
    if (steps == 0) return chord;

    final List<String> notes = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    final Map<String, String> flatsToSharps = {
      'Db': 'C#',
      'Eb': 'D#',
      'Gb': 'F#',
      'Ab': 'G#',
      'Bb': 'A#',
    };

    final match = RegExp(r'^([A-G][#b]?)(.*)$').firstMatch(chord);
    if (match == null) return chord; // Not a recognized chord format root

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
    SettingsProvider settings,
  ) {
    final showChords = settings.showChords;
    final showChordShapes = settings.showChordShapes;
    final instrument = settings.chordInstrument;
    final processedText = text.replaceAll('\t', '    ');

    final wordsToBold = [
      'Repeat Coro',
      'Repeat Chorus',
      'Repeat Koro',
      'Coro',
      'Chorus',
      'Koro',
    ];

    final pattern = RegExp(
      r'\[([^\]]+)\]|(' + wordsToBold.join('|') + r')',
      caseSensitive: false,
    );
    final List<TextSpan> spans = [];

    processedText.splitMapJoin(
      pattern,
      onMatch: (Match m) {
        if (m.group(1) != null) {
          String chordText = m.group(1)!;
          if (_isChordsView && showChords && _transposeOffset != 0) {
            chordText = chordText
                .split(' ')
                .map((c) => _transposeChord(c, _transposeOffset))
                .join(' ');
          }
          if (_isChordsView &&
              showChords &&
              showChordShapes &&
              !_isProjectMode) {
            spans.add(
              TextSpan(
                text: ' $chordText ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: fontSize,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    _showChordShapeDialog(chordText, instrument);
                  },
              ),
            );
          } else {
            spans.add(
              TextSpan(
                text: ' $chordText ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: fontSize,
                ),
              ),
            );
          }
        } else if (m.group(2) != null) {
          spans.add(
            TextSpan(
              text: m.group(2),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: fontSize,
              ),
            ),
          );
        }
        return '';
      },
      onNonMatch: (String n) {
        spans.add(
          TextSpan(
            text: n,
            style: TextStyle(color: textColor, fontSize: fontSize),
          ),
        );
        return '';
      },
    );

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
    final category = widget.song['category'] ?? 'Uncategorized';

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final displayContent = (_isChordsView && settings.showChords)
        ? chordsContent
        : lyricsContent;
    final isBookmarked = bookmarks.isBookmarked(title.toString());

    return Scaffold(
      appBar: AppBar(
        title: Text(_isProjectMode ? 'Projecting' : 'Song Details'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!_isProjectMode)
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? primaryColor : textColor,
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
                          ? 'Removed from Bookmarks'
                          : 'Added to Bookmarks',
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          if (!_isProjectMode)
            IconButton(
              icon: Icon(Icons.info_outline, color: textColor),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: surfaceColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        top: 24.0,
                        bottom: 32.0,
                        left: 16.0,
                        right: 16.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Song Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ListTile(
                            leading: Icon(Icons.category, color: primaryColor),
                            title: const Text('Category'),
                            subtitle: Text(category.toString()),
                          ),
                          ListTile(
                            leading: Icon(Icons.person, color: primaryColor),
                            title: const Text('Composer / Author'),
                            subtitle: const Text('N/A'),
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.calendar_today,
                              color: primaryColor,
                            ),
                            title: const Text('Date Created'),
                            subtitle: Text(
                              widget.song['dateCreated']?.toString() ?? 'N/A',
                            ),
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: primaryColor,
                            ),
                            title: const Text('Origin'),
                            subtitle: const Text('N/A'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: _isProjectMode
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (!_isProjectMode) ...[
                Text(
                  title.toString(),
                  style: TextStyle(
                    fontSize: settings.fontSize * 1.5,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (_isChordsView && settings.showChords)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Transpose: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: primaryColor,
                          onPressed: _transposeOffset > -5
                              ? () => setState(() => _transposeOffset--)
                              : null,
                        ),
                        SizedBox(
                          width: 32,
                          child: Center(
                            child: Text(
                              _transposeOffset > 0
                                  ? '+$_transposeOffset'
                                  : '$_transposeOffset',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: primaryColor,
                          onPressed: _transposeOffset < 5
                              ? () => setState(() => _transposeOffset++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              Container(
                width: double.infinity,
                padding: _isProjectMode
                    ? const EdgeInsets.all(8.0)
                    : EdgeInsets.zero,
                color: Colors.transparent,
                child: RichText(
                  textAlign:
                      (_isProjectMode &&
                          !(_isChordsView && settings.showChords))
                      ? TextAlign.center
                      : TextAlign.left,
                  // Use fixed monospaced font ONLY in chords view to force alignments
                  text: TextSpan(
                    style: (_isChordsView && settings.showChords)
                        ? GoogleFonts.robotoMono(height: 1.5)
                        : const TextStyle(height: 1.5),
                    children: _buildParsedSpans(
                      displayContent.toString(),
                      textColor,
                      primaryColor,
                      _isProjectMode
                          ? settings.fontSize * 2.5
                          : settings.fontSize,
                      settings,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const AdBannerWidget(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: surfaceColor,
        height: 70,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (settings.showChords && !_isProjectMode)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton.icon(
                    icon: Icon(
                      _isChordsView ? Icons.music_note : Icons.notes,
                      color: surfaceColor,
                      size: 18,
                    ),
                    label: Text(
                      _isChordsView ? 'Chords' : 'Lyrics',
                      style: TextStyle(
                        color: surfaceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => setState(() {
                      _isChordsView = !_isChordsView;
                      if (!_isChordsView) _transposeOffset = 0;
                    }),
                  ),
                )
              else
                const SizedBox.shrink(),
              IconButton(
                icon: Icon(
                  _isProjectMode ? Icons.cast_connected : Icons.cast,
                  color: _isProjectMode ? primaryColor : textColor,
                ),
                onPressed: () {
                  setState(() {
                    _isProjectMode = !_isProjectMode;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
