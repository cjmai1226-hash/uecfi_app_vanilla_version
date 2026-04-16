import 'package:flutter/material.dart';
import 'setup_screen.dart';
import '../menu/recover_profile_screen.dart';


class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              colorScheme.surface,
              colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // App Logo or Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.church_rounded,
                  size: 80,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 48),
              // Welcome Text
              Text(
                'Welcome to UECFI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your digital companion for spiritual growth and community connection. Start your journey with us today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OnboardingSetupScreen()),
                    );
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Log In to Existing Account Button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecoverProfileScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'Log In to Existing Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'It only takes a minute to set up.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
