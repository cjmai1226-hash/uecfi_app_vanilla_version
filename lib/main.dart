import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'navigation/app_navigation.dart';
import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/bookmark_provider.dart';
import 'services/ad_service.dart';
import 'screens/onboarding/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid || Platform.isIOS) {
    debugPrint("✅Initializing AdMob...");
    await AdService().initializeMobileAds();
    AdService().loadAndShowAppOpenAd();
  } else {
    debugPrint("❌Unsupported platform - AdMob disabled");
  }

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    if (Platform.isWindows) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyAXdY8JXgmOPiUmn4BCwTBhhcRHj7FT-LI',
          appId: '1:741354382245:web:d3623d316a80e3daa1be4c',
          messagingSenderId: '741354382245',
          projectId: 'uecfi-zaoqsg',
          authDomain: 'uecfi-zaoqsg.firebaseapp.com',
          storageBucket: 'uecfi-zaoqsg.firebasestorage.app',
          measurementId: 'G-7XXNJM47LN',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    debugPrint("✅Firebase initialized successfully");
  } catch (e) {
    debugPrint("❌Firebase initialization error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'UECFI App',
      theme: AppTheme.themeData(
        isDarkMode: settings.isDarkMode,
        seedColor: settings.colorSeed,
        fontStyle: settings.fontStyle,
      ),
      home: settings.isProfileSetup && settings.hasAcceptedTerms
          ? const AppNavigation()
          : const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
