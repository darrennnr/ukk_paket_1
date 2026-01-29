// lib/screens/splash/splash_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:paket_3_training/core/design_system/app_color.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  bool get _isMobilePlatform {
    // Check if running on web
    if (kIsWeb) return false;
    // Check for mobile platforms (Android/iOS)
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> _navigateAfterDelay() async {
    // If not mobile, navigate to login immediately
    if (!_isMobilePlatform) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
      return;
    }

    // On mobile, show splash for 2.5 seconds then navigate
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not mobile, show nothing (will redirect immediately)
    if (!_isMobilePlatform) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.shrink(),
      );
    }

    final size = MediaQuery.sizeOf(context);
    final isSmallScreen = size.height < 600;

    // Responsive logo size
    final logoSize = size.width * 0.35;
    final clampedLogoSize = logoSize.clamp(100.0, 180.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo Container with subtle border
              Container(
                    width: clampedLogoSize,
                    height: clampedLogoSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.asset(
                        'assets/images/icon.jpg',
                        width: clampedLogoSize,
                        height: clampedLogoSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),

              SizedBox(height: isSmallScreen ? 24 : 40),

              // App Title
              Text(
                    'Sistem Peminjaman',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 22 : 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.surfaceColor,
                      letterSpacing: -0.5,
                    ),
                  )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 4),

              Text(
                    'Buku',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 22 : 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                      letterSpacing: -0.5,
                    ),
                  )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              SizedBox(height: isSmallScreen ? 8 : 12),

              // Tagline
              Text(
                'Kelola peminjaman dengan mudah',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.surfaceColor.withOpacity(0.6),
                  letterSpacing: 0.2,
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 500.ms),

              const Spacer(flex: 2),

              const Spacer(flex: 1),
              SizedBox(height: isSmallScreen ? 20 : 32),
            ],
          ),
        ),
      ),
    );
  }
}
