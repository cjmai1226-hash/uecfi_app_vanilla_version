import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_helper.dart';
import '../menu/terms_agreements_screen.dart';
import '../../services/firestore_service.dart';

class OnboardingSetupScreen extends StatefulWidget {
  const OnboardingSetupScreen({super.key});

  @override
  State<OnboardingSetupScreen> createState() => _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends State<OnboardingSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _districtController = TextEditingController();
  final _centerNameController = TextEditingController();
  final _centerAddressController = TextEditingController();

  List<Map<String, dynamic>> _allCenters = [];
  Map<String, dynamic>? _selectedCenterMap;
  bool _isManualCenter = false;
  bool _isLoadingCenters = true;
  bool _isCheckingEmail = false;

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    try {
      final centers = await DatabaseHelper().getCenters();
      if (mounted) {
        setState(() {
          _allCenters = centers;
          _isLoadingCenters = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCenters = false);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _districtController.dispose();
    _centerNameController.dispose();
    _centerAddressController.dispose();
    super.dispose();
  }

  void _showCenterPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CenterPickerSheet(
        centers: _allCenters,
        onSelect: (center) {
          setState(() {
            if (center == null) {
              _isManualCenter = true;
              _selectedCenterMap = null;
              _districtController.clear();
              _centerNameController.clear();
              _centerAddressController.clear();
            } else {
              _isManualCenter = false;
              _selectedCenterMap = center;
              _districtController.text = center['centerdistrict'] ?? '';
              _centerNameController.text = center['centername'] ?? '';
              _centerAddressController.text = center['centeraddress'] ?? '';
            }
          });
        },
      ),
    );
  }

  Future<void> _onProceed() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isCheckingEmail = true);
      
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final theme = Theme.of(context);

      try {
        final email = _emailController.text.trim();
        final nickname = _nicknameController.text.trim();
        
        // 1. Check Email
        final isEmailTaken = await FirestoreService().checkEmailExists(email);
        if (!mounted) return;
        
        if (isEmailTaken) {
          messenger.showSnackBar(
            SnackBar(
              content: const Text('This email is already registered. Please use another or recover your profile.'),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isCheckingEmail = false);
          return;
        }

        // 2. Check Nickname
        final isNicknameTaken = await FirestoreService().checkNicknameExists(nickname);
        if (!mounted) return;

        if (isNicknameTaken) {
          messenger.showSnackBar(
            SnackBar(
              content: const Text('This nickname is already taken. Please choose a unique one for the community feed.'),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isCheckingEmail = false);
          return;
        }

        final settings = context.read<SettingsProvider>();
        settings.updateProfile(
          _nicknameController.text.trim(),
          email,
          _districtController.text.trim(),
          settings.position,
          _firstNameController.text.trim(),
          settings.middleName,
          _surnameController.text.trim(),
          settings.dob,
          settings.phoneNumber,
          settings.address,
          settings.area,
          _centerNameController.text.trim(),
          _centerAddressController.text.trim(),
        );

        navigator.push(
          MaterialPageRoute(
            builder: (_) => const TermsAgreementsScreen(isOnboarding: true),
          ),
        );
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error validating subscription: $e'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isCheckingEmail = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Setup'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent going back to Welcome screen
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about yourself',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide your details to keep the community vibrant and connected.',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Member ID Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.badge_rounded, color: colorScheme.secondary, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEMBER ID',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.secondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          context.read<SettingsProvider>().userId,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              _buildModernField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.badge_outlined,
                colorScheme: colorScheme,
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              _buildModernField(
                controller: _surnameController,
                label: 'Surname',
                icon: Icons.person_rounded,
                colorScheme: colorScheme,
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              _buildModernField(
                controller: _nicknameController,
                label: 'Nickname',
                icon: Icons.face_rounded,
                colorScheme: colorScheme,
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              _buildModernField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                colorScheme: colorScheme,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (!val.contains('@')) return 'Invalid Email';
                  return null;
                },
              ),
              const Divider(height: 48),
              Text(
                'Church Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              
              // Center Selector
              InkWell(
                onTap: _isLoadingCenters ? null : _showCenterPicker,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.church_rounded, color: colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isManualCenter 
                                ? 'Other / Not Listed' 
                                : (_selectedCenterMap?['centername'] ?? 'Select Local Center'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (!_isManualCenter && _selectedCenterMap == null)
                              Text(
                                'Find your local church center',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              if (!_isManualCenter && _selectedCenterMap != null)
                _buildReadOnlyInfoCard(colorScheme),

              if (_isManualCenter) ...[
                const SizedBox(height: 8),
                _buildModernField(
                  controller: _districtController,
                  label: 'District',
                  icon: Icons.location_city_outlined,
                  colorScheme: colorScheme,
                  validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                ),
                _buildModernField(
                  controller: _centerNameController,
                  label: 'Local Center Name',
                  icon: Icons.home_work_outlined,
                  colorScheme: colorScheme,
                  validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                ),
                _buildModernField(
                  controller: _centerAddressController,
                  label: 'Center Address',
                  icon: Icons.pin_drop_outlined,
                  colorScheme: colorScheme,
                  validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                ),
              ],
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: (_isLoadingCenters || _isCheckingEmail) ? null : _onProceed,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isCheckingEmail
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Next: Community Guidelines',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyInfoCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadOnlyRow(Icons.location_city_rounded, 'District', _districtController.text, colorScheme),
          const SizedBox(height: 12),
          _buildReadOnlyRow(Icons.pin_drop_rounded, 'Address', _centerAddressController.text, colorScheme),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: colorScheme.primary, size: 22),
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: colorScheme.error, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

class _CenterPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> centers;
  final Function(Map<String, dynamic>?) onSelect;

  const _CenterPickerSheet({required this.centers, required this.onSelect});

  @override
  State<_CenterPickerSheet> createState() => _CenterPickerSheetState();
}

class _CenterPickerSheetState extends State<_CenterPickerSheet> {
  late List<Map<String, dynamic>> _filteredCenters;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCenters = widget.centers;
  }

  void _filterCenters(String query) {
    setState(() {
      _filteredCenters = widget.centers
          .where((c) =>
              (c['centername'] ?? '').toString().toLowerCase().contains(query.toLowerCase()) ||
              (c['centerdistrict'] ?? '').toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Local Center',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _filterCenters,
                  decoration: InputDecoration(
                    hintText: 'Search by name or district...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredCenters.length + 1,
              itemBuilder: (context, index) {
                if (index == _filteredCenters.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 32),
                    child: ListTile(
                      onTap: () {
                        widget.onSelect(null);
                        Navigator.pop(context);
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_location_alt_rounded, color: colorScheme.secondary),
                      ),
                      title: const Text(
                        'Other / Not Listed',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: const Text('Enter your center details manually'),
                    ),
                  );
                }

                final center = _filteredCenters[index];
                return ListTile(
                  onTap: () {
                    widget.onSelect(center);
                    Navigator.pop(context);
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.church_rounded, color: colorScheme.primary, size: 20),
                  ),
                  title: Text(
                    center['centername'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    center['centerdistrict'] ?? 'No District',
                    style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
