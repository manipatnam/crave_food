// Favourite Card Animations
// lib/animations/favourites/favourite_card_animations.dart

import 'package:flutter/material.dart';

class FavouriteCardAnimations {
  final AnimationController controller;
  late final Animation<double> scaleAnimation;
  late final Animation<double> expandAnimation;
  late final Animation<double> fadeAnimation;

  FavouriteCardAnimations(this.controller) {
    scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    
    expandAnimation = CurvedAnimation(
      parent: controller, 
      curve: Curves.easeInOut,
    );
    
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeIn),
    );
  }
}

class CardPressAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;

  const CardPressAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<CardPressAnimation> createState() => _CardPressAnimationState();
}

class _CardPressAnimationState extends State<CardPressAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}