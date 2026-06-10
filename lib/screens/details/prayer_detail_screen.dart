import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/main_app_bar.dart';

class PrayerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> prayer;
  final List<Map<String, dynamic>>? allPrayers;
  final int? initialIndex;

  const PrayerDetailScreen({
    super.key,
    required this.prayer,
    this.allPrayers,
    this.initialIndex,
  });

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> {
  bool _isProjectMode = false;
  late int _currentIndex;
  late Map<String, dynamic> _currentPrayer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _currentPrayer = widget.prayer;
  }

  bool get _hasList =>
      widget.allPrayers != null && widget.allPrayers!.isNotEmpty;

  bool get _hasPrevious => _hasList && _currentIndex > 0;
  bool get _hasNext =>
      _hasList && _currentIndex < widget.allPrayers!.length - 1;

  void _goToPrevious() {
    if (!_hasPrevious) return;
    setState(() {
      _currentIndex--;
      _currentPrayer = widget.allPrayers![_currentIndex];
    });
  }

  void _goToNext() {
    if (!_hasNext) return;
    setState(() {
      _currentIndex++;
      _currentPrayer = widget.allPrayers![_currentIndex];
    });
  }

  List<TextSpan> _buildParsedSpans(
    String text,
    Color textColor,
    double fontSize,
  ) {
    final pattern = RegExp(r'(Ama Namin|Amami)', caseSensitive: false);
    final List<TextSpan> spans = [];

    text.splitMapJoin(
      pattern,
      onMatch: (Match m) {
        spans.add(
          TextSpan(
            text: m.group(0),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: textColor,
              fontSize: fontSize,
            ),
          ),
        );
        return '';
      },
      onNonMatch: (String n) {
        spans.add(
          TextSpan(
            text: n,
            style: TextStyle(color: textColor, fontSize: fontSize, height: 1.6),
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
    final isTagalog = settings.prayerLanguage == 'Tagalog';

    // Ilocano variables
    final ilocanoTitle = _currentPrayer['title'] ?? 'Untitled';
    final ilocanoContent = _currentPrayer['content'] ?? 'No content available';

    // Tagalog variables
    final tagalogTitle = _currentPrayer['title1'] ?? ilocanoTitle;
    final tagalogContent = _currentPrayer['content1'] ?? ilocanoContent;

    final category = _currentPrayer['category'] ?? 'Uncategorized';

    // Resolving based on global state
    final currentTitle = isTagalog ? tagalogTitle : ilocanoTitle;
    final currentContent = isTagalog ? tagalogContent : ilocanoContent;

    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;
    final primaryColor = colorScheme.primary;

    return Scaffold(
      appBar: _isProjectMode
          ? null
          : MainAppBar(
              title: 'Prayer Detail',
              showBackButton: true,
              actions: [
                IconButton(
                  tooltip: 'Projector Mode',
                  onPressed: () => setState(() => _isProjectMode = true),
                  icon: const Icon(Icons.cast_rounded),
                ),
              ],
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: _isProjectMode
              ? const EdgeInsets.symmetric(horizontal: 32, vertical: 48)
              : const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: _isProjectMode
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (!_isProjectMode) ...[
                // Category Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Text(
                    category.toString().toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  currentTitle.toString(),
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
              RichText(
                textAlign: _isProjectMode ? TextAlign.center : TextAlign.start,
                text: TextSpan(
                  style: const TextStyle(height: 1.6),
                  children: _buildParsedSpans(
                    currentContent.toString(),
                    textColor,
                    _isProjectMode
                        ? settings.fontSize * 2.8
                        : settings.fontSize * 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isProjectMode || !_hasList
          ? null
          : BottomAppBar(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Previous Button
                  FilledButton.tonalIcon(
                    onPressed: _hasPrevious ? _goToPrevious : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Previous'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const Spacer(),
                  // Counter
                  Text(
                    '${_currentIndex + 1} / ${widget.allPrayers!.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  // Next Button
                  FilledButton.icon(
                    onPressed: _hasNext ? _goToNext : null,
                    label: const Text('Next'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    iconAlignment: IconAlignment.end,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: colorScheme.onPrimary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _isProjectMode
          ? FloatingActionButton.large(
              heroTag: 'prayer_project_exit',
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              onPressed: () => setState(() => _isProjectMode = false),
              child: const Icon(Icons.close_rounded),
            )
          : null,
    );
  }
}
