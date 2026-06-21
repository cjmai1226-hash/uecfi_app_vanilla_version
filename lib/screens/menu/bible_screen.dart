import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_helper.dart';
import '../../widgets/chatgpt_design_system.dart';
import '../../widgets/main_app_bar.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key, this.onOpenDrawer});

  final VoidCallback? onOpenDrawer;

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};

  List<Map<String, dynamic>> _books = [];
  String? _selectedBookId;
  String? _selectedBookName;
  int _selectedChapter = 1;
  List<int> _chapters = [];
  List<Map<String, dynamic>> _verses = [];

  bool _isLoading = true;

  // Search variables
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearchLoading = false;

  // Scrolling & Highlight helpers
  int? _highlightedVerse;

  @override
  void initState() {
    super.initState();
    _initBible();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initBible() async {
    final prefs = await SharedPreferences.getInstance();

    // Load books
    final booksData = await _dbHelper.getBibleBooks();
    if (!mounted) return;

    if (booksData.isNotEmpty) {
      setState(() {
        _books = booksData;
      });

      // Load saved position or default to Genesis (GN)
      final savedBookId = prefs.getString('last_read_book_id');
      final savedBookName = prefs.getString('last_read_book_name');
      final savedChapter = prefs.getInt('last_read_chapter');

      final initialBookId = savedBookId ?? booksData.first['book_id'] as String;
      final initialBookName =
          savedBookName ?? booksData.first['book_name'] as String;
      final initialChapter = savedChapter ?? 1;

      await _loadBookAndChapter(initialBookId, initialBookName, initialChapter);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBookAndChapter(
    String bookId,
    String bookName,
    int chapter, {
    int? targetVerse,
  }) async {
    setState(() {
      _isLoading = true;
      _selectedBookId = bookId;
      _selectedBookName = bookName;
      _selectedChapter = chapter;
      _verses = [];
      _verseKeys.clear();
    });

    // Save reading position
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_read_book_id', bookId);
    await prefs.setString('last_read_book_name', bookName);
    await prefs.setInt('last_read_chapter', chapter);

    // Fetch chapters for this book
    final chaptersList = await _dbHelper.getChaptersForBook(bookId);

    // Ensure the chapter fits within available chapters
    int validChapter = chapter;
    if (chaptersList.isNotEmpty && !chaptersList.contains(chapter)) {
      validChapter = chaptersList.first;
    }

    // Fetch verses
    final versesList = await _dbHelper.getVerses(bookId, validChapter);

    if (!mounted) return;

    setState(() {
      _chapters = chaptersList;
      _selectedChapter = validChapter;
      _verses = versesList;
      _isLoading = false;
    });

    if (targetVerse != null) {
      _triggerScrollAndHighlight(targetVerse);
    }
  }

  void _triggerScrollAndHighlight(int verseNumber) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Small delay to ensure layout is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        final key = _verseKeys[verseNumber];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
          setState(() {
            _highlightedVerse = verseNumber;
          });

          // Clear highlight after 3 seconds
          Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _highlightedVerse = null;
              });
            }
          });
        }
      });
    });
  }

  void _navigateToNextChapter() {
    if (_books.isEmpty || _selectedBookId == null) return;

    final bookIndex = _books.indexWhere((b) => b['book_id'] == _selectedBookId);
    if (bookIndex == -1) return;

    final currentBookChapters = _chapters;
    if (currentBookChapters.isEmpty) return;

    if (_selectedChapter < currentBookChapters.last) {
      // Go to next chapter in same book
      _loadBookAndChapter(
        _selectedBookId!,
        _selectedBookName!,
        _selectedChapter + 1,
      );
    } else {
      // Go to next book
      if (bookIndex < _books.length - 1) {
        final nextBook = _books[bookIndex + 1];
        final nextBookId = nextBook['book_id'] as String;
        final nextBookName = nextBook['book_name'] as String;
        _loadBookAndChapter(nextBookId, nextBookName, 1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are at the end of the Bible.')),
        );
      }
    }
  }

  void _navigateToPrevChapter() {
    if (_books.isEmpty || _selectedBookId == null) return;

    final bookIndex = _books.indexWhere((b) => b['book_id'] == _selectedBookId);
    if (bookIndex == -1) return;

    if (_selectedChapter > 1) {
      // Go to previous chapter in same book
      _loadBookAndChapter(
        _selectedBookId!,
        _selectedBookName!,
        _selectedChapter - 1,
      );
    } else {
      // Go to previous book
      if (bookIndex > 0) {
        final prevBook = _books[bookIndex - 1];
        final prevBookId = prevBook['book_id'] as String;
        final prevBookName = prevBook['book_name'] as String;

        // Fetch prev book chapters to find the last chapter
        _dbHelper.getChaptersForBook(prevBookId).then((prevChapters) {
          if (prevChapters.isNotEmpty) {
            _loadBookAndChapter(prevBookId, prevBookName, prevChapters.last);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are at the beginning of the Bible.'),
          ),
        );
      }
    }
  }

  void _showBookChapterSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _BookChapterSelectorSheet(
          books: _books,
          initialBookId: _selectedBookId,
          initialChapter: _selectedChapter,
          dbHelper: _dbHelper,
          onSelected: (bookId, bookName, chapter, verse) {
            _loadBookAndChapter(bookId, bookName, chapter, targetVerse: verse);
          },
        );
      },
    );
  }

  void _showAboutDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF171717) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ilocano Door Version',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ti Biblia (ILODOR)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Date', '2019', colorScheme),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Copyright',
                  '© 2019 Door43 World Missions Community',
                  colorScheme,
                ),
                const SizedBox(height: 12),
                _buildInfoRow('License', 'CC BY-SA', colorScheme),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Spoken',
                  'Austronesian language spoken by the Ilocano people of the Philippines',
                  colorScheme,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    setState(() {
      _isSearchLoading = true;
    });

    final results = await _dbHelper.searchBible(cleanQuery);

    if (!mounted) return;

    setState(() {
      _searchResults = results;
      _isSearchLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final fontSize = settings.fontSize;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: MainAppBar(
        title: _isSearching
            ? 'Search Bible'
            : (_selectedBookName != null
                ? '$_selectedBookName $_selectedChapter'
                : ''),
        onOpenDrawer: widget.onOpenDrawer,
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                  _searchResults = [];
                  _searchController.clear();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: _showAboutDialog,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                });
              },
            ),
          ],
        ],
      ),
      body: _isSearching
          ? _buildSearchView(colorScheme, isDark)
          : _buildReaderView(colorScheme, isDark, fontSize),
      bottomNavigationBar: !_isSearching && !_isLoading && _verses.isNotEmpty
          ? _buildBottomNavigationBar(colorScheme, isDark)
          : null,
    );
  }

  Widget _buildReaderView(
    ColorScheme colorScheme,
    bool isDark,
    double fontSize,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_verses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No verses loaded.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _initBible, child: const Text('Retry')),
          ],
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe to change chapters
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < 0) {
            // Swiped Left -> Next Chapter
            _navigateToNextChapter();
          } else if (details.primaryVelocity! > 0) {
            // Swiped Right -> Prev Chapter
            _navigateToPrevChapter();
          }
        }
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        itemCount: _verses.length,
        itemBuilder: (context, index) {
          final verse = _verses[index];
          final verseNum = verse['verse'] as int;
          final text = verse['text']?.toString() ?? '';
          final key = _verseKeys.putIfAbsent(verseNum, () => GlobalKey());

          final isHighlighted = _highlightedVerse == verseNum;

          return AnimatedContainer(
            key: key,
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verse Number
                Container(
                  width: 32,
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '$verseNum',
                    style: TextStyle(
                      fontSize: fontSize - 3,
                      fontWeight: FontWeight.bold,
                      color: isHighlighted
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                // Verse Text
                Expanded(
                  child: SelectableText(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.6,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchView(ColorScheme colorScheme, bool isDark) {
    final isDarkSearch = isDark;
    final containerBg = isDarkSearch
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF9F9F9);
    final borderColor = isDarkSearch
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return Column(
      children: [
        // Search Input field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: containerBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      autofocus: true,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search words in Ilocano Bible...',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _performSearch,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () => _performSearch(_searchController.text),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isSearchLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Enter a keyword to search scriptures.'
                          : 'No matching verses found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    final bookId = result['book_id'] as String;
                    final bookName = result['book_name']?.toString() ?? 'Bible';
                    final chapter = result['chapter'] as int;
                    final verse = result['verse'] as int;
                    final text = result['text']?.toString() ?? '';

                    return ChatGPTCard(
                      borderRadius: 12,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Row(
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$bookName $chapter:$verse',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _isSearching = false;
                          });
                          _loadBookAndChapter(
                            bookId,
                            bookName,
                            chapter,
                            targetVerse: verse,
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Prev Button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                tooltip: 'Previous Chapter',
                onPressed: _navigateToPrevChapter,
              ),

              // Title Selector button
              Expanded(
                child: TextButton.icon(
                  onPressed: _showBookChapterSelector,
                  icon: const Icon(Icons.unfold_more_rounded, size: 18),
                  label: Text(
                    '$_selectedBookName $_selectedChapter',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),

              // Next Button
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                tooltip: 'Next Chapter',
                onPressed: _navigateToNextChapter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bottom sheet stateful selector
class _BookChapterSelectorSheet extends StatefulWidget {
  final List<Map<String, dynamic>> books;
  final String? initialBookId;
  final int initialChapter;
  final DatabaseHelper dbHelper;
  final Function(String bookId, String bookName, int chapter, int? verse) onSelected;

  const _BookChapterSelectorSheet({
    required this.books,
    required this.initialBookId,
    required this.initialChapter,
    required this.dbHelper,
    required this.onSelected,
  });

  @override
  State<_BookChapterSelectorSheet> createState() =>
      _BookChapterSelectorSheetState();
}

class _BookChapterSelectorSheetState extends State<_BookChapterSelectorSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _tempBookId;
  String? _tempBookName;
  int? _tempChapter;
  List<int> _tempChapters = [];
  List<int> _tempVerses = [];
  bool _loadingChapters = false;
  bool _loadingVerses = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tempBookId = widget.initialBookId;
    _tempChapter = widget.initialChapter;

    if (_tempBookId != null) {
      final bk = widget.books.firstWhere(
        (b) => b['book_id'] == _tempBookId,
        orElse: () => {},
      );
      _tempBookName = bk.isNotEmpty ? bk['book_name'] as String : '';
      _loadChapters(_tempBookId!);
      if (_tempChapter != null) {
        _loadVerses(_tempBookId!, _tempChapter!);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters(String bookId) async {
    setState(() {
      _loadingChapters = true;
    });
    final ch = await widget.dbHelper.getChaptersForBook(bookId);
    if (!mounted) return;
    setState(() {
      _tempChapters = ch;
      _loadingChapters = false;
    });
  }

  Future<void> _loadVerses(String bookId, int chapter) async {
    setState(() {
      _loadingVerses = true;
    });
    final versesData = await widget.dbHelper.getVerses(bookId, chapter);
    final List<int> vs = versesData.map((v) => v['verse'] as int).toList();
    if (!mounted) return;
    setState(() {
      _tempVerses = vs;
      _loadingVerses = false;
    });
  }

  void _onBookTapped(String bookId, String bookName) {
    setState(() {
      _tempBookId = bookId;
      _tempBookName = bookName;
      _tempChapter = null;
      _tempVerses = [];
    });
    _loadChapters(bookId).then((_) {
      _tabController.animateTo(1);
    });
  }

  void _onChapterTapped(int chapterNum) {
    setState(() {
      _tempChapter = chapterNum;
    });
    _loadVerses(_tempBookId!, chapterNum).then((_) {
      _tabController.animateTo(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Tab bar selection
          TabBar(
            controller: _tabController,
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.onSurface,
            unselectedLabelColor: colorScheme.onSurfaceVariant.withValues(
              alpha: 0.6,
            ),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'BOOKS'),
              Tab(text: 'CHAPTERS'),
              Tab(text: 'VERSES'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Books Grid
                _buildBooksTab(colorScheme, isDark),

                // Chapters Grid
                _buildChaptersTab(colorScheme, isDark),

                // Verses Grid
                _buildVersesTab(colorScheme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksTab(ColorScheme colorScheme, bool isDark) {
    if (widget.books.isEmpty) {
      return const Center(child: Text('No books available.'));
    }

    final mtIndex = widget.books.indexWhere((b) => b['book_id'] == 'MT');
    final otBooks = mtIndex != -1
        ? widget.books.sublist(0, mtIndex)
        : widget.books;
    final ntBooks = mtIndex != -1
        ? widget.books.sublist(mtIndex)
        : <Map<String, dynamic>>[];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (otBooks.isNotEmpty) ...[
          _buildSectionHeader(colorScheme, 'DAAN A TULAG (OLD TESTAMENT)'),
          ...otBooks.map((bk) => _buildBookItem(bk, colorScheme)),
        ],
        if (ntBooks.isNotEmpty) ...[
          _buildSectionHeader(colorScheme, 'BARO A TULAG (NEW TESTAMENT)'),
          ...ntBooks.map((bk) => _buildBookItem(bk, colorScheme)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(ColorScheme colorScheme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildBookItem(Map<String, dynamic> bk, ColorScheme colorScheme) {
    final id = bk['book_id'] as String;
    final name = bk['book_name'] as String;
    final isSelected = id == _tempBookId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ChatGPTCard(
        borderRadius: 10,
        child: InkWell(
          onTap: () => _onBookTapped(id, name),
          child: Container(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 18,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      fontSize: 14,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChaptersTab(ColorScheme colorScheme, bool isDark) {
    if (_tempBookId == null) {
      return Center(
        child: Text(
          'Please select a book first.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    if (_loadingChapters) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tempChapters.isEmpty) {
      return const Center(child: Text('No chapters found.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _tempChapters.length,
      itemBuilder: (context, index) {
        final chNum = _tempChapters[index];
        final isSelected =
            _tempBookId == widget.initialBookId &&
            chNum == widget.initialChapter;

        return ChatGPTCard(
          borderRadius: 12,
          child: InkWell(
            onTap: () => _onChapterTapped(chNum),
            child: Container(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              alignment: Alignment.center,
              child: Text(
                '$chNum',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 16,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersesTab(ColorScheme colorScheme, bool isDark) {
    if (_tempBookId == null) {
      return Center(
        child: Text(
          'Please select a book first.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    if (_tempChapter == null) {
      return Center(
        child: Text(
          'Please select a chapter first.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    if (_loadingVerses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tempVerses.isEmpty) {
      return const Center(child: Text('No verses found.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _tempVerses.length,
      itemBuilder: (context, index) {
        final verseNum = _tempVerses[index];

        return ChatGPTCard(
          borderRadius: 12,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              widget.onSelected(_tempBookId!, _tempBookName!, _tempChapter!, verseNum);
            },
            child: Container(
              alignment: Alignment.center,
              child: Text(
                '$verseNum',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
