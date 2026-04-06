import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../providers/settings_provider.dart';
import 'details/prayer_detail_screen.dart';
import 'search_screen.dart';
import '../widgets/main_app_bar.dart';

class PrayersScreen extends StatelessWidget {
  const PrayersScreen({super.key, this.onOpenDrawer});

  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isTagalog = settings.prayerLanguage == 'Tagalog';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: MainAppBar(
        title: 'Prayers',
        onOpenDrawer: onOpenDrawer,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(
                    initialFilter: 'Prayers',
                    autoFocusField: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper().getPrayers(),
        builder: (context, snapshot) {
          final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;

          return CustomScrollView(
            slivers: [
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  child: Center(
                    child: Text("Error loading prayers: ${snapshot.error}"),
                  ),
                )
              else if (!hasData)
                const SliverFillRemaining(
                  child: Center(child: Text("No prayers found.")),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final prayers = snapshot.data!;
                        final prayer = prayers[index];

                        final ilocanoTitle = prayer['title'] ?? 'Untitled';
                        final ilocanoContent = prayer['content'] ?? 'No content available';
                        final tagalogTitle = prayer['title1'] ?? ilocanoTitle;
                        final tagalogContent = prayer['content1'] ?? ilocanoContent;

                        final title = isTagalog ? tagalogTitle : ilocanoTitle;
                        final content = isTagalog ? tagalogContent : ilocanoContent;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(24),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.auto_stories_rounded,
                                  color: colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                title.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  content.toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                size: 14,
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
                            ),
                          ),
                        );
                      },
                      childCount: snapshot.data!.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
