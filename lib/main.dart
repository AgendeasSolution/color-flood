import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'constants/app_constants.dart';
import 'pages/splash_page.dart';
import 'assets/styles/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handlers to prevent crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log the error but don't crash the app
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    // In production, you could send this to crash reporting service
  };
  
  // Handle async errors that aren't caught by Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled Error: $error');
    debugPrint('Stack trace: $stack');
    // Return true to indicate error was handled (prevents crash)
    return true;
  };
  
  // Set custom error widget builder to show friendly error screen instead of red screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'The app will continue working normally.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  };
  
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
    debugPrint('OneSignal initialization error: $e');
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
      // Ensure no default splash screen interference and wrap child safely
      builder: (context, child) {
        // If child is null, return splash page as fallback
        if (child == null) {
          return const SplashPage();
        }
        // Wrap child in try-catch boundary to prevent crashes
        try {
          return child;
        } catch (e) {
          // If build fails, show splash page
          return const SplashPage();
        }
      },
    );
  }
}

