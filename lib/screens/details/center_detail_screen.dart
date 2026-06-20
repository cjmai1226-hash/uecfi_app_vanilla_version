import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../forms/update_center_screen.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/chatgpt_design_system.dart';

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

  String _extractPhoneNumber(String contactStr) {
    if (contactStr.isEmpty) return '';
    final parts = contactStr.split(',').map((p) => p.trim()).toList();
    return parts.last;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    backgroundColor: isDark ? Colors.white : const Color(0xFF0F0F0F),
                    child: Text(
                      name.toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.8,
                      height: 1.1,
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
                  context,
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
                  context,
                  Icons.contact_support_rounded,
                  'Contact info not provided',
                  'No phone number found for this center.',
                  onDismiss: () => setState(() => _showContactAlert = false),
                ),
              const SizedBox(height: 32),
            ],

            // Info Sections — single unified list
            _buildInfoCard(
              context,
              title: 'Center Info',
              children: [
                _buildInfoTile(
                  context,
                  icon: Icons.map_rounded,
                  label: 'Full Address / Location',
                  value: displayLocation.isNotEmpty
                      ? displayLocation
                      : 'Location details unavailable',
                ),
                Divider(
                  height: 1,
                  indent: 52,
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                ),
                _buildInfoTile(
                  context,
                  icon: Icons.location_city_rounded,
                  label: 'District',
                  value: district,
                ),
                Divider(
                  height: 1,
                  indent: 52,
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                ),
                _buildInfoTile(
                  context,
                  icon: Icons.phone_rounded,
                  label: 'Primary Contact',
                  value: hasContact
                      ? contactParts.split(',').map((p) => p.trim()).join('\n')
                      : 'Not provided',
                ),
                Divider(
                  height: 1,
                  indent: 52,
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                ),
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
    final hasRoute = location.isNotEmpty || address.isNotEmpty;
    final String phoneNumber = _extractPhoneNumber(contact);
    final hasCall = phoneNumber.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ChatGPTButton(
                onPressed: hasRoute ? () => _openMap(location, address) : null,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Route',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChatGPTButton(
                onPressed: hasCall ? () => _openDialer(phoneNumber) : null,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.call_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Call',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ChatGPTButton(
          onPressed: () => UpdateCenterSheet.show(context, widget.centerNode),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_note_rounded, size: 18),
              SizedBox(width: 8),
              Text(
                'Suggest Edit',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlert(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onDismiss,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorBg = isDark ? const Color(0xFF2D1F1F) : const Color(0xFFFDF2F2);
    final errorBorder = isDark ? const Color(0xFF6E2A2A) : const Color(0xFFF5C2C2);
    final errorTextColor = isDark ? const Color(0xFFF9A8A8) : const Color(0xFF9B1C1C);
    final closeButtonColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: errorTextColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: errorTextColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: errorTextColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded,
                size: 18, color: closeButtonColor),
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
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
              letterSpacing: 1.5,
            ),
          ),
        ),
        ChatGPTCard(
          borderRadius: 12.0,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          height: 1.4,
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
            )
          : null,
      onTap: onTap,
    );
  }
}
