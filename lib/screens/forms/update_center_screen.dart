import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../menu/edit_profile_screen.dart';

class UpdateCenterScreen extends StatefulWidget {
  final Map<String, dynamic> centerNode;

  const UpdateCenterScreen({super.key, required this.centerNode});

  @override
  State<UpdateCenterScreen> createState() => _UpdateCenterScreenState();
}

class _UpdateCenterScreenState extends State<UpdateCenterScreen> {
  String _selectedType = 'Location Locator'; // Default Dropdown value
  bool _isSubmitting = false;

  // Location Controllers
  final _latLngController = TextEditingController();
  final _mapsLinkController = TextEditingController();
  final _locationNotesController = TextEditingController();

  // Contact Controllers
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
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Account Setup Required'),
          content: const Text(
            'To maintain community trust and data integrity, please update your profile nickname and email before submitting suggestions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
              child: const Text('Go to Profile'),
            ),
          ],
        ),
      );
      return;
    }

    // Determine which check to run based on the selected dropdown form
    if (_selectedType == 'Location Locator') {
      if (_latLngController.text.isEmpty && _mapsLinkController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please provide either Latitude/Longitude or a Google Maps Link.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
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
          ),
        );
        return;
      }

      // Explicit consent dialog for privacy
      final bool? consent = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Consent Required',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Do you have the explicit consent of this person to share their direct contact information within the community directory?',
            style: TextStyle(height: 1.4, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false), // Dismiss and return false
              child: const Text(
                'No, cancel',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true), // Proceed and return true
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Yes, I have consent',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      // Halt submission if they hit No or dismissed the dialog
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
        Navigator.pop(context); // Go back to Center Details
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

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggest Update'),
        centerTitle: true,
        elevation: 0,
        actions: [
          _isSubmitting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton.icon(
                  onPressed: _submitUpdate,
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: const Text(
                    'Submit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          children: [
            // Header Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'Help us keep the directory accurate! Select the type of information you are contributing for ${widget.centerNode['centername'] ?? 'this center'}.',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form Content Block
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Information Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    dropdownColor: surfaceColor,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: textColor.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    items: ['Location Locator', 'Contact Person']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Dynamic Form Injection based on explicit Dropdown string
                  if (_selectedType == 'Location Locator') ...[
                    _buildTextField(
                      _latLngController,
                      'Latitude / Longitude',
                      Icons.explore_outlined,
                      textColor,
                    ),
                    _buildTextField(
                      _mapsLinkController,
                      'Google Maps Link',
                      Icons.add_link,
                      textColor,
                    ),
                    _buildTextField(
                      _locationNotesController,
                      'Additional Notes (Optional)',
                      Icons.notes,
                      textColor,
                    ),
                  ] else ...[
                    _buildTextField(
                      _nameController,
                      'Contact Name',
                      Icons.person_outline,
                      textColor,
                    ),
                    _buildTextField(
                      _positionController,
                      'Role / Position',
                      Icons.badge_outlined,
                      textColor,
                      helperText: 'Example: (Member or Local President)',
                    ),
                    _buildTextField(
                      _contactNumberController,
                      'Contact Number',
                      Icons.phone_outlined,
                      textColor,
                      isPhone: true,
                    ),
                    _buildTextField(
                      _contactNotesController,
                      'Additional Notes (Optional)',
                      Icons.notes,
                      textColor,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            const SizedBox(height: 20),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper widget to rapidly construct matching standard UI TextField configurations
  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    Color textColor, {
    bool isPhone = false,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: hint,
          prefixIcon: Icon(icon, size: 20, color: textColor.withValues(alpha: 0.6)),
          filled: true,
          fillColor: textColor.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          helperText: helperText,
          helperStyle: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 12,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
