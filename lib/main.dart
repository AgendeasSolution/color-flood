import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'constants/app_constants.dart';
import 'pages/splash_page.dart';
import 'assets/styles/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (must be done before any Firebase services)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Log error but allow app to continue
    // Firebase initialization failure should not prevent app from working
    debugPrint('Firebase initialization error: $e');
  }
  
  // Initialize OneSignal push notifications (non-blocking)
  // App will work even if this fails or user denies permission
  try {
    OneSignal.initialize(AppConstants.oneSignalAppId);
    // Request permission non-blocking (don't wait for user response)
    // App continues to work regardless of permission status
    OneSignal.Notifications.requestPermission(false);
  } catch (e) {
    // Silently fail - app must continue working
    // OneSignal initialization failure should not affect gameplay
  }
  
  runApp(const ColorFloodApp());
}

/// Main application widget
class ColorFloodApp extends StatelessWidget {
  const ColorFloodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashPage(),
      debugShowCheckedModeBanner: false,
      // Ensure no default splash screen interference
      builder: (context, child) {
        return child ?? const SplashPage();
      },
    );
  }
}

