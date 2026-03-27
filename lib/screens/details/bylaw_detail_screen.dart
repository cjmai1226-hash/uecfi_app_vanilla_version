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
    // Matches "Article 1", "Article II", "ARTICLE 12", etc.
    final pattern = RegExp(r'(Article\s+[A-Za-z0-9]+)', caseSensitive: false);
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

    final title = bylaw['title'] ?? 'Untitled';
    final content = bylaw['content'] ?? 'No content available';
    final chapter = bylaw['chapters'] ?? '';

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('By-Laws Details'),
        centerTitle: true,
        elevation: 0,
      ),
      bottomNavigationBar: BottomAppBar(
        color: surfaceColor,
        height: 70,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Chip(
                label: Text(
                  'Chapter $chapter',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                side: BorderSide.none,
              ),
              const SizedBox(width: 8),
              Chip(
                label: const Text(
                  '2019 BY-LAWS',
                  style: TextStyle(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title.toString(),
              style: TextStyle(
                fontSize: settings.fontSize * 1.5,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 24),
            // Content Container
            RichText(
              text: TextSpan(
                style: const TextStyle(height: 1.6),
                children: _buildParsedSpans(
                  content.toString(),
                  textColor,
                  settings.fontSize,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const AdBannerWidget(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
