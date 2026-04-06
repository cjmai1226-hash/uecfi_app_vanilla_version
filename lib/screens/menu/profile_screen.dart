import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/color_utils.dart';
import '../../widgets/main_app_bar.dart';
import 'recover_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late TextEditingController _districtController;
  late TextEditingController _positionController;
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _surnameController;
  late TextEditingController _dobController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _addressController;
  late TextEditingController _areaController;
  late TextEditingController _centerNameController;
  late TextEditingController _centerAddressController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _initControllers(settings);
  }

  void _initControllers(SettingsProvider settings) {
    _nicknameController = TextEditingController(text: settings.nickname);
    _emailController = TextEditingController(text: settings.email);
    _districtController = TextEditingController(text: settings.district);
    _positionController = TextEditingController(text: settings.position);
    _firstNameController = TextEditingController(text: settings.firstName);
    _middleNameController = TextEditingController(text: settings.middleName);
    _surnameController = TextEditingController(text: settings.surname);
    _dobController = TextEditingController(text: settings.dob);
    _phoneNumberController = TextEditingController(text: settings.phoneNumber);
    _addressController = TextEditingController(text: settings.address);
    _areaController = TextEditingController(text: settings.area);
    _centerNameController = TextEditingController(text: settings.centerName);
    _centerAddressController = TextEditingController(text: settings.centerAddress);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _districtController.dispose();
    _positionController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _surnameController.dispose();
    _dobController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _centerNameController.dispose();
    _centerAddressController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    if (_isEditing) return; // Prevent external links in edit mode
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  double _calculateCompletion(SettingsProvider settings) {
    final fields = [
      settings.firstName,
      settings.middleName,
      settings.surname,
      settings.nickname,
      settings.email,
      settings.district,
      settings.position,
      settings.dob,
      settings.phoneNumber,
      settings.address,
      settings.area,
      settings.centerName,
      settings.centerAddress,
    ];
    final filledFields = fields.where((f) => f.isNotEmpty).length;
    return filledFields / fields.length;
  }

  void _onCancel() {
    if (_isSaving) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('Are you sure you want to discard your edits? All changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final settings = context.read<SettingsProvider>();
              setState(() {
                _initControllers(settings);
                _isEditing = false;
              });
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    if (_nicknameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _firstNameController.text.trim().isEmpty ||
        _surnameController.text.trim().isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Please fill in Name, Email, and basic details.'),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // --- NEW: Nickname Uniqueness Validation ---
    final newNickname = _nicknameController.text.trim();
    if (newNickname != settings.nickname) {
      setState(() => _isSaving = true);
      try {
        final isTaken = await FirestoreService().checkNicknameExists(newNickname);
        if (isTaken) {
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: const Text('This nickname is already taken. Please choose a unique one for the community feed.'),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
            setState(() => _isSaving = false);
          }
          return;
        }
      } catch (e) {
        // Continue if check fails? Or stop? Better stop.
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error validating nickname: $e'), backgroundColor: theme.colorScheme.error),
          );
          setState(() => _isSaving = false);
        }
        return;
      }
    }
    // ------------------------------------------

    setState(() => _isSaving = true);

    try {
      context.read<SettingsProvider>().updateProfile(
        _nicknameController.text,
        _emailController.text,
        _districtController.text,
        _positionController.text,
        _firstNameController.text,
        _middleNameController.text,
        _surnameController.text,
        _dobController.text,
        _phoneNumberController.text,
        _addressController.text,
        _areaController.text,
        _centerNameController.text,
        _centerAddressController.text,
      );

      await FirestoreService().saveUserProfile(
        uid: settings.userId,
        email: _emailController.text.trim(),
        name: _nicknameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        surname: _surnameController.text.trim(),
        dob: _dobController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        address: _addressController.text.trim(),
        position: _positionController.text.trim(),
        district: _districtController.text.trim(),
        area: _areaController.text.trim(),
        centerName: _centerNameController.text.trim(),
        centerAddress: _centerAddressController.text.trim(),
      );

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), behavior: SnackBarBehavior.floating),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error syncing data: $e'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final completion = _calculateCompletion(settings);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: MainAppBar(
        title: _isEditing ? 'Editing Profile' : 'Member Detail',
        showBackButton: !_isEditing,
        actions: [
          if (_isEditing) ...[
            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              )
            else ...[
              IconButton(
                onPressed: _onCancel,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Cancel',
              ),
              IconButton(
                onPressed: _saveProfile,
                icon: const Icon(Icons.check_rounded, color: Colors.green),
                tooltip: 'Save',
              ),
            ],
          ] else
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildProfileHeader(context, settings, colorScheme),
            const SizedBox(height: 24),
            
            // Member ID Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.badge_rounded, color: colorScheme.secondary, size: 24),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEMBER DIGITAL ID',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.secondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          settings.userId,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSecondaryContainer,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: settings.userId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Member ID copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(Icons.copy_rounded, color: colorScheme.secondary, size: 20),
                    tooltip: 'Copy ID',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            if (!_isEditing && completion < 1.0) _buildCompletionCard(context, completion, colorScheme),
            const SizedBox(height: 16),
            _buildCardSection(
              context,
              'Contact Information',
              Icons.contact_mail_outlined,
              [
                _buildInfoTile(
                  context,
                  controller: _emailController,
                  icon: Icons.alternate_email_rounded,
                  label: 'Email',
                  value: settings.email,
                  onTap: () => _launchUrl('mailto:${settings.email}'),
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true, // Email is locked as a unique identifier
                ),
                _buildInfoTile(
                  context,
                  controller: _phoneNumberController,
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: settings.phoneNumber,
                  onTap: () => _launchUrl('tel:${settings.phoneNumber}'),
                  keyboardType: TextInputType.phone,
                ),
                _buildInfoTile(
                  context,
                  controller: _addressController,
                  icon: Icons.map_outlined,
                  label: 'Address',
                  value: settings.address,
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCardSection(
              context,
              'Personal Details',
              Icons.person_outline_rounded,
              [
                _buildInfoTile(
                  context,
                  controller: _dobController,
                  icon: Icons.cake_outlined,
                  label: 'Birthday',
                  value: settings.dob,
                  readOnly: true,
                  onTap: _isEditing ? () => _selectDate(context) : null,
                ),
                _buildInfoTile(
                  context,
                  controller: _firstNameController,
                  icon: Icons.badge_outlined,
                  label: 'First Name',
                  value: settings.firstName,
                ),
                _buildInfoTile(
                  context,
                  controller: _middleNameController,
                  icon: Icons.person_outline_rounded,
                  label: 'Middle Name',
                  value: settings.middleName,
                ),
                _buildInfoTile(
                  context,
                  controller: _surnameController,
                  icon: Icons.person_rounded,
                  label: 'Surname',
                  value: settings.surname,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCardSection(
              context,
              'Church Information',
              Icons.church_outlined,
              [
                _buildInfoTile(
                  context,
                  controller: _positionController,
                  icon: Icons.verified_user_outlined,
                  label: 'Role / Position',
                  value: settings.position,
                ),
                _buildInfoTile(
                  context,
                  controller: _districtController,
                  icon: Icons.location_city_outlined,
                  label: 'District',
                  value: settings.district,
                ),
                _buildInfoTile(
                  context,
                  controller: _areaController,
                  icon: Icons.near_me_outlined,
                  label: 'Area',
                  value: settings.area,
                ),
                _buildInfoTile(
                  context,
                  controller: _centerNameController,
                  icon: Icons.home_outlined,
                  label: 'Local Center',
                  value: settings.centerName,
                ),
                _buildInfoTile(
                  context,
                  controller: _centerAddressController,
                  icon: Icons.pin_drop_outlined,
                  label: 'Center Address',
                  value: settings.centerAddress,
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (!_isEditing) _buildRecoverCard(colorScheme),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _refreshControllers() {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    setState(() {
      _nicknameController.text = settings.nickname;
      _emailController.text = settings.email;
      _districtController.text = settings.district;
      _positionController.text = settings.position;
      _firstNameController.text = settings.firstName;
      _middleNameController.text = settings.middleName;
      _surnameController.text = settings.surname;
      _dobController.text = settings.dob;
      _phoneNumberController.text = settings.phoneNumber;
      _addressController.text = settings.address;
      _areaController.text = settings.area;
      _centerNameController.text = settings.centerName;
      _centerAddressController.text = settings.centerAddress;
    });
  }

  Widget _buildRecoverCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 32, color: colorScheme.primary),
          const SizedBox(height: 16),
          const Text(
            'Moving to a new device?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can recover your previous profile settings from the cloud.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecoverProfileScreen(),
                ),
              ).then((_) => _refreshControllers());
            },
            icon: const Icon(Icons.restore_page_rounded, size: 20),
            label: const Text('Recover Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    SettingsProvider settings,
    ColorScheme colorScheme,
  ) {
    final String nickname = _isEditing ? _nicknameController.text : settings.nickname;
    final String initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';
    final Color avatarColor = ColorUtils.getAvatarColor(nickname);

    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: nickname == 'DEVELOPER'
              ? Colors.amber.shade700
              : avatarColor,
          child: nickname == 'DEVELOPER'
              ? const Icon(Icons.verified_rounded,
                  color: Colors.white, size: 64)
              : Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
        ),
        const SizedBox(height: 24),
        if (_isEditing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: TextField(
              controller: _nicknameController,
              textAlign: TextAlign.center,
              onChanged: (val) => setState(() {}),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
              decoration: InputDecoration(
                hintText: 'Enter Nickname',
                border: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          )
        else
          Text(
            settings.nickname,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          settings.email.isEmpty ? 'New Member' : settings.email,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionCard(BuildContext context, double percentage, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.1), width: 1),
      ),
      color: colorScheme.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars_rounded, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Complete your profile',
                    style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.2,
                    ),
                  ),
                ),
                Text(
                  '${(percentage * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              minHeight: 12,
            ),
            const SizedBox(height: 12),
            Text(
              'Add more details to make it easier for the center to reach you.',
              style: TextStyle(
                fontSize: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7), height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSection(
    BuildContext context,
    String title,
    IconData sectionIcon,
    List<Widget> tiles,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Row(
            children: [
              Icon(sectionIcon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w900, color: colorScheme.primary, letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(color: colorScheme.outlineVariant, width: 1),
          ),
          color: colorScheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayValue = value.isEmpty ? 'Click to add' : value;
    final isPlaceholder = value.isEmpty;

    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20, color: colorScheme.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        ),
      );
    }

    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon, 
        color: isPlaceholder ? colorScheme.primary.withValues(alpha: 0.3) : colorScheme.primary, size: 20,
      ),
      title: Text(
        displayValue,
        style: TextStyle(
          fontSize: 16,
          color: isPlaceholder ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4) : colorScheme.onSurface,
          fontWeight: isPlaceholder ? FontWeight.w400 : FontWeight.w700,
        ),
      ),
      subtitle: Text(
        label,
        style: TextStyle(
          fontSize: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }
}
