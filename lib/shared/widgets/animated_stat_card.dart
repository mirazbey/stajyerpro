import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'premium_glass_container.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/settings_controller.dart';

class AnimatedStatCard extends ConsumerStatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String? trend;
  final bool? isPositiveTrend;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final double delay;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.trend,
    this.isPositiveTrend,
    required this.icon,
    this.gradientColors = const [
      Color(0xFF6366F1), // Indigo 500
      Color(0xFF8B5CF6), // Violet 500
    ],
    this.onTap,
    this.delay = 0,
  });

  @override
  ConsumerState<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends ConsumerState<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Check performance mode in post-frame callback or just run animation
    // We'll handle the "skip" logic in build or by checking provider here if possible
    // But accessing ref in initState is restricted.
    // Better to start animation, and if performance mode is on, we just show final state in build.

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final isPerformanceMode = settingsAsync.value?.performanceMode ?? false;

    if (isPerformanceMode) {
      // Return static content without animation wrapper
      return _buildCardContent();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: _buildCardContent(),
    );
  }

  Widget _buildCardContent() {
    return GestureDetector(
      onTap: widget.onTap,
      child: PremiumGlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradientColors.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 20),
                ),
                if (widget.trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (widget.isPositiveTrend ?? true)
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (widget.isPositiveTrend ?? true)
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: (widget.isPositiveTrend ?? true)
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.trend!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: (widget.isPositiveTrend ?? true)
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (widget.onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.3),
                    size: 14,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              widget.value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.title,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.subtitle!,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
