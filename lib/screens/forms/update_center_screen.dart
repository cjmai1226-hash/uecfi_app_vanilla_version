import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../menu/profile_screen.dart';

class UpdateCenterScreen extends StatefulWidget {
  final Map<String, dynamic> centerNode;

  const UpdateCenterScreen({super.key, required this.centerNode});

  @override
  State<UpdateCenterScreen> createState() => _UpdateCenterScreenState();
}

class _UpdateCenterScreenState extends State<UpdateCenterScreen> {
  String _selectedType = 'Location Locator';
  bool _isSubmitting = false;

  final _latLngController = TextEditingController();
  final _mapsLinkController = TextEditingController();
  final _locationNotesController = TextEditingController();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _contactNotesController = TextEditingController();

  @override
  void dispose() {
    _latLngController.dispose();
    _mapsLinkController.dispose();
    _locationNotesController.dispose();
    _nameController.dispose();
    _positionController.dispose();
    _contactNumberController.dispose();
    _contactNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    final settings = context.read<SettingsProvider>();

    if (!settings.isProfileSetup) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text(
            'Account Setup Required',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'To maintain community trust and data integrity, please update your profile nickname and email before submitting suggestions.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: const Text(
                'Go to Profile',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (_selectedType == 'Location Locator') {
      if (_latLngController.text.isEmpty && _mapsLinkController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please provide either Latitude/Longitude or a Google Maps Link.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else {
      if (_nameController.text.isEmpty ||
          _contactNumberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please provide the Contact Name and Number.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final bool? consent = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: Icon(
            Icons.privacy_tip_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          title: const Text(
            'Consent Required',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Do you have the explicit consent of this person to share their contact information within the community directory?',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.4, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'No, cancel',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Yes, I have consent',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

      if (consent != true) return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final settings = context.read<SettingsProvider>();

      Map<String, dynamic> payload = {};
      if (_selectedType == 'Location Locator') {
        payload = {
          'latLng': _latLngController.text,
          'mapsLink': _mapsLinkController.text,
          'notes': _locationNotesController.text,
        };
      } else {
        payload = {
          'name': _nameController.text,
          'position': _positionController.text,
          'contactNumber': _contactNumberController.text,
          'notes': _contactNotesController.text,
          'consentGranted': true,
        };
      }

      await FirestoreService().submitCenterUpdate(
        centerId: widget.centerNode['id']?.toString() ?? 'unknown',
        centerName:
            widget.centerNode['centername']?.toString() ?? 'Unknown Center',
        centerAddress:
            widget.centerNode['centeraddress']?.toString() ?? 'No address',
        updateType: _selectedType,
        payload: payload,
        submittedByEmail: settings.email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update suggestion submitted for review!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit update: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildModernField(
    TextEditingController controller,
    String label,
    IconData icon,
    ColorScheme colorScheme, {
    bool isPhone = false,
    String? helperText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: colorScheme.primary, size: 20),
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          helperText: helperText,
          helperStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 11,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggest Update'),
        centerTitle: true,
        actions: [
          _isSubmitting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton.filled(
                  tooltip: 'Submit',
                  icon: const Icon(Icons.send_rounded, size: 18),
                  onPressed: _submitUpdate,
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Contributing updates for ${widget.centerNode['centername'] ?? 'this center'}. All suggestions are reviewed by the community.',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    'INFORMATION TYPE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  dropdownColor: colorScheme.surface,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  items: ['Location Locator', 'Contact Person']
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedType = value);
                  },
                ),
                const SizedBox(height: 24),
                if (_selectedType == 'Location Locator') ...[
                  _buildModernField(
                    _latLngController,
                    'Latitude / Longitude',
                    Icons.explore_rounded,
                    colorScheme,
                  ),
                  _buildModernField(
                    _mapsLinkController,
                    'Google Maps Link',
                    Icons.link_rounded,
                    colorScheme,
                  ),
                  _buildModernField(
                    _locationNotesController,
                    'Additional Notes',
                    Icons.notes_rounded,
                    colorScheme,
                    maxLines: 3,
                  ),
                ] else ...[
                  _buildModernField(
                    _nameController,
                    'Contact Name',
                    Icons.person_rounded,
                    colorScheme,
                  ),
                  _buildModernField(
                    _positionController,
                    'Role / Position',
                    Icons.badge_rounded,
                    colorScheme,
                    helperText: 'Example: Local President',
                  ),
                  _buildModernField(
                    _contactNumberController,
                    'Contact Number',
                    Icons.phone_rounded,
                    colorScheme,
                    isPhone: true,
                  ),
                  _buildModernField(
                    _contactNotesController,
                    'Additional Notes',
                    Icons.notes_rounded,
                    colorScheme,
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
