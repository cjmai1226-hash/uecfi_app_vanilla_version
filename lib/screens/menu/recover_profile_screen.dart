import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/main_app_bar.dart';

class RecoverProfileScreen extends StatefulWidget {
  const RecoverProfileScreen({super.key});

  @override
  State<RecoverProfileScreen> createState() => _RecoverProfileScreenState();
}

class _RecoverProfileScreenState extends State<RecoverProfileScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  bool _isRecovering = false;

  @override
  void dispose() {
    _emailController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _recoverProfile() async {
    final email = _emailController.text.trim();
    final userId = _userIdController.text.trim();

    if (email.isEmpty || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email and User ID are required.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isRecovering = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        if (data['uid'] == userId) {
          if (!mounted) return;
          // Match found
          final settings = context.read<SettingsProvider>();
          settings.recoverProfile(
            userId,
            data['name'] ?? 'User',
            email,
            data['district'] ?? '',
            data['position'] ?? '',
            data['firstName'] ?? '',
            data['middleName'] ?? '',
            data['surname'] ?? '',
            data['area'] ?? '',
            data['centerName'] ?? '',
            data['centerAddress'] ?? '',
          );
          settings.setHasAcceptedTerms(true);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile recovered successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); // Go back to previous screen
          }
        } else {
          // User ID mismatch
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Invalid User ID for this Email.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      } else {
        // Email not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No profile found with this Email.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recovering profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRecovering = false);
      }
    }
  }

  Future<void> _requestRecovery() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'uecfiapps@gmail.com',
      query:
          'subject=Profile Recovery Request&body=Hello, I need help recovering my profile. My Email is: ',
    );
    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not open email client. Please email uecfiapps@gmail.com.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: const MainAppBar(
        title: 'Recover Profile',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Restore your profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your previous Email Address and User ID to reconnect to your profile.',
                style: TextStyle(color: textColor.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(fontSize: 16, color: textColor),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _userIdController,
                style: TextStyle(fontSize: 16, color: textColor),
                decoration: InputDecoration(
                  labelText: 'User ID (e.g. UE-US-...)',
                  labelStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isRecovering ? null : _recoverProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isRecovering
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Recover Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _requestRecovery,
                child: Text(
                  'Forgot User ID? Request Recovery',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
