import 'package:flutter/material.dart';
import '../../widgets/main_app_bar.dart';

class BylawDetailScreen extends StatelessWidget {
  final Map<String, dynamic> bylaw;

  const BylawDetailScreen({super.key, required this.bylaw});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const MainAppBar(title: 'Bylaw Detail', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(Icons.gavel_rounded, color: colorScheme.primary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chapter ${bylaw['chapters'] ?? ''}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          bylaw['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildContent(bylaw['content'] ?? 'No content available.', colorScheme),
            const SizedBox(height: 64),
            Center(
              child: Text(
                '2019 By-Laws',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String content, ColorScheme colorScheme) {
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r'(Article\s+\d+)', caseSensitive: false);

    int start = 0;
    for (final Match match in regExp.allMatches(content)) {
      if (match.start > start) {
        spans.add(TextSpan(text: content.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ));
      start = match.end;
    }
    if (start < content.length) {
      spans.add(TextSpan(text: content.substring(start)));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: TextStyle(
        fontSize: 16,
        height: 1.6,
        letterSpacing: 0.2,
        color: colorScheme.onSurface,
      ),
    );
  }
}
