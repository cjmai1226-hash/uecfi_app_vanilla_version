import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../widgets/main_app_bar.dart';
import '../details/bylaw_detail_screen.dart';
import '../../services/ad_service.dart';

class BylawsScreen extends StatefulWidget {
  const BylawsScreen({super.key});

  @override
  State<BylawsScreen> createState() => _BylawsScreenState();
}

class _BylawsScreenState extends State<BylawsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allBylaws = [];
  List<Map<String, dynamic>> _filteredBylaws = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBylaws();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBylaws() async {
    final bylaws = await DatabaseHelper().getBylaws();
    setState(() {
      _allBylaws = bylaws;
      _filteredBylaws = bylaws;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBylaws = _allBylaws.where((bylaw) {
        final title = (bylaw['title'] ?? '').toString().toLowerCase();
        final content = (bylaw['content'] ?? '').toString().toLowerCase();
        final chapters = (bylaw['chapters'] ?? '').toString().toLowerCase();
        return title.contains(query) || content.contains(query) || chapters.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const MainAppBar(title: 'Church Bylaws', showBackButton: true),
      body: Column(
        children: [
          // Local Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search bylaws...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBylaws.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gavel_rounded, size: 64, color: colorScheme.primary.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            const Text('No bylaws found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        itemCount: _filteredBylaws.length,
                        itemBuilder: (context, index) {
                          final bylaw = _filteredBylaws[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(24),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  bylaw['title'] ?? 'Untitled',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.5),
                                ),
                                subtitle: Text(
                                  bylaw['content'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                trailing: (bylaw['chapters'] != null &&
                                        bylaw['chapters'].toString().trim().isNotEmpty)
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: colorScheme.primary.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'CH. ${bylaw['chapters']}',
                                          style: TextStyle(
                                            color: colorScheme.onPrimaryContainer,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => BylawDetailScreen(bylaw: bylaw)),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(
        child: AdBannerWidget(),
      ),
    );
  }
}
