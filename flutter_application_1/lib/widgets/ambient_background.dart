import 'package:flutter/material.dart';
import 'dart:ui';

class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Container(
          color: const Color(0xFFFFF8EE),
        ),

        // Glow blobs
        Positioned(
          top: -100,
          left: -80,
          child: _Glow(color: const Color(0xFFFFD6A5), size: 260),
        ),
        Positioned(
          top: 200,
          right: -100,
          child: _Glow(color: const Color(0xFFFFB4A2), size: 240),
        ),
        Positioned(
          bottom: -120,
          left: -60,
          child: _Glow(color: const Color(0xFFFFE5EC), size: 280),
        ),

        // Blur layer
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(color: Colors.transparent),
        ),

        // Your actual UI
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.6),
      ),
    );
  }
}
