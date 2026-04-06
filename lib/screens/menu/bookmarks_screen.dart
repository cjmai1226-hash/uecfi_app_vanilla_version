import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../services/database_helper.dart';
import '../details/song_detail_screen.dart';
import '../../widgets/main_app_bar.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarkProvider>();
    final bookmarkedTitles = bookmarks.bookmarkedSongTitles;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const MainAppBar(
        title: 'Bookmarks',
        showBackButton: true,
      ),
      body: bookmarkedTitles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline_rounded, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No bookmarks yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your favorite songs will appear here.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper().getSongs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final allSongs = snapshot.data ?? [];
                final bookmarkedSongs = allSongs.where((song) {
                  final title = song['title'] ?? '';
                  return bookmarkedTitles.contains(title);
                }).toList();

                if (bookmarkedSongs.isEmpty && bookmarkedTitles.isNotEmpty) {
                  return const Center(child: Text("Syncing bookmarks..."));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: bookmarkedSongs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final song = bookmarkedSongs[index];
                    final title = song['title'] ?? 'Untitled';
                    final category = song['category'] ?? 'Uncategorized';
                    final content = song['content'] ?? song['lyrics'] ?? '';

                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          radius: 24,
                          child: Icon(Icons.music_note_rounded, color: colorScheme.onPrimaryContainer, size: 20),
                        ),
                        title: Text(
                          title.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.3),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$category • ${content.toString().replaceAll('\n', ' ')}',
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
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SongDetailScreen(song: song)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
