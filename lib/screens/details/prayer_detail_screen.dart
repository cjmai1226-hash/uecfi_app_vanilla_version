import 'package:flutter/material.dart';
import '../../services/ad_service.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/main_app_bar.dart';

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
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              height: 1.6,
            ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                textAlign: _isProjectMode
                    ? TextAlign.center
                    : TextAlign.start,
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
              const SizedBox(height: 48),
              const AdBannerWidget(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: _isProjectMode
          ? FloatingActionButton.large(
              heroTag: 'prayer_project_exit',
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              onPressed: () => setState(() => _isProjectMode = false),
              child: const Icon(Icons.close_rounded),
            )
          : null,
    );
  }
}
