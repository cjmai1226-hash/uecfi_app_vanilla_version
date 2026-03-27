import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/database_helper.dart';
import 'details/prayer_detail_screen.dart';
import 'details/song_detail_screen.dart';
import 'details/center_detail_screen.dart';
import 'details/bylaw_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Prayers', 'Songs', 'Centers', 'By-Laws'];
  final List<String> _recentSearches = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> results = [];
    final dbHelper = DatabaseHelper();

    if (_selectedFilter == 'All') {
      results = await dbHelper.searchAll(query);
    } else if (_selectedFilter == 'Prayers') {
      results = await dbHelper.searchTable('Prayers', 'Prayer', query, [
        'title',
        'content',
        'title1',
        'content1',
      ]);
    } else if (_selectedFilter == 'Songs') {
      results = await dbHelper.searchTable('Songs', 'Song', query, [
        'title',
        'content',
        'chords',
      ]);
    } else if (_selectedFilter == 'Centers') {
      results = await dbHelper.searchTable('Centers', 'Center', query, [
        'centername',
        'centeraddress',
        'centerdistrict',
        'centerlocation',
      ]);
    } else if (_selectedFilter == 'By-Laws') {
      results = await dbHelper.searchTable('bylaws', 'By-Laws', query, [
        'title',
        'content',
        'chapters',
      ]);
    }

    setState(() {
      _searchResults = results;
      _isLoading = false;
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
      }
    });
  }

  Widget _buildSearchResults(Color textColor, bool isTagalog) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Text(
          'No results found for "${_searchController.text}"',
          style: TextStyle(color: textColor.withValues(alpha: 0.5)),
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (_recentSearches.isNotEmpty)
                  TextButton(
                    onPressed: _clearRecentSearches,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _recentSearches.isEmpty
                ? Center(
                    child: Text(
                      'No recent searches',
                      style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                    ),
                  )
                : ListView.builder(
                    itemCount: _recentSearches.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(
                          Icons.history,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        title: Text(
                          _recentSearches[index],
                          style: TextStyle(color: textColor),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: textColor.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        onTap: () {
                          _searchController.text = _recentSearches[index];
                          _performSearch(_recentSearches[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, thickness: 0.5),
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        final type = item['type'];

        String title = '';
        String subtitle = '';
        IconData icon = Icons.article;

        if (type == 'Prayer') {
          final ilocanoTitle = item['title'] ?? 'Unknown Prayer';
          final tagalogTitle = item['title1'] ?? ilocanoTitle;
          title = isTagalog ? tagalogTitle : ilocanoTitle;
          subtitle = 'Prayer • Page ${item['page'] ?? ''}';
          icon = Icons.menu_book;
        } else if (type == 'Song') {
          title = item['title'] ?? 'Unknown Song';
          subtitle = 'Song • ${item['category'] ?? ''}';
          icon = Icons.music_note;
        } else if (type == 'Center') {
          title = item['centername']?.toString() ?? 'Unknown Center';
          final address = item['centeraddress']?.toString() ?? '';
          subtitle = address.isNotEmpty ? address : 'No address provided';
          icon = Icons.church_outlined;
        } else if (type == 'By-Laws') {
          title = item['title'] ?? 'Unknown By-Law';
          subtitle = 'By-Law • Chapter ${item['chapters'] ?? ''}';
          icon = Icons.gavel_outlined;
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(
            title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: textColor.withValues(alpha: 0.6)),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to appropriate detail screen
            if (type == 'Prayer') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrayerDetailScreen(prayer: item),
                ),
              );
            } else if (type == 'Song') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongDetailScreen(song: item),
                ),
              );
            } else if (type == 'Center') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CenterDetailScreen(centerNode: item),
                ),
              );
            } else if (type == 'By-Laws') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BylawDetailScreen(bylaw: item),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isTagalog = settings.prayerLanguage == 'Tagalog';

    // Rely exclusively on theme mappings
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        titleSpacing: 0,
        leading: BackButton(color: textColor),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.05), // Dynamic subtle grey
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search,
                color: textColor.withValues(alpha: 0.5),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.clear,
                        color: textColor.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _performSearch(value);
              }
            },
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            color: surfaceColor,
            icon: Icon(
              Icons.filter_list,
              color: _selectedFilter != 'All'
                  ? Theme.of(context).colorScheme.primary
                  : textColor,
            ),
            onSelected: (String result) {
              setState(() {
                _selectedFilter = result;
              });
              // Perform a search automatically if text exists
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }
            },
            itemBuilder: (BuildContext context) =>
                _filters.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(
                      choice,
                      style: TextStyle(
                        fontWeight: choice == _selectedFilter
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: choice == _selectedFilter
                            ? Theme.of(context).colorScheme.primary
                            : textColor,
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedFilter != 'All')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Searching in: $_selectedFilter',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          Expanded(child: _buildSearchResults(textColor, isTagalog)),
        ],
      ),
    );
  }
}
