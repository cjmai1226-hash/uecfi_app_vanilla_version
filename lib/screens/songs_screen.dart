import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/ad_service.dart';
import 'details/song_detail_screen.dart';
import 'search_screen.dart';
import 'menu/bookmarks_screen.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/chatgpt_widgets.dart';

class SongsScreen extends StatelessWidget {
  const SongsScreen({super.key, this.onOpenDrawer});

  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: MainAppBar(
        title: 'Songs',
        onOpenDrawer: onOpenDrawer,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(
                    initialFilter: 'Songs',
                    autoFocusField: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper().getSongs(),
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
                    child: Text("Error loading songs: ${snapshot.error}"),
                  ),
                )
              else if (!hasData)
                const SliverFillRemaining(
                  child: Center(child: Text("No songs found.")),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final songs = snapshot.data!;
                        final song = songs[index];
                        final title = song['title'] ?? 'Untitled';
                        final content = song['content'] ?? 'No content available';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ChatGPTCard(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  content,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              trailing: (song['chords'] != null &&
                                      song['chords'].toString().trim().isNotEmpty)
                                  ? const ChatGPTTag(
                                      label: 'CHORDS',
                                      icon: Icons.music_note_rounded,
                                      fontSize: 9,
                                    )
                                  : null,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SongDetailScreen(song: song),
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
      bottomNavigationBar: const SafeArea(
        child: AdBannerWidget(),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookmarksScreen(),
            ),
          );
        },
        tooltip: 'Bookmarks',
        child: const Icon(Icons.bookmarks_rounded),
      ),
    );
  }
}
