import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../components/color_flood_logo.dart';
import '../constants/app_constants.dart';
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
    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _logoController.repeat(reverse: true);

    // Wait for splash duration (3 seconds)
    await Future.delayed(const Duration(seconds: 3));

    // Navigate to home page
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
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
          _buildAnimatedBackground(),
          
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
                            child: const ColorFloodLogo(
                              fontSize: 60,
                              enableHoverEffects: false,
                              enableFloatingAnimation: false,
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

  /// Creates a beautiful animated background similar to home page
  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
            Color(0xFF533A7B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Floating particles
          ...List.generate(20, (index) => _buildFloatingParticle(index)),
          
          // Glowing orbs
          ...List.generate(12, (index) => _buildGlowingOrb(index)),
          
          // Color swatches
          ...List.generate(10, (index) => _buildFloatingColorSwatch(index)),
          
          // Subtle overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Creates floating particles
  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = 2.0 + random.nextDouble() * 3.0;
    
    final x = random.nextDouble();
    final y = random.nextDouble();
    
    return Positioned(
      left: x * MediaQuery.of(context).size.width,
      top: y * MediaQuery.of(context).size.height,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: [
            const Color(0xFFEF4444),
            const Color(0xFFEC4899),
            const Color(0xFF3B82F6),
            const Color(0xFF10B981),
            const Color(0xFFF59E0B),
          ][index % 5].withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: [
                const Color(0xFFEF4444),
                const Color(0xFFEC4899),
                const Color(0xFF3B82F6),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
              ][index % 5].withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  /// Creates glowing orbs
  Widget _buildGlowingOrb(int index) {
    final random = math.Random(index + 100);
    final size = 40.0 + random.nextDouble() * 60.0;
    
    final x = random.nextDouble();
    final y = random.nextDouble();
    
    return Positioned(
      left: x * MediaQuery.of(context).size.width,
      top: y * MediaQuery.of(context).size.height,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              [
                const Color(0xFFEF4444),
                const Color(0xFFEC4899),
                const Color(0xFF3B82F6),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
              ][index % 5].withOpacity(0.15),
              [
                const Color(0xFFEF4444),
                const Color(0xFFEC4899),
                const Color(0xFF3B82F6),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
              ][index % 5].withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: [
                const Color(0xFFEF4444),
                const Color(0xFFEC4899),
                const Color(0xFF3B82F6),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
              ][index % 5].withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  /// Creates floating color swatches
  Widget _buildFloatingColorSwatch(int index) {
    final random = math.Random(index + 200);
    final size = 20.0 + random.nextDouble() * 15.0;
    
    final x = random.nextDouble();
    final y = random.nextDouble();
    final rotation = random.nextDouble() * 2 * math.pi;
    
    return Positioned(
      left: x * MediaQuery.of(context).size.width,
      top: y * MediaQuery.of(context).size.height,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                [
                  const Color(0xFFEF4444),
                  const Color(0xFFEC4899),
                  const Color(0xFF3B82F6),
                  const Color(0xFF10B981),
                  const Color(0xFFF59E0B),
                ][index % 5].withOpacity(0.3),
                [
                  const Color(0xFFEF4444),
                  const Color(0xFFEC4899),
                  const Color(0xFF3B82F6),
                  const Color(0xFF10B981),
                  const Color(0xFFF59E0B),
                ][index % 5].withOpacity(0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: [
                  const Color(0xFFEF4444),
                  const Color(0xFFEC4899),
                  const Color(0xFF3B82F6),
                  const Color(0xFF10B981),
                  const Color(0xFFF59E0B),
                ][index % 5].withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
