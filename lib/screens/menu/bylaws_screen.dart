import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../details/bylaw_detail_screen.dart';

class BylawsScreen extends StatelessWidget {
  const BylawsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getBylaws(),
      builder: (context, snapshot) {
        final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
        final count = hasData ? snapshot.data!.length : 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('ByLaws'),
            centerTitle: true,
            elevation: 0,
            actions: [
              if (hasData)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: () {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: TextStyle(color: textColor),
                ),
              );
            } else if (!hasData) {
              return Center(
                child: Text(
                  "No ByLaws found.",
                  style: TextStyle(color: textColor),
                ),
              );
            }

            final bylaws = snapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: bylaws.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, thickness: 0.5),
              itemBuilder: (context, index) {
                final bylaw = bylaws[index];
                final title = bylaw['title'] ?? 'Untitled';
                final content = bylaw['content'] ?? 'No content available';
                final chapter = bylaw['chapters'] ?? '';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    title.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      content.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        height: 1.3,
                      ),
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      chapter.toString(),
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: textColor.withValues(alpha: 0.3),
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BylawDetailScreen(bylaw: bylaw),
                      ),
                    );
                  },
                );
              },
            );
          }(),
        );
      },
    );
  }
}
