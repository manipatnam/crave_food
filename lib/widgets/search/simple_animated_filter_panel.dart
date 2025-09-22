// Simple Animated Filter Panel Replacement
// lib/widgets/search/simple_animated_filter_panel.dart

import 'package:flutter/material.dart';

class AnimatedFilterPanel extends StatelessWidget {
  final bool showFilters;
  final Widget child;

  const AnimatedFilterPanel({
    super.key,
    required this.showFilters,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: showFilters ? null : 0,
      child: showFilters 
        ? Container(
            margin: const EdgeInsets.only(top: 120),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: child,
          )
        : const SizedBox.shrink(),
    );
  }
}