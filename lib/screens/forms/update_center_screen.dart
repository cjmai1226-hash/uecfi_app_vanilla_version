import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../menu/profile_screen.dart';
import '../../widgets/chatgpt_widgets.dart';

class UpdateCenterSheet extends StatefulWidget {
  final Map<String, dynamic> centerNode;

  const UpdateCenterSheet({super.key, required this.centerNode});

  /// Opens the Suggest Edit bottom sheet.
  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> centerNode,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => UpdateCenterSheet(centerNode: centerNode),
    );
  }

  @override
  State<UpdateCenterSheet> createState() => _UpdateCenterSheetState();
}

class _UpdateCenterSheetState extends State<UpdateCenterSheet> {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.1);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ───────────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ────────────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggest Edit',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.centerNode['centername'] ?? 'this center',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Info banner ───────────────────────────────────────────────────
            ChatGPTCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All suggestions are reviewed by community/administrators before being applied to the database.',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Type selector ─────────────────────────────────────────────────
            Text(
              'INFORMATION TYPE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: colorScheme.primary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              dropdownColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              items: ['Location Locator', 'Contact Person']
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        type,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),

            const SizedBox(height: 20),

            // ── Fields ────────────────────────────────────────────────────────
            if (_selectedType == 'Location Locator') ...[
              ChatGPTTextField(
                controller: _latLngController,
                label: 'Latitude / Longitude',
                icon: Icons.explore_rounded,
              ),
              ChatGPTTextField(
                controller: _mapsLinkController,
                label: 'Google Maps Link',
                icon: Icons.link_rounded,
              ),
              ChatGPTTextField(
                controller: _locationNotesController,
                label: 'Additional Notes',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
            ] else ...[
              ChatGPTTextField(
                controller: _nameController,
                label: 'Contact Name',
                icon: Icons.person_rounded,
              ),
              ChatGPTTextField(
                controller: _positionController,
                label: 'Role / Position',
                hintText: 'Example: Local President',
                icon: Icons.badge_rounded,
              ),
              ChatGPTTextField(
                controller: _contactNumberController,
                label: 'Contact Number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              ChatGPTTextField(
                controller: _contactNotesController,
                label: 'Additional Notes',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
            ],

            // ── Submit button ─────────────────────────────────────────────────
            const SizedBox(height: 8),
            ChatGPTButton(
              onPressed: _isSubmitting ? null : _submitUpdate,
              isLoading: _isSubmitting,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Submit Suggestion',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
