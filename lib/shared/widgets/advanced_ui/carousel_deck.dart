import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D Cover Flow Carousel
class Carousel3D extends StatefulWidget {
  final List<Widget> items;
  final double itemWidth;
  final double itemHeight;
  final double viewportFraction;
  final ValueChanged<int>? onPageChanged;
  final int initialIndex;
  final bool autoPlay;
  final Duration autoPlayDuration;
  final bool enableInfiniteScroll;

  const Carousel3D({
    super.key,
    required this.items,
    this.itemWidth = 280,
    this.itemHeight = 400,
    this.viewportFraction = 0.75,
    this.onPageChanged,
    this.initialIndex = 0,
    this.autoPlay = false,
    this.autoPlayDuration = const Duration(seconds: 4),
    this.enableInfiniteScroll = false,
  });

  @override
  State<Carousel3D> createState() => _Carousel3DState();
}

class _Carousel3DState extends State<Carousel3D> {
  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _currentPage = widget.initialIndex.toDouble();

    _pageController =
        PageController(
          viewportFraction: widget.viewportFraction,
          initialPage: widget.initialIndex,
        )..addListener(() {
          setState(() {
            _currentPage = _pageController.page ?? 0;
          });
        });

    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    Future.delayed(widget.autoPlayDuration, () {
      if (mounted && widget.autoPlay) {
        final nextPage = _pageController.page!.round() + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
        _startAutoPlay();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.itemHeight + 60, // Extra space for shadows/transform
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.enableInfiniteScroll ? null : widget.items.length,
        onPageChanged: (index) {
          final actualIndex = widget.enableInfiniteScroll
              ? index % widget.items.length
              : index;
          widget.onPageChanged?.call(actualIndex);
        },
        itemBuilder: (context, index) {
          final actualIndex = widget.enableInfiniteScroll
              ? index % widget.items.length
              : index;
          return _buildCoverFlowItem(index, widget.items[actualIndex]);
        },
      ),
    );
  }

  Widget _buildCoverFlowItem(int index, Widget child) {
    if (_currentPage.isNaN) return child;
    final difference = index - _currentPage;
    final absDiff = difference.abs();

    // Cover Flow Parameters
    final maxRotation = 0.3; // Radians
    final scaleFactor = 0.2;
    final opacityFactor = 0.4;

    // Calculate transform values
    final rotationY = -difference.clamp(-1.0, 1.0) * maxRotation;
    final scale = 1.0 - (absDiff * scaleFactor).clamp(0.0, 0.4);
    final opacity = 1.0 - (absDiff * opacityFactor).clamp(0.0, 0.6);
    final translateZ = -absDiff * 100; // Push back

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspective
        ..rotateY(rotationY)
        ..translate(0.0, 0.0, translateZ)
        ..scale(scale, scale, scale),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: widget.itemWidth,
          height: widget.itemHeight,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.3 * (1 - absDiff.clamp(0.0, 1.0)),
                ),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Deck Style View - Gelişmiş Kart Destesi
class DeckView extends StatefulWidget {
  final List<Widget> cards;
  final double cardHeight;
  final double cardWidth;
  final double stackOffset;
  final int visibleCards;
  final Duration animationDuration;
  final VoidCallback? onTapTop;

  const DeckView({
    super.key,
    required this.cards,
    this.cardHeight = 200,
    this.cardWidth = 300,
    this.stackOffset = 15,
    this.visibleCards = 3,
    this.animationDuration = const Duration(milliseconds: 400),
    this.onTapTop,
  });

  @override
  State<DeckView> createState() => DeckViewState();
}

class DeckViewState extends State<DeckView>
    with SingleTickerProviderStateMixin {
  int _topCardIndex = 0;
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void nextCard() {
    if (_isAnimating || _topCardIndex >= widget.cards.length - 1) return;

    setState(() => _isAnimating = true);
    _controller.forward(from: 0).then((_) {
      setState(() {
        _topCardIndex++;
        _isAnimating = false;
      });
      _controller.reset();
    });
  }

  void previousCard() {
    if (_isAnimating || _topCardIndex <= 0) return;

    setState(() {
      _topCardIndex--;
      _isAnimating = true;
    });
    // Reverse animation logic would be different, simplified here
    _controller.forward(from: 0).then((_) {
      // Using forward for simplicity in this demo
      setState(() => _isAnimating = false);
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = math.min(
      widget.visibleCards,
      widget.cards.length - _topCardIndex,
    );

    if (visibleCount <= 0) return const SizedBox();

    return GestureDetector(
      onTap: () {
        widget.onTapTop?.call();
        nextCard();
      },
      child: SizedBox(
        height: widget.cardHeight + (widget.stackOffset * widget.visibleCards),
        width: widget.cardWidth,
        child: Stack(
          alignment: Alignment.topCenter,
          children: List.generate(visibleCount, (index) {
            // Render from back to front
            final reverseIndex = visibleCount - 1 - index;
            final cardIndex = _topCardIndex + reverseIndex;

            // 0 is top card, 1 is behind, etc.
            final stackIndex = reverseIndex;

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double yOffset = stackIndex * widget.stackOffset;
                double scale = 1.0 - (stackIndex * 0.05);
                double opacity = 1.0 - (stackIndex * 0.2);
                double xOffset = 0;
                double rotation = 0;

                // Animating the top card (flying away)
                if (stackIndex == 0 && _isAnimating) {
                  // Fly to right and rotate
                  xOffset = _slideAnimation.value * 400;
                  rotation = _slideAnimation.value * 0.2;
                  opacity = 1.0 - _slideAnimation.value;
                }
                // Animating cards behind (moving up)
                else if (_isAnimating) {
                  // Interpolate to next position (stackIndex - 1)
                  final targetY = (stackIndex - 1) * widget.stackOffset;
                  final targetScale = 1.0 - ((stackIndex - 1) * 0.05);

                  yOffset =
                      yOffset - (yOffset - targetY) * _slideAnimation.value;
                  scale = scale + (targetScale - scale) * _slideAnimation.value;
                }

                return Positioned(
                  top: yOffset,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..translate(xOffset, 0.0, 0.0)
                      ..rotateZ(rotation)
                      ..scale(scale, scale, scale),
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Container(
                        width: widget.cardWidth,
                        height: widget.cardHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 15,
                              offset: Offset(0, 5 + (stackIndex * 2.0)),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: widget.cards[cardIndex],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
