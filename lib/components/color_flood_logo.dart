import 'package:flutter/material.dart';
import 'dart:math';

/// Color Flood Logo component with gradient text effects and animations
class ColorFloodLogo extends StatefulWidget {
  final double? fontSize;
  final bool enableHoverEffects;
  final bool enableFloatingAnimation;
  final Duration animationDuration;
  final Duration staggerDelay;

  const ColorFloodLogo({
    super.key,
    this.fontSize,
    this.enableHoverEffects = true,
    this.enableFloatingAnimation = true,
    this.animationDuration = const Duration(milliseconds: 3000),
    this.staggerDelay = const Duration(milliseconds: 200),
  });

  @override
  State<ColorFloodLogo> createState() => _ColorFloodLogoState();
}

class _ColorFloodLogoState extends State<ColorFloodLogo>
    with TickerProviderStateMixin {
  late List<AnimationController> _letterControllers;
  late List<AnimationController> _hoverControllers;
  late List<Animation<double>> _floatingAnimations;
  late List<Animation<double>> _hoverAnimations;

  // Letter gradient definitions
  static const List<List<Color>> _letterGradients = [
    // C - Red gradient
    [Color(0xFFEF4444), Color(0xFFF87171), Color(0xFFFCA5A5)],
    // O - Blue gradient
    [Color(0xFF3B82F6), Color(0xFF60A5FA), Color(0xFF93C5FD)],
    // L - Green gradient
    [Color(0xFF22C55E), Color(0xFF4ADE80), Color(0xFF86EFAC)],
    // O - Yellow gradient
    [Color(0xFFFFFF00), Color(0xFFFDE047), Color(0xFFFEF08A)],
    // R - Orange gradient
    [Color(0xFFFFA500), Color(0xFFFB923C), Color(0xFFFDBA74)],
    // F - Pink gradient
    [Color(0xFFEC4899), Color(0xFFF472B6), Color(0xFFF9A8D4)],
    // L - Purple gradient
    [Color(0xFF8B5CF6), Color(0xFFA78BFA), Color(0xFFC4B5FD)],
    // O - Cyan gradient
    [Color(0xFF06B6D4), Color(0xFF22D3EE), Color(0xFF67E8F9)],
    // O - Lime gradient
    [Color(0xFF84CC16), Color(0xFFA3E635), Color(0xFFBEF264)],
    // D - Amber gradient
    [Color(0xFFF59E0B), Color(0xFFFBBF24), Color(0xFFFCD34D)],
  ];

  static const String _titleText = 'Color Flood';
  static const List<int> _letterIndices = [0, 1, 2, 3, 4, 6, 7, 8, 9, 10]; // Skip space at index 5

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _letterControllers = List.generate(_letterIndices.length, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: widget.animationDuration,
      );
      
      // Stagger the animation start times
      Future.delayed(Duration(milliseconds: index * widget.staggerDelay.inMilliseconds), () {
        if (mounted && widget.enableFloatingAnimation) {
          controller.repeat(reverse: true);
        }
      });
      
      return controller;
    });

    _hoverControllers = List.generate(_letterIndices.length, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    });

    _floatingAnimations = _letterControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    _hoverAnimations = _hoverControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _letterControllers) {
      controller.dispose();
    }
    for (var controller in _hoverControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double _getResponsiveFontSize(BuildContext context) {
    if (widget.fontSize != null) return widget.fontSize!;
    
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 32.0; // Smaller for very small screens
    } else if (screenWidth < 480) {
      return 40.0; // Smaller for small mobile
    } else if (screenWidth < 768) {
      return 48.0; // Smaller for mobile
    } else {
      return 64.0; // Smaller for desktop
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = _getResponsiveFontSize(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_titleText.length, (index) {
            if (_titleText[index] == ' ') {
              return SizedBox(width: fontSize * 0.15); // Reduced spacing
            }

            final letterIndex = _letterIndices.indexOf(index);
            if (letterIndex == -1) return const SizedBox.shrink();

            return Flexible(
              child: _buildAnimatedLetter(
                letter: _titleText[index],
                letterIndex: letterIndex,
                fontSize: fontSize,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildAnimatedLetter({
    required String letter,
    required int letterIndex,
    required double fontSize,
  }) {
    return MouseRegion(
      onEnter: widget.enableHoverEffects ? (_) => _hoverControllers[letterIndex].forward() : null,
      onExit: widget.enableHoverEffects ? (_) => _hoverControllers[letterIndex].reverse() : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _floatingAnimations[letterIndex],
          _hoverAnimations[letterIndex],
        ]),
        builder: (context, child) {
          final floatingOffset = widget.enableFloatingAnimation
              ? -4 * sin(_floatingAnimations[letterIndex].value * 2 * pi)
              : 0.0;
          
          final hoverOffset = widget.enableHoverEffects
              ? -10 * _hoverAnimations[letterIndex].value
              : 0.0;
          
          final hoverScale = widget.enableHoverEffects
              ? 1.0 + (0.1 * _hoverAnimations[letterIndex].value)
              : 1.0;

          return Transform.translate(
            offset: Offset(0, floatingOffset + hoverOffset),
            child: Transform.scale(
              scale: hoverScale,
              child: _buildGradientText(
                letter: letter,
                gradient: _letterGradients[letterIndex],
                fontSize: fontSize,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradientText({
    required String letter,
    required List<Color> gradient,
    required double fontSize,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white, // This will be masked by the gradient
          shadows: const [
            Shadow(
              color: Color.fromRGBO(0, 0, 0, 0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
