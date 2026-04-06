import 'package:flutter/material.dart';
import '../../services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../forms/update_center_screen.dart';
import '../../widgets/main_app_bar.dart';

class CenterDetailScreen extends StatefulWidget {
  final Map<String, dynamic> centerNode;

  const CenterDetailScreen({super.key, required this.centerNode});

  @override
  State<CenterDetailScreen> createState() => _CenterDetailScreenState();
}

class _CenterDetailScreenState extends State<CenterDetailScreen> {
  bool _showLocationAlert = true;
  bool _showContactAlert = true;

  Future<void> _openMap(String locationStr, String addressStr) async {
    String query = locationStr.isNotEmpty ? locationStr : addressStr;
    if (query.isEmpty) return;

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
    final colorScheme = Theme.of(context).colorScheme;

    final name = widget.centerNode['centername'] ?? 'Unknown Center';
    final address = widget.centerNode['centeraddress']?.toString() ?? '';
    final location = widget.centerNode['centerlocation']?.toString() ?? '';
    final rawDistrict =
        widget.centerNode['centerdistrict']?.toString() ?? '';
    final status = widget.centerNode['centerstatus'] ?? '';
    final contact = widget.centerNode['centercontact']?.toString() ?? '';

    final String district =
        rawDistrict.isNotEmpty ? rawDistrict : 'Uncategorized';
    final String displayLocation = address.isNotEmpty ? address : location;
    final String contactParts = contact.trim();

    final bool hasLocation = location.isNotEmpty;
    final bool hasContact = contactParts.isNotEmpty;

    return Scaffold(
      appBar: const MainAppBar(
        title: 'Center Detail',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      name.toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      district.toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSecondaryContainer,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Action Row
            _buildActionRow(
                context, colorScheme, location, address, contactParts),
            const SizedBox(height: 32),

            // Missing Data Alerts (Dismissable)
            if ((!hasLocation && _showLocationAlert) ||
                (!hasContact && _showContactAlert)) ...[
              if (!hasLocation && _showLocationAlert)
                _buildAlert(
                  colorScheme,
                  Icons.location_off_rounded,
                  'Center is not Located properly',
                  'Missing precise coordinates for mapping.',
                  onDismiss: () => setState(() => _showLocationAlert = false),
                ),
              if (!hasLocation &&
                  _showLocationAlert &&
                  !hasContact &&
                  _showContactAlert)
                const SizedBox(height: 12),
              if (!hasContact && _showContactAlert)
                _buildAlert(
                  colorScheme,
                  Icons.contact_support_rounded,
                  'Contact info not provided',
                  'No phone number found for this center.',
                  onDismiss: () => setState(() => _showContactAlert = false),
                ),
              const SizedBox(height: 32),
            ],

            // Info Sections
            _buildInfoCard(
              context,
              title: 'Location Detail',
              children: [
                _buildInfoTile(
                  context,
                  icon: Icons.map_rounded,
                  label: 'Full Address / Location',
                  value: displayLocation.isNotEmpty
                      ? displayLocation
                      : 'Location details unavailable',
                  onTap: (address.isNotEmpty || location.isNotEmpty)
                      ? () => _openMap(location, address)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: 'Additional Info',
              children: [
                _buildInfoTile(
                  context,
                  icon: Icons.phone_rounded,
                  label: 'Primary Contact',
                  value: hasContact ? contactParts : 'Not provided',
                  onTap: hasContact ? () => _openDialer(contactParts) : null,
                ),
                const Divider(indent: 52),
                _buildInfoTile(
                  context,
                  icon: Icons.info_rounded,
                  label: 'Operational Status',
                  value: status.toString().isNotEmpty
                      ? status.toString()
                      : 'Active',
                ),
              ],
            ),

            const SizedBox(height: 48),
            const AdBannerWidget(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    ColorScheme colorScheme,
    String location,
    String address,
    String contact,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context,
          icon: Icons.directions_rounded,
          label: 'Route',
          onTap: (location.isNotEmpty || address.isNotEmpty)
              ? () => _openMap(location, address)
              : null,
        ),
        _buildActionButton(
          context,
          icon: Icons.call_rounded,
          label: 'Call',
          onTap: contact.isNotEmpty ? () => _openDialer(contact) : null,
        ),
        _buildActionButton(
          context,
          icon: Icons.edit_note_rounded,
          label: 'Suggest Edit',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UpdateCenterScreen(centerNode: widget.centerNode),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDisabled
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDisabled
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                    : colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDisabled
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                    : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlert(
    ColorScheme colorScheme,
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onDismiss,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.error, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.error,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onErrorContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded,
                size: 18, color: colorScheme.onSurfaceVariant),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: colorScheme.primary.withValues(alpha: 0.5),
            )
          : null,
      onTap: onTap,
    );
  }
}
