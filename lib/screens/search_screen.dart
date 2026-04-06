import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../services/database_helper.dart';
import 'details/prayer_detail_screen.dart';
import 'details/song_detail_screen.dart';
import 'details/center_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.autoFocusField = false,
    this.initialFilter,
  });

  final bool autoFocusField;
  final String? initialFilter;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Prayers', 'Songs', 'Centers'];
  final List<String> _recentSearches = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  void _requestSearchFocus() {
    if (!mounted) return;
    _searchFocusNode.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');

    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'All';
    _searchController.addListener(_onSearchChanged);
    _loadRecentSearches();

    if (widget.autoFocusField) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestSearchFocus();
      });
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_recentSearchesKey) ?? [];
    if (!mounted) return;
    setState(() {
      _recentSearches.clear();
      _recentSearches.addAll(saved);
    });
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
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  Future<void> _clearRecentSearches() async {
    setState(() {
      _recentSearches.clear();
    });
    await _saveRecentSearches();
  }

  void _addToRecentSearches(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return;
    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == normalizedQuery.toLowerCase(),
    );
    _recentSearches.insert(0, normalizedQuery);
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches.removeRange(_maxRecentSearches, _recentSearches.length);
    }
    unawaited(_saveRecentSearches());
  }

  Future<void> _performSearch(String query, {bool saveToRecent = false}) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);
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
    }

    setState(() {
      _searchResults = results;
      _isLoading = false;
      if (saveToRecent) _addToRecentSearches(query);
    });
  }

  TextSpan _buildHighlightedTextSpan({
    required String text,
    required String query,
    required TextStyle normalStyle,
    required TextStyle highlightStyle,
  }) {
    final terms = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toSet()
        .toList();
    if (terms.isEmpty || text.isEmpty) {
      return TextSpan(text: text, style: normalStyle);
    }
    final escapedTerms = terms.map(RegExp.escape).join('|');
    final matchRegex = RegExp('($escapedTerms)', caseSensitive: false);
    final matches = matchRegex.allMatches(text).toList();
    if (matches.isEmpty) return TextSpan(text: text, style: normalStyle);

    final children = <TextSpan>[];
    var currentIndex = 0;
    for (final match in matches) {
      if (match.start > currentIndex) {
        children.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: normalStyle,
          ),
        );
      }
      children.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: highlightStyle,
        ),
      );
      currentIndex = match.end;
    }
    if (currentIndex < text.length) {
      children.add(
        TextSpan(text: text.substring(currentIndex), style: normalStyle),
      );
    }
    return TextSpan(children: children);
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isTagalog = settings.prayerLanguage == 'Tagalog';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Custom Google-Style Search Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Material(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const BackButton(),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          autofocus: widget.autoFocusField,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Search community...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _performSearch(value, saveToRecent: true);
                            }
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // --- Sticky Filter Chips ---
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      }
                    },
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // --- Results / Recent Searches ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchController.text.isEmpty
                  ? _buildRecentSearches()
                  : _buildSearchResults(isTagalog),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_rounded,
        title: 'Start searching',
        subtitle: 'Find prayers, songs, and centers instantly.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              TextButton(
                onPressed: _clearRecentSearches,
                child: const Text('Clear all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final query = _recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(
                  query,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.north_west_rounded, size: 18),
                  onPressed: () => _searchController.text = query,
                ),
                onTap: () {
                  _searchController.text = query;
                  _performSearch(query, saveToRecent: true);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(bool isTagalog) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results',
        subtitle:
            'We couldn\'t find anything matching "${_searchController.text}"',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        final type = item['type'];

        String title = '';
        String subtitle = '';
        IconData icon = Icons.article_rounded;

        if (type == 'Prayer') {
          title = isTagalog
              ? (item['title1'] ?? item['title'])
              : (item['title'] ?? 'Untitled');
          subtitle = 'Prayer • Page ${item['page'] ?? ''}';
          icon = Icons.auto_stories_rounded;
        } else if (type == 'Song') {
          title = item['title'] ?? 'Untitled';
          subtitle = 'Song • ${item['category'] ?? ''}';
          icon = Icons.music_note_rounded;
        } else if (type == 'Center') {
          title = item['centername']?.toString() ?? 'Center';
          subtitle =
              '${item['centerdistrict'] ?? ''} • ${item['centeraddress'] ?? ''}';
          icon = Icons.church_rounded;
        }

        return Material(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 22),
            ),
            title: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: _buildHighlightedTextSpan(
                text: title,
                query: _searchController.text,
                normalStyle: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
                highlightStyle: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            onTap: () {
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
              }
            },
          ),
        );
      },
    );
  }
}
