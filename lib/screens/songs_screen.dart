import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'details/song_detail_screen.dart';

class SongsScreen extends StatelessWidget {
  const SongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getSongs(),
      builder: (context, snapshot) {
        final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
        final count = hasData ? snapshot.data!.length : 0;

        return Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.asset('assets/images/image.png'),
            ),
            title: const Text('Songs'),
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
                        fontSize: 16,
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
                child: Text("Error loading songs: ${snapshot.error}"),
              );
            } else if (!hasData) {
              return const Center(child: Text("No songs found."));
            }

            final songs = snapshot.data!;

            return ListView.separated(
              itemCount: songs.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, thickness: 0.5),
              itemBuilder: (context, index) {
                final song = songs[index];
                final title = song['title'] ?? 'Untitled';
                final content = song['content'] ?? 'No content available';

                return ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    content,
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
          }(),
        );
      },
    );
  }
}
