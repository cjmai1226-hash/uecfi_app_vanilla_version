import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../services/database_helper.dart';
import '../details/song_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarkProvider>();
    final bookmarkedTitles = bookmarks.bookmarkedSongTitles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        centerTitle: true,
        elevation: 0,
      ),
      body: bookmarkedTitles.isEmpty
          ? const Center(child: Text('No bookmarks yet.'))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper().getSongs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Error loading bookmarks: ${snapshot.error}"),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No songs database found."));
                }

                final allSongs = snapshot.data!;
                final bookmarkedSongs = allSongs.where((song) {
                  final title = song['title'] ?? '';
                  return bookmarkedTitles.contains(title);
                }).toList();

                if (bookmarkedSongs.isEmpty) {
                  // Bookmarks exist locally but are strangely missing from the DB
                  return const Center(
                    child: Text(
                      'Bookmarked songs could not be logically mapped.',
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: bookmarkedSongs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, thickness: 0.5),
                  itemBuilder: (context, index) {
                    final song = bookmarkedSongs[index];
                    final title = song['title'] ?? 'Untitled';
                    final content =
                        song['content'] ??
                        song['lyrics'] ??
                        'No content available';

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
                            builder: (context) => SongDetailScreen(song: song),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
