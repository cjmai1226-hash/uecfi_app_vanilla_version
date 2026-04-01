import 'package:flutter/material.dart';
import '../../services/ad_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/settings_provider.dart';
import '../forms/update_center_screen.dart';

class CenterDetailScreen extends StatelessWidget {
  final Map<String, dynamic> centerNode;

  const CenterDetailScreen({super.key, required this.centerNode});

  Widget _buildListTile(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color primaryColor,
    double fontSize, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: primaryColor, size: 28),
      title: Text(
        label,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          value.isNotEmpty ? value : 'Not provided',
          style: TextStyle(color: textColor, fontSize: fontSize, height: 1.4),
        ),
      ),
      trailing: onTap != null
          ? Icon(Icons.open_in_new, color: primaryColor, size: 20)
          : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 8.0,
      ),
      onTap: onTap,
    );
  }

  Future<void> _openMap(String locationStr, String addressStr) async {
    String query = '';
    if (locationStr.isNotEmpty) {
      query = locationStr;
    } else if (addressStr.isNotEmpty) {
      query = addressStr;
    } else {
      return;
    }

    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openDialer(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('tel:$cleanNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    final name = centerNode['centername'] ?? 'Unknown Center';
    final address = centerNode['centeraddress']?.toString() ?? '';
    final location = centerNode['centerlocation']?.toString() ?? '';
    final rawDistrict = centerNode['centerdistrict']?.toString() ?? '';
    final status = centerNode['centerstatus'] ?? '';
    final contact = centerNode['centercontact'] ?? '';

    // The user moved from int codes (0, 1) to full text (Foreign-Based, District 1)
    // in the 'centerdistrict' field. We use this as our primary source for the district.
    final String district = rawDistrict.isNotEmpty ? rawDistrict : 'Uncategorized';

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Use centeraddress as primary location, fallback to centerlocation
    final String displayLocation = address.isNotEmpty ? address : location;

    final contactStr = contact.toString().trim();
    final contactParts = contactStr.split(',').map((e) => e.trim()).toList();

    String contactName = '';
    String contactPosition = '';
    String contactNumber = '';

    if (contactParts.isNotEmpty && contactParts[0].isNotEmpty) {
      if (contactParts.length == 1 && RegExp(r'\d').hasMatch(contactParts[0])) {
        contactNumber = contactParts[0];
      } else {
        contactName = contactParts[0];
      }
    }
    if (contactParts.length > 1 && contactParts[1].isNotEmpty) {
      contactPosition = contactParts[1];
    }
    if (contactParts.length > 2 && contactParts[2].isNotEmpty) {
      contactNumber = contactParts.sublist(2).join(', ').trim();
    }

    String completeContactDetails = '';
    if (contactName.isNotEmpty) completeContactDetails += contactName;
    if (contactPosition.isNotEmpty) {
      completeContactDetails += completeContactDetails.isNotEmpty
          ? '\n$contactPosition'
          : contactPosition;
    }
    if (contactNumber.isNotEmpty) {
      completeContactDetails += completeContactDetails.isNotEmpty
          ? '\n$contactNumber'
          : contactNumber;
    }

    final String completeContactDetailsFinal = completeContactDetails.trim();

    final bool missingLocation = location.toString().trim().isEmpty;
    final bool missingContact = contact.toString().trim().isEmpty;

    String missingInfoText = '';
    if (missingLocation && missingContact) {
      missingInfoText =
          "This center is not properly located yet and doesn't have a contact.";
    } else if (missingLocation) {
      missingInfoText = "This center is not properly located yet.";
    } else if (missingContact) {
      missingInfoText = "This center doesn't have a contact.";
    }

    final tiles = <Widget>[
      _buildListTile(
        Icons.church_outlined,
        'NAME',
        name.toString(),
        textColor,
        primaryColor,
        settings.fontSize,
      ),
      _buildListTile(
        Icons.map_outlined,
        'DISTRICT',
        district.toString(),
        textColor,
        primaryColor,
        settings.fontSize,
      ),
      _buildListTile(
        Icons.location_on_outlined,
        'ADDRESS / LOCATION',
        displayLocation,
        textColor,
        primaryColor,
        settings.fontSize,
        onTap: (address.toString().isNotEmpty || location.toString().isNotEmpty)
            ? () => _openMap(location.toString(), address.toString())
            : null,
      ),
      _buildListTile(
        Icons.person_outline,
        'CONTACT',
        completeContactDetailsFinal,
        textColor,
        primaryColor,
        settings.fontSize,
        onTap: contactNumber.isNotEmpty
            ? () => _openDialer(contactNumber)
            : null,
      ),
      _buildListTile(
        Icons.info_outline,
        'STATUS',
        status.toString(),
        textColor,
        primaryColor,
        settings.fontSize,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Center Details'),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UpdateCenterScreen(centerNode: centerNode),
                ),
              );
            },
            icon: const Icon(Icons.edit_note),
            label: const Text(
              'Suggest',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: ListTile.divideTiles(
                  context: context,
                  tiles: tiles,
                ).toList(),
              ),
            ),
            if (missingInfoText.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        missingInfoText,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 32),
            const AdBannerWidget(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
