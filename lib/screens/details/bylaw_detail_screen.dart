import 'package:flutter/material.dart';
import '../../services/ad_service.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class BylawDetailScreen extends StatelessWidget {
  final Map<String, dynamic> bylaw;

  const BylawDetailScreen({super.key, required this.bylaw});

  List<TextSpan> _buildParsedSpans(
    String text,
    Color textColor,
    double fontSize,
  ) {
    final pattern = RegExp(r'(Article\s+[A-Za-z0-9]+)', caseSensitive: false);
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
              fontSize: fontSize * 1.1,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    final title = bylaw['title'] ?? 'Untitled';
    final content = bylaw['content'] ?? 'No content available';
    final chapter = bylaw['chapters'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Policies & By-Laws'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter Tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Chapter $chapter'.toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '2019 BY-LAWS',
                    style: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
            // Content
            RichText(
              text: TextSpan(
                style: const TextStyle(height: 1.6),
                children: _buildParsedSpans(
                  content.toString(),
                  textColor,
                  settings.fontSize * 1.1,
                ),
              ),
            ),
            const SizedBox(height: 48),
            const AdBannerWidget(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
