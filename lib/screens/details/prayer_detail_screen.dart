import 'package:flutter/material.dart';
import '../../services/ad_service.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class PrayerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> prayer;

  const PrayerDetailScreen({super.key, required this.prayer});

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> {
  bool _isProjectMode = false;

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
              fontWeight: FontWeight.bold,
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
    final isTagalog = settings.prayerLanguage == 'Tagalog';

    // Ilocano variables
    final ilocanoTitle = widget.prayer['title'] ?? 'Untitled';
    final ilocanoContent = widget.prayer['content'] ?? 'No content available';

    // Tagalog variables
    final tagalogTitle = widget.prayer['title1'] ?? ilocanoTitle;
    final tagalogContent = widget.prayer['content1'] ?? ilocanoContent;

    final category = widget.prayer['category'] ?? 'Uncategorized';

    // Resolving based on global state
    final currentTitle = isTagalog ? tagalogTitle : ilocanoTitle;
    final currentContent = isTagalog ? tagalogContent : ilocanoContent;

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isProjectMode ? 'Projecting' : 'Prayer Details'),
        centerTitle: true,
        elevation: 0,
        actions: [
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: _isProjectMode
              ? const EdgeInsets.all(8.0)
              : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: _isProjectMode
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (!_isProjectMode) ...[
                // Title
                Text(
                  currentTitle.toString(),
                  style: TextStyle(
                    fontSize: settings.fontSize * 1.5,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Content Container
              RichText(
                textAlign: _isProjectMode
                    ? TextAlign.center
                    : TextAlign.justify,
                text: TextSpan(
                  style: const TextStyle(height: 1.5),
                  children: _buildParsedSpans(
                    currentContent.toString(),
                    textColor,
                    _isProjectMode
                        ? settings.fontSize * 2.5
                        : settings.fontSize,
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
      bottomNavigationBar: _isProjectMode
          ? null
          : BottomAppBar(
              color: surfaceColor,
              height: 70,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Chip(
                      label: Text(
                        category.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      side: BorderSide.none,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
