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
                final distA =
                    (a['centerdistrict']?.toString() ?? 'Uncategorized');
                final distB =
                    (b['centerdistrict']?.toString() ?? 'Uncategorized');
                // Sort by district first, then by center name
                final districtCompare = distA.compareTo(distB);
                if (districtCompare != 0) return districtCompare;
                final nameA = (a['centername']?.toString() ?? '');
                final nameB = (b['centername']?.toString() ?? '');
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
                final rawDistrict = centerNode['centerdistrict']?.toString();
                final district = rawDistrict == '0'
                    ? 'Foreign-Based'
                    : (rawDistrict ?? 'Uncategorized');
                final name = centerNode['centername'] ?? 'Unknown Center';
                final address =
                    centerNode['centeraddress'] ?? 'No address provided';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    name.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      address.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        height: 1.3,
                      ),
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      district.toString().isNotEmpty
                          ? district.toString().substring(0, 1).toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 24),
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
