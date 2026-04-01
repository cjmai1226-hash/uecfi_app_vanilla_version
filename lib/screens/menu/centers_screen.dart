import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../details/center_detail_screen.dart';

enum CenterFilter { district, centers }

class CentersScreen extends StatefulWidget {
  const CentersScreen({super.key});

  @override
  State<CentersScreen> createState() => _CentersScreenState();
}

class _CentersScreenState extends State<CentersScreen> {
  CenterFilter _currentFilter = CenterFilter.centers;

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Sort by',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_city),
                title: const Text('Centers'),
                trailing: _currentFilter == CenterFilter.centers
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _currentFilter = CenterFilter.centers);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('District'),
                trailing: _currentFilter == CenterFilter.district
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _currentFilter = CenterFilter.district);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getCenters(),
      builder: (context, snapshot) {
        final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
        final count = hasData ? snapshot.data!.length : 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Centers'),
            centerTitle: true,
            elevation: 0,
            actions: [
              if (hasData)
                Center(
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterOptions,
              ),
            ],
          ),
          body: () {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: TextStyle(color: textColor),
                ),
              );
            } else if (!hasData) {
              return Center(
                child: Text(
                  "No Centers found.",
                  style: TextStyle(color: textColor),
                ),
              );
            }

            final rawCenters = snapshot.data!;
            final centers = List<Map<String, dynamic>>.from(rawCenters);

            if (_currentFilter == CenterFilter.district) {
              centers.sort((a, b) {
                final distA = (a['centerdistrict']?.toString() ?? 'Uncategorized');
                final distB = (b['centerdistrict']?.toString() ?? 'Uncategorized');

                // Custom comparator for natural sorting (1, 2, 10...)
                int getSortWeight(String dist) {
                  if (dist == 'Foreign-Based') return 9999;
                  if (dist == 'Uncategorized') return 10000;
                  
                  // Extract number from "District X"
                  final numberMatch = RegExp(r'\d+').firstMatch(dist);
                  if (numberMatch != null) {
                    return int.parse(numberMatch.group(0)!);
                  }
                  return 5000; // Generic fallback
                }

                final weightA = getSortWeight(distA);
                final weightB = getSortWeight(distB);

                if (weightA != weightB) {
                  return weightA.compareTo(weightB);
                }

                // If same district, sort by name
                final nameA = (a['centername']?.toString() ?? '').toLowerCase();
                final nameB = (b['centername']?.toString() ?? '').toLowerCase();
                return nameA.compareTo(nameB);
              });
            } else {
              centers.sort((a, b) {
                final nameA = (a['centername']?.toString() ?? '');
                final nameB = (b['centername']?.toString() ?? '');
                return nameA.compareTo(nameB);
              });
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: centers.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, thickness: 0.5),
              itemBuilder: (context, index) {
                final centerNode = centers[index];
                final name = centerNode['centername'] ?? 'Unknown Center';
                final address = centerNode['centeraddress']?.toString() ?? '';
                final location = centerNode['centerlocation']?.toString() ?? '';
                final rawDistrict = centerNode['centerdistrict']?.toString() ?? '';

                // Use centerdistrict for the pill label (as requested)
                final String district = rawDistrict.isNotEmpty ? rawDistrict : 'Uncategorized';
                
                // Use centeraddress or centerlocation for the subtitle
                final String subtitleText = address.isNotEmpty ? address : location;

                // Short-code logic for the avatar text
                String avatarText = '?';
                if (district == 'Foreign-Based') {
                  avatarText = 'FB';
                } else if (district.contains('District')) {
                  final number = district.replaceAll(RegExp(r'[^0-9]'), '');
                  avatarText = 'D$number';
                } else if (district.isNotEmpty) {
                  avatarText = district.substring(0, 1).toUpperCase();
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      avatarText,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Text(
                    name.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      subtitleText.isEmpty
                          ? 'No address provided'
                          : subtitleText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        height: 1.3,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 24,
                    color: textColor.withValues(alpha: 0.3),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CenterDetailScreen(centerNode: centerNode),
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
