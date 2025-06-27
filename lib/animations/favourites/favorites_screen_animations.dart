// Favorites Screen Animations
// lib/animations/favourites/favorites_screen_animations.dart

import 'package:flutter/material.dart';

class FavoritesScreenAnimations {
  static Widget buildAnimatedFAB({
    required Animation<double> fabAnimation,
    required VoidCallback onPressed,
    required Color primaryColor,
  }) {
    return ScaleTransition(
      scale: fabAnimation,
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Favourite'),
        elevation: 8,
        highlightElevation: 12,
      ),
    );
  }

  static Widget buildStaggeredList({
    required List<Widget> children,
    Duration delay = const Duration(milliseconds: 100),
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return StaggeredAnimationList(
      children: children,
      delay: delay,
      duration: duration,
    );
  }
}

class StaggeredAnimationList extends StatefulWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;

  const StaggeredAnimationList({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<StaggeredAnimationList> createState() => _StaggeredAnimationListState();
}

class _StaggeredAnimationListState extends State<StaggeredAnimationList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    _fadeAnimations = _controllers.map((controller) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOut),
        )).toList();

    _slideAnimations = _controllers.map((controller) =>
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOut),
        )).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.delay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        return FadeTransition(
          opacity: _fadeAnimations[index],
          child: SlideTransition(
            position: _slideAnimations[index],
            child: widget.children[index],
          ),
        );
      }),
    );
  }
}

class FilterPanelAnimation extends StatefulWidget {
  final Widget child;
  final bool isVisible;

  const FilterPanelAnimation({
    super.key,
    required this.child,
    required this.isVisible,
  });

  @override
  State<FilterPanelAnimation> createState() => _FilterPanelAnimationState();
}

class _FilterPanelAnimationState extends State<FilterPanelAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _heightAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FilterPanelAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _heightAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );
  }
}