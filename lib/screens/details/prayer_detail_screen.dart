import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/chatgpt_design_system.dart';

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
                ChatGPTTag(
                  label: category.toString().toUpperCase(),
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
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        tooltip: 'Previous Prayer',
                        onPressed: _hasPrevious ? _goToPrevious : null,
                      ),

                      // Counter
                      Text(
                        '${_currentIndex + 1} / ${widget.allPrayers!.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      // Next Button
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded),
                        tooltip: 'Next Prayer',
                        onPressed: _hasNext ? _goToNext : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: _isProjectMode
          ? FloatingActionButton.large(
              heroTag: 'prayer_project_exit',
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F0F0F),
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F0F0F) : Colors.white,
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
