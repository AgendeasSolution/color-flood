import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../services/update_service.dart';
import '../services/audio_service.dart';
import '../utils/responsive_utils.dart';

/// Update pop-up widget that appears at the bottom of the screen
/// Only shows when an update is available
class UpdatePopup extends StatefulWidget {
  const UpdatePopup({super.key});

  @override
  State<UpdatePopup> createState() => _UpdatePopupState();
}

class _UpdatePopupState extends State<UpdatePopup> with SingleTickerProviderStateMixin {
  final UpdateService _updateService = UpdateService.instance;
  final AudioService _audioService = AudioService();
  bool _isVisible = false;
  bool _isChecking = true;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkForUpdate();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for updates when page becomes visible again
    // This ensures popup appears when returning to home page
    if (!_isChecking && !_isVisible) {
      _checkForUpdate();
    }
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Start from bottom
      end: Offset.zero, // End at position
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
  }

  Future<void> _checkForUpdate() async {
    try {
      // Check if popup should be shown (automatically checks for update and ensures once per day)
      final shouldShow = await _updateService.shouldShowPopup();
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isVisible = shouldShow;
        });
        
        if (shouldShow) {
          // Mark popup as shown for today
          await _updateService.markPopupShown();
          // Slide in the pop-up automatically
          _slideController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isVisible = false;
        });
      }
    }
  }

  Future<void> _onUpdatePressed() async {
    _audioService.playClickSound();
    
    try {
      final storeUrl = _updateService.getStoreUrl();
      if (storeUrl.isNotEmpty) {
        final uri = Uri.parse(storeUrl);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open app store'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open app store'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _onLaterPressed() async {
    _audioService.playClickSound();
    
    // Slide out the pop-up
    await _slideController.reverse();
    
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
      
      // Mark as dismissed so it won't show again until next update check
      await _updateService.dismissUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render anything if not visible or still checking
    if (!_isVisible || _isChecking) {
      return const SizedBox.shrink();
    }

    // Full screen backdrop with popup content
    return Positioned.fill(
      child: Stack(
        children: [
          // Semi-transparent backdrop that closes on tap outside
          GestureDetector(
            onTap: _onLaterPressed,
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          // Popup content that slides in from bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: () {}, // Absorb taps on popup content
                child: _buildPopupContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupContent() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: ResponsiveUtils.getResponsiveSpacing(
              context,
              smallPhone: 16,
              mediumPhone: 18,
              largePhone: 20,
              tablet: 24,
            ),
            right: ResponsiveUtils.getResponsiveSpacing(
              context,
              smallPhone: 16,
              mediumPhone: 18,
              largePhone: 20,
              tablet: 24,
            ),
            top: ResponsiveUtils.getResponsiveSpacing(
              context,
              smallPhone: 12,
              mediumPhone: 14,
              largePhone: 16,
              tablet: 18,
            ),
            bottom: ResponsiveUtils.getResponsiveSpacing(
              context,
              smallPhone: 20,
              mediumPhone: 24,
              largePhone: 28,
              tablet: 32,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Centered Heading
              Text(
                AppConstants.updateAvailableTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    smallPhone: 24,
                    mediumPhone: 26,
                    largePhone: 28,
                    tablet: 30,
                  ),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 12,
                  mediumPhone: 14,
                  largePhone: 16,
                  tablet: 18,
                ),
              ),
              // Large Color Flood Logo Image
              Container(
                width: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 100,
                  mediumPhone: 110,
                  largePhone: 120,
                  tablet: 130,
                ),
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 100,
                  mediumPhone: 110,
                  largePhone: 120,
                  tablet: 130,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/img/color-flood.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 12,
                  mediumPhone: 14,
                  largePhone: 16,
                  tablet: 18,
                ),
              ),
              // Message
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    smallPhone: 12,
                    mediumPhone: 16,
                    largePhone: 20,
                    tablet: 24,
                  ),
                ),
                child: Text(
                  AppConstants.updateAvailableMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      smallPhone: 16,
                      mediumPhone: 17,
                      largePhone: 18,
                      tablet: 19,
                    ),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    height: 1.6,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 10,
                  mediumPhone: 12,
                  largePhone: 14,
                  tablet: 16,
                ),
              ),
              // Centered Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Later button
                  _buildActionButton(
                    text: AppConstants.laterButtonText,
                    onPressed: _onLaterPressed,
                    isSecondary: true,
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      smallPhone: 12,
                      mediumPhone: 14,
                      largePhone: 16,
                      tablet: 18,
                    ),
                  ),
                  // Update button - WIDER
                  Expanded(
                    flex: 2,
                    child: _buildActionButton(
                      text: AppConstants.updateButtonText,
                      onPressed: _onUpdatePressed,
                      isSecondary: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required bool isSecondary,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSecondary
                  ? [
                      Colors.white.withOpacity(0.18),
                      Colors.white.withOpacity(0.10),
                    ]
                  : [
                      const Color(0xFF22C55E).withOpacity(0.6), // Green from game
                      const Color(0xFF10B981).withOpacity(0.5),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSecondary
                  ? Colors.white.withOpacity(0.25)
                  : const Color(0xFF22C55E).withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: isSecondary
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.15),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    smallPhone: 20,
                    mediumPhone: 24,
                    largePhone: 28,
                    tablet: 32,
                  ),
                  vertical: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    smallPhone: 14,
                    mediumPhone: 15,
                    largePhone: 16,
                    tablet: 17,
                  ),
                ),
                child: Center(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        smallPhone: 16,
                        mediumPhone: 17,
                        largePhone: 18,
                        tablet: 19,
                      ),
                      fontWeight: isSecondary ? FontWeight.w600 : FontWeight.w700,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

