import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/chatgpt_widgets.dart';
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
    _areaController = TextEditingController(text: settings.area);
    _centerNameController = TextEditingController(text: settings.centerName);
    _centerAddressController = TextEditingController(
      text: settings.centerAddress,
    );
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
    _areaController.dispose();
    _centerNameController.dispose();
    _centerAddressController.dispose();
    super.dispose();
  }







  void _onCancel() {
    if (_isSaving) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'Are you sure you want to discard your edits? All changes will be lost.',
        ),
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
        final isTaken = await FirestoreService().checkNicknameExists(
          newNickname,
        );
        if (isTaken) {
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: const Text(
                  'This nickname is already taken. Please choose a unique one for the community feed.',
                ),
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
            SnackBar(
              content: Text('Error validating nickname: $e'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
          setState(() => _isSaving = false);
        }
        return;
      }
    }
    // ------------------------------------------

    setState(() => _isSaving = true);

    try {
      settings.updateProfile(
        _nicknameController.text,
        _emailController.text,
        _districtController.text,
        _positionController.text,
        _firstNameController.text,
        _middleNameController.text,
        _surnameController.text,
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
        position: _positionController.text.trim(),
        district: _districtController.text.trim(),
        area: _areaController.text.trim(),
        centerName: _centerNameController.text.trim(),
        centerAddress: _centerAddressController.text.trim(),
      );

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            _buildProfileHeader(context, settings, colorScheme),
            const SizedBox(height: 32),

            // Member ID Card
            ChatGPTCard(
              borderRadius: 12.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.badge_rounded,
                        color: isDark ? Colors.white : Colors.black,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MEMBER DIGITAL ID',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            settings.userId,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              letterSpacing: 0.5,
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
                      icon: Icon(
                        Icons.copy_rounded,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        size: 18,
                      ),
                      tooltip: 'Copy ID',
                    ),
                  ],
                ),
              ),
            ),


            const SizedBox(height: 24),
            _buildCardSection(
              context,
              'Personal Details',
              [
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
            const SizedBox(height: 24),
            _buildCardSection(
              context,
              'Church Information',
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
      _areaController.text = settings.area;
      _centerNameController.text = settings.centerName;
      _centerAddressController.text = settings.centerAddress;
    });
  }

  Widget _buildRecoverCard(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChatGPTCard(
      borderRadius: 12.0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 28,
              color: isDark ? Colors.white : Colors.black,
            ),
            const SizedBox(height: 12),
            const Text(
              'Moving to a new device?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can recover your previous profile settings from the cloud.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ChatGPTButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecoverProfileScreen(),
                  ),
                ).then((_) => _refreshControllers());
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restore_page_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Recover Profile',
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

  Widget _buildProfileHeader(
    BuildContext context,
    SettingsProvider settings,
    ColorScheme colorScheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String nickname = _isEditing
        ? _nicknameController.text
        : settings.nickname;
    final String initial = nickname.isNotEmpty
        ? nickname[0].toUpperCase()
        : '?';

    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: nickname == 'DEVELOPER'
              ? Colors.amber.shade700
              : (isDark ? Colors.white : const Color(0xFF0F0F0F)),
          child: nickname == 'DEVELOPER'
              ? const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 64,
                )
              : Text(
                  initial,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
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
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 2),
                ),
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



  Widget _buildCardSection(
    BuildContext context,
    String title,
    List<Widget> tiles,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<Widget> children = [];
    for (int i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);
      if (i < tiles.length - 1) {
        children.add(
          Divider(
            height: 1,
            indent: 52,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12, top: 12),
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
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final displayValue = value.isEmpty ? 'Click the edit button to add' : value;
    final isPlaceholder = value.isEmpty;

    if (_isEditing) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 20,
          ),
        ),
        title: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      );
    }

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isPlaceholder
              ? (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3))
              : (isDark ? Colors.white : Colors.black),
          size: 20,
        ),
      ),
      title: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      ),
      subtitle: Text(
        displayValue,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isPlaceholder
              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
              : colorScheme.onSurface,
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
    );
  }
}
