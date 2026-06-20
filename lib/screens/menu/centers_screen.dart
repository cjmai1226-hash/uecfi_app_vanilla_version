import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../details/center_detail_screen.dart';
import '../search_screen.dart';
import '../../widgets/main_app_bar.dart';
import '../../services/ad_service.dart';
import '../../widgets/chatgpt_design_system.dart';

class CentersScreen extends StatefulWidget {
  const CentersScreen({super.key, this.onOpenDrawer});

  final VoidCallback? onOpenDrawer;

  @override
  State<CentersScreen> createState() => _CentersScreenState();
}

class _CentersScreenState extends State<CentersScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: MainAppBar(
        title: 'Centers',
        onOpenDrawer: widget.onOpenDrawer,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(
                    initialFilter: 'Centers',
                    autoFocusField: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper().getCenters(),
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
                    child: Text("Error: ${snapshot.error}"),
                  ),
                )
              else if (!hasData)
                const SliverFillRemaining(
                  child: Center(child: Text("No Centers found.")),
                )
              else
                () {
                  final centers = List<Map<String, dynamic>>.from(snapshot.data!);
                  centers.sort((a, b) {
                    final nameA = (a['centername']?.toString() ?? '');
                    final nameB = (b['centername']?.toString() ?? '');
                    return nameA.compareTo(nameB);
                  });

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final centerNode = centers[index];
                          final name = centerNode['centername'] ?? 'Unknown Center';
                          final address = centerNode['centeraddress']?.toString() ?? '';
                          final location = centerNode['centerlocation']?.toString() ?? '';
                          final rawDistrict = centerNode['centerdistrict']?.toString() ?? '';

                          final String district = rawDistrict.isNotEmpty ? rawDistrict : 'Uncategorized';
                          final String subtitleText = address.isNotEmpty ? address : location;


                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ChatGPTCard(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                title: Text(
                                  name.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    subtitleText.isEmpty ? 'No address provided' : subtitleText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                trailing: ChatGPTTag(
                                  label: district,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CenterDetailScreen(centerNode: centerNode),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        childCount: centers.length,
                      ),
                    ),
                  );
                }(),
            ],
          );
        },
      ),
      bottomNavigationBar: const SafeArea(
        child: AdBannerWidget(),
      ),
    );
  }
}
