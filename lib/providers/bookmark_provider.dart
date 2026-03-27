import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkProvider with ChangeNotifier {
  List<String> _bookmarkedSongTitles = [];

  List<String> get bookmarkedSongTitles => _bookmarkedSongTitles;

  BookmarkProvider() {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    _bookmarkedSongTitles = prefs.getStringList('bookmarks') ?? [];
    notifyListeners();
  }

  bool isBookmarked(String title) {
    return _bookmarkedSongTitles.contains(title);
  }

  Future<void> toggleBookmark(String title) async {
    if (_bookmarkedSongTitles.contains(title)) {
      _bookmarkedSongTitles.remove(title);
    } else {
      _bookmarkedSongTitles.add(title);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('bookmarks', _bookmarkedSongTitles);
  }
}
