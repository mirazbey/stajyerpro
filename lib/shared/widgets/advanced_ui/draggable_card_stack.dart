import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Draggable Kart Yığını - Tinder tarzı swipe
class DraggableCardStack<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T item, int index) cardBuilder;
  final void Function(T item, SwipeDirection direction)? onSwipe;
  final void Function()? onEmpty;
  final int visibleCards;
  final double cardHeight;
  final double cardWidth;
  final double stackOffset;
  final double scaleDecrement;
  final Duration animationDuration;

  const DraggableCardStack({
    super.key,
    required this.items,
    required this.cardBuilder,
    this.onSwipe,
    this.onEmpty,
    this.visibleCards = 3,
    this.cardHeight = 400,
    this.cardWidth = 300,
    this.stackOffset = 10,
    this.scaleDecrement = 0.05,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<DraggableCardStack<T>> createState() => DraggableCardStackState<T>();
}

class DraggableCardStackState<T> extends State<DraggableCardStack<T>>
    with TickerProviderStateMixin {
  late List<T> _items;
  Offset _dragOffset = Offset.zero;
  double _dragRotation = 0;
  late AnimationController _springController;
  late AnimationController _dismissController;
  Animation<Offset>? _springAnimation;
  Animation<Offset>? _dismissAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _springController = AnimationController(vsync: this);
    _dismissController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    _dismissController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _springController.stop();
    _dismissController.stop();
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _dragRotation = _dragOffset.dx * 0.0015;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    final velocity = details.velocity.pixelsPerSecond;
    final speed = velocity.distance;

    // Swipe threshold
    if (_dragOffset.dx.abs() > 100 || speed > 800) {
      final direction = _dragOffset.dx > 0 
          ? SwipeDirection.right 
          : SwipeDirection.left;
      _dismissCard(direction);
    } else if (_dragOffset.dy < -100 || (velocity.dy < -500 && _dragOffset.dy < 0)) {
      _dismissCard(SwipeDirection.up);
    } else {
      _springBack();
    }
  }

  void _springBack() {
    final spring = SpringDescription(
      mass: 1,
      stiffness: 500,
      damping: 25,
    );

    final simulation = SpringSimulation(spring, 0, 1, -_springController.velocity);
    
    _springAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutBack,
    ));

    _springController.animateWith(simulation);
    
    _springController.addListener(() {
      if (_springAnimation != null) {
        setState(() {
          _dragOffset = _springAnimation!.value;
          _dragRotation = _dragOffset.dx * 0.0015;
        });
      }
    });
  }

  void _dismissCard(SwipeDirection direction) {
    final screenSize = MediaQuery.of(context).size;
    Offset targetOffset;

    switch (direction) {
      case SwipeDirection.left:
        targetOffset = Offset(-screenSize.width * 1.5, _dragOffset.dy);
        break;
      case SwipeDirection.right:
        targetOffset = Offset(screenSize.width * 1.5, _dragOffset.dy);
        break;
      case SwipeDirection.up:
        targetOffset = Offset(_dragOffset.dx, -screenSize.height);
        break;
      case SwipeDirection.down:
        targetOffset = Offset(_dragOffset.dx, screenSize.height);
        break;
    }

    _dismissAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(
      parent: _dismissController,
      curve: Curves.easeOut,
    ));

    _dismissController.forward(from: 0).then((_) {
      if (_items.isNotEmpty) {
        final removedItem = _items.removeAt(0);
        widget.onSwipe?.call(removedItem, direction);
        
        if (_items.isEmpty) {
          widget.onEmpty?.call();
        }

        setState(() {
          _dragOffset = Offset.zero;
          _dragRotation = 0;
        });
        _dismissController.reset();
      }
    });

    _dismissController.addListener(() {
      if (_dismissAnimation != null) {
        setState(() {
          _dragOffset = _dismissAnimation!.value;
          _dragRotation = _dragOffset.dx * 0.0015;
        });
      }
    });
  }

  /// Dışarıdan kart swipe etmek için
  void swipe(SwipeDirection direction) {
    if (_items.isNotEmpty) {
      _dismissCard(direction);
    }
  }

  /// Kartları sıfırla
  void reset(List<T> newItems) {
    setState(() {
      _items = List.from(newItems);
      _dragOffset = Offset.zero;
      _dragRotation = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return SizedBox(
        height: widget.cardHeight,
        width: widget.cardWidth,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
              const SizedBox(height: 16),
              Text(
                'Tüm kartlar tamamlandı!',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.cardHeight + (widget.visibleCards * widget.stackOffset),
      width: widget.cardWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(
          math.min(widget.visibleCards, _items.length),
          (index) => _buildCard(index),
        ).reversed.toList(),
      ),
    );
  }

  Widget _buildCard(int index) {
    final isTop = index == 0;
    final scale = 1.0 - (index * widget.scaleDecrement);
    final yOffset = index * widget.stackOffset;

    Widget card = widget.cardBuilder(_items[index], index);

    if (isTop) {
      return Positioned(
        top: yOffset + _dragOffset.dy,
        left: _dragOffset.dx,
        child: Transform.rotate(
          angle: _dragRotation,
          child: Transform.scale(
            scale: scale,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: SizedBox(
                width: widget.cardWidth,
                height: widget.cardHeight,
                child: Stack(
                  children: [
                    card,
                    // Swipe indicator overlay
                    if (_isDragging || _dragOffset.dx.abs() > 20)
                      _buildSwipeIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      top: yOffset,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: 1.0 - (index * 0.15),
          child: SizedBox(
            width: widget.cardWidth,
            height: widget.cardHeight,
            child: card,
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeIndicator() {
    final progress = (_dragOffset.dx.abs() / 150).clamp(0.0, 1.0);
    final isRight = _dragOffset.dx > 0;

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRight 
                  ? Colors.green.withOpacity(progress) 
                  : Colors.red.withOpacity(progress),
              width: 4,
            ),
          ),
          child: Center(
            child: Opacity(
              opacity: progress,
              child: Transform.rotate(
                angle: isRight ? -0.3 : 0.3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isRight ? Colors.green : Colors.red,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isRight ? 'DOĞRU' : 'YANLIŞ',
                    style: TextStyle(
                      color: isRight ? Colors.green : Colors.red,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
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

enum SwipeDirection { left, right, up, down }
