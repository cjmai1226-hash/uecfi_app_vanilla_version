import 'package:flutter/material.dart';

class TermsAgreementsScreen extends StatelessWidget {
  const TermsAgreementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Agreements'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By using this application, you agree to the following terms and guidelines:',
                style: TextStyle(
                  fontSize: 15,
                  color: textColor.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTile('1. Acceptance of Terms', textColor, primaryColor),
              _buildSectionContent('By accessing and using this application, you accept and agree to be bound by the terms and provisions of this agreement.', textColor),
              const SizedBox(height: 20),
              
              _buildSectionTile('2. Purpose and Conduct', textColor, primaryColor),
              _buildSectionContent('This application is designed to foster community and spiritual growth. Users are expected to maintain respectful, appropriate, and constructive conduct in all interactions.', textColor),
              const SizedBox(height: 20),

              _buildSectionTile('3. User Submissions', textColor, primaryColor),
              _buildSectionContent('Any content submitted by users (such as posts, comments, or directory updates) must not be malicious, offensive, or infringe upon the rights of others.', textColor),
              const SizedBox(height: 20),

              _buildSectionTile('4. Privacy and Data', textColor, primaryColor),
              _buildSectionContent('We are committed to protecting your privacy. Personal information collected through forms or profiles will be used solely for community directory and application functionality purposes. Do not submit contact information without explicit consent.', textColor),
              const SizedBox(height: 20),

              _buildSectionTile('5. Intellectual Property', textColor, primaryColor),
              _buildSectionContent('All content included on the app, such as text, graphics, logos, images, and software, is the property of the organization or its content suppliers.', textColor),
              const SizedBox(height: 20),

              _buildSectionTile('6. Disclaimer', textColor, primaryColor),
              _buildSectionContent('The application and its content are provided "as is". We make no warranties regarding the accuracy or completeness of the informational directories provided.', textColor),
              
              const SizedBox(height: 12),
            ],
          ),
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
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryColor,
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
        height: 1.5,
      ),
    );
  }
}
