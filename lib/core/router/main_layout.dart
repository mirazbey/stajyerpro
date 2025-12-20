import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/glass_bottom_nav_bar.dart';
import '../../core/theme/design_tokens.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  DateTime? _lastPressedAt;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/subjects') || location.startsWith('/exams')) {
      return 1;
    }
    if (location.startsWith('/analytics')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/exams'); // Deneme sınavları sayfasına yönlendir
        break;
      case 2:
        context.go('/analytics');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  Future<bool> _handleBackButton(BuildContext context) async {
    final String currentLocation = GoRouterState.of(context).uri.toString();
    final bool isOnDashboard = currentLocation.startsWith('/dashboard');
    
    // Eğer dashboard'da değilsek, dashboard'a git
    if (!isOnDashboard) {
      context.go('/dashboard');
      return false; // Pop'u engelle
    }
    
    // Dashboard'dayız - çift tıklama ile çıkış
    final now = DateTime.now();
    final maxDuration = const Duration(seconds: 2);
    final isWarningShown =
        _lastPressedAt != null &&
        now.difference(_lastPressedAt!) < maxDuration;

    if (isWarningShown) {
      await SystemNavigator.pop();
      return true;
    }

    _lastPressedAt = now;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Çıkmak için tekrar basın',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: DesignTokens.surfaceLight,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    return false; // Pop'u engelle
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackButton(context);
      },
      child: Scaffold(
        backgroundColor: DesignTokens.background,
        extendBody: true, // Important for glass effect
        body: Stack(
          children: [
            // Background Gradient (Global)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: DesignTokens.darkGradient,
                ),
              ),
            ),

            // Dark Overlay
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.8)),
            ),

            // Child Screen
            widget.child,

            // Bottom Nav Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GlassBottomNavBar(
                currentIndex: _calculateSelectedIndex(context),
                onTap: (index) => _onItemTapped(index, context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
