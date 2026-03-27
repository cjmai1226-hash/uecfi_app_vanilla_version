import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import 'recover_profile_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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

  late int _selectedAvatarIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
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
    _centerAddressController =
        TextEditingController(text: settings.centerAddress);
    _selectedAvatarIndex = settings.avatarIndex;
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _saveProfile() async {
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);

    if (_nicknameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _firstNameController.text.trim().isEmpty ||
        _surnameController.text.trim().isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content:
              const Text('Nickname, Email, Firstname and Surname are required.'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      settings.updateProfile(
        _nicknameController.text.trim(),
        _emailController.text.trim(),
        _selectedAvatarIndex,
        _districtController.text.trim(),
        _positionController.text.trim(),
        _firstNameController.text.trim(),
        _middleNameController.text.trim(),
        _surnameController.text.trim(),
        _dobController.text.trim(),
        _phoneNumberController.text.trim(),
        _addressController.text.trim(),
        _areaController.text.trim(),
        _centerNameController.text.trim(),
        _centerAddressController.text.trim(),
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
          const SnackBar(
            content: Text('Profile synced to Cloud successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to sync profile: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildModernField(
    TextEditingController controller,
    String label,
    IconData icon,
    Color textColor, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(
          fontSize: 15,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: textColor.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        elevation: 0,
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          children: [
            // Avatar Selector
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avatar Icon',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: SettingsProvider.avatarIcons.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final isSelected = _selectedAvatarIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAvatarIndex = index;
                            });
                          },
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: isSelected
                                ? primaryColor
                                : primaryColor.withValues(alpha: 0.1),
                            child: Icon(
                              SettingsProvider.avatarIcons[index],
                              color: isSelected ? surfaceColor : primaryColor,
                              size: 28,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form Content
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernField(
                    TextEditingController(
                      text: context.read<SettingsProvider>().userId,
                    ),
                    'User ID',
                    Icons.fingerprint,
                    textColor,
                    readOnly: true,
                  ),
                  _buildModernField(
                    _nicknameController,
                    'Nickname',
                    Icons.face,
                    textColor,
                  ),

                  const SizedBox(height: 16),
                  _buildSectionHeader('Personal Details', textColor),
                  _buildModernField(
                    _firstNameController,
                    'First Name',
                    Icons.person_outline,
                    textColor,
                  ),
                  _buildModernField(
                    _middleNameController,
                    'Middle Name',
                    Icons.person_outline,
                    textColor,
                  ),
                  _buildModernField(
                    _surnameController,
                    'Surname',
                    Icons.person_outline,
                    textColor,
                  ),
                  _buildModernField(
                    _dobController,
                    'Date of Birth',
                    Icons.calendar_today_outlined,
                    textColor,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  _buildModernField(
                    _emailController,
                    'Email Address',
                    Icons.email_outlined,
                    textColor,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildModernField(
                    _phoneNumberController,
                    'Phone Number',
                    Icons.phone_outlined,
                    textColor,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 16),
                  _buildSectionHeader('Address', textColor),
                  _buildModernField(
                    _addressController,
                    'Home Address',
                    Icons.home_outlined,
                    textColor,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),
                  _buildSectionHeader('Church Info', textColor),
                  _buildModernField(
                    _positionController,
                    'Position / Role',
                    Icons.badge_outlined,
                    textColor,
                  ),
                  _buildModernField(
                    _districtController,
                    'District',
                    Icons.map_outlined,
                    textColor,
                  ),
                  _buildModernField(
                    _areaController,
                    'Area',
                    Icons.location_city_outlined,
                    textColor,
                  ),
                  _buildModernField(
                    _centerNameController,
                    'Center Name',
                    Icons.church_outlined,
                    textColor,
                  ),
                  _buildModernField(
                    _centerAddressController,
                    'Center Address',
                    Icons.location_on_outlined,
                    textColor,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecoverProfileScreen(),
                          ),
                        ).then((_) {
                          if (!context.mounted) return;
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
                            _centerAddressController.text =
                                settings.centerAddress;
                            _selectedAvatarIndex = settings.avatarIndex;
                          });
                        });
                      },
                      icon: Icon(Icons.restore, color: primaryColor),
                      label: Text(
                        'Recover Previous Profile',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
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
