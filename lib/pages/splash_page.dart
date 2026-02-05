import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../components/animated_background.dart';
import '../utils/responsive_utils.dart';
import 'home_page.dart';

/// Custom splash screen with logo and developer information
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _logoController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Fade animation for overall content
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Scale animation for logo
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Logo floating animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );
  }

  void _startSplashSequence() async {
    try {
      // Start animations with error handling
      try {
        _fadeController.forward();
      } catch (e) {
        // Continue even if animation fails
      }
      
      try {
        _scaleController.forward();
      } catch (e) {
        // Continue even if animation fails
      }
      
      try {
        _logoController.repeat(reverse: true);
      } catch (e) {
        // Continue even if animation fails
      }

      // Wait for splash duration (3 seconds)
      await Future.delayed(const Duration(seconds: 3));

      // Navigate to home page with error handling
      if (mounted && context.mounted) {
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          );
        } catch (e) {
          // If navigation fails, try again after a short delay
          if (mounted && context.mounted) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && context.mounted) {
                try {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const HomePage(),
                    ),
                  );
                } catch (e2) {
                  // Continue even if retry fails
                }
              }
            });
          }
        }
      }
    } catch (e) {
      // Even if everything fails, try to navigate to home page
      if (mounted && context.mounted) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted && context.mounted) {
            try {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
              );
            } catch (e2) {
              // Continue even if final attempt fails
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          const AnimatedBackground(),
          
          // Main Content
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Logo centered in available space
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _logoAnimation,
                      builder: (context, child) {
                        final floatingOffset = -8 * math.sin(_logoAnimation.value * 2 * math.pi);
                        return Transform.translate(
                          offset: Offset(0, floatingOffset),
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Image.asset(
                              'assets/img/color_flood_logo.png',
                              width: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                smallPhone: 220.0,
                                mediumPhone: 275.0,
                                largePhone: 330.0,
                                tablet: 440.0,
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Developer text at bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _buildDeveloperText(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperText() {
    return Column(
      children: [
        // "Developed by" text
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 2000),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: const Text(
                  'Developed by',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: Colors.white70,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 4),
        
        // "FGTP Labs" text
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 2000),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: const Text(
                  'FGTP Labs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

}
