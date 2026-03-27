import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../providers/settings_provider.dart';
import 'details/prayer_detail_screen.dart';

class PrayersScreen extends StatelessWidget {
  const PrayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isTagalog = settings.prayerLanguage == 'Tagalog';

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getPrayers(),
      builder: (context, snapshot) {
        final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
        final count = hasData ? snapshot.data!.length : 0;

        return Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.asset('assets/images/image.png'),
            ),
            title: const Text('Prayers'),
            centerTitle: true,
            elevation: 0,
            actions: [
              if (hasData)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
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
                child: Text("Error loading prayers: ${snapshot.error}"),
              );
            } else if (!hasData) {
              return const Center(child: Text("No prayers found."));
            }

            final prayers = snapshot.data!;

            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: prayers.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, thickness: 0.5),
              itemBuilder: (context, index) {
                final prayer = prayers[index];

                final ilocanoTitle = prayer['title'] ?? 'Untitled';
                final ilocanoContent =
                    prayer['content'] ?? 'No content available';

                final tagalogTitle = prayer['title1'] ?? ilocanoTitle;
                final tagalogContent = prayer['content1'] ?? ilocanoContent;

                final title = isTagalog ? tagalogTitle : ilocanoTitle;
                final content = isTagalog ? tagalogContent : ilocanoContent;

                return ListTile(
                  title: Text(
                    title.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    content.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PrayerDetailScreen(prayer: prayer),
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
