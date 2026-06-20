import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../../navigation/app_navigation.dart';
import '../../widgets/chatgpt_design_system.dart';

class TermsAgreementsScreen extends StatefulWidget {
  final bool isOnboarding;

  const TermsAgreementsScreen({super.key, this.isOnboarding = false});

  @override
  State<TermsAgreementsScreen> createState() => _TermsAgreementsScreenState();
}

class _TermsAgreementsScreenState extends State<TermsAgreementsScreen> {
  bool _hasAccepted = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Agreements'),
        centerTitle: true,
        elevation: 0,
        // Hide back button during onboarding to prevent accidental exit
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: ChatGPTCard(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'By using this application, you agree to the following terms and guidelines:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textColor.withValues(alpha: 0.85),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTile('1. Acceptance of Terms', textColor, primaryColor),
                      _buildSectionContent(
                          'By accessing and using this application, you accept and agree to be bound by the terms and provisions of this agreement.',
                          textColor),
                      const SizedBox(height: 20),
                      _buildSectionTile('2. Purpose and Conduct', textColor, primaryColor),
                      _buildSectionContent(
                          'This application is designed to foster community and spiritual growth. Users are expected to maintain respectful, appropriate, and constructive conduct in all interactions.',
                          textColor),
                      const SizedBox(height: 20),
                      _buildSectionTile('3. User Submissions', textColor, primaryColor),
                      _buildSectionContent(
                          'Any content submitted by users (such as posts, comments, or directory updates) must not be malicious, offensive, or infringe upon the rights of others.',
                          textColor),
                      const SizedBox(height: 20),
                      _buildSectionTile('4. Privacy and Data', textColor, primaryColor),
                      _buildSectionContent(
                          'We are committed to protecting your privacy. Personal information collected through forms or profiles will be used solely for community directory and application functionality purposes.',
                          textColor),
                      const SizedBox(height: 20),
                      _buildSectionTile('5. Intellectual Property', textColor, primaryColor),
                      _buildSectionContent(
                          'All content included on the app, such as text, graphics, logos, images, and software, is the property of the organization or its content suppliers.',
                          textColor),
                      const SizedBox(height: 20),
                      _buildSectionTile('6. Disclaimer', textColor, primaryColor),
                      _buildSectionContent(
                          'The application and its content are provided "as is". We make no warranties regarding the accuracy or completeness of the informational directories provided.',
                          textColor),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.isOnboarding)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: _hasAccepted,
                      activeColor: isDark ? Colors.white : const Color(0xFF0F0F0F),
                      checkColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                      checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => setState(() => _hasAccepted = val ?? false),
                      title: const Text(
                        'I have read and agree to the community terms and guidelines.',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 20),
                    ChatGPTButton(
                      onPressed: (_hasAccepted && !_isSaving)
                          ? () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);
                              
                              setState(() => _isSaving = true);
                              try {
                                final settings = context.read<SettingsProvider>();
                                
                                // 1. Save locally
                                settings.setHasAcceptedTerms(true);
                                
                                // 2. Save to Firestore (Makes email taken)
                                await FirestoreService().saveUserProfile(
                                  uid: settings.userId,
                                  email: settings.email,
                                  name: settings.nickname,
                                  firstName: settings.firstName,
                                  middleName: settings.middleName,
                                  surname: settings.surname,
                                  position: settings.position,
                                  district: settings.district,
                                  area: settings.area,
                                  centerName: settings.centerName,
                                  centerAddress: settings.centerAddress,
                                );

                                if (!mounted) return;
                                
                                // Explicitly navigate and clear stack to ensure user goes to home
                                navigator.pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const AppNavigation()),
                                  (route) => false,
                                );
                              } catch (e) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Error finalizing setup: $e')),
                                  );
                                  setState(() => _isSaving = false);
                                }
                              }
                            }
                          : null,
                      isLoading: _isSaving,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Accept & Proceed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
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

  Widget _buildSectionTile(String title, Color textColor, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content, Color textColor) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 14,
        color: textColor.withValues(alpha: 0.7),
        height: 1.6,
      ),
    );
  }
}

