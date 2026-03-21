import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wraps widgets to scale down to 0.97 on tap down, and spring back on tap up.
class ScaleTapWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ScaleTapWrapper({super.key, required this.child, this.onTap});

  @override
  State<ScaleTapWrapper> createState() => _ScaleTapWrapperState();
}

class _ScaleTapWrapperState extends State<ScaleTapWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onTap != null) widget.onTap!();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// A subtle internal parallax that shifts Y position based on its scroll viewport global position.
class ParallaxScrollLayer extends StatelessWidget {
  final Widget child;
  const ParallaxScrollLayer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return child;

    return AnimatedBuilder(
      animation: scrollable.position,
      builder: (context, _) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return child;
        final yPos = box.localToGlobal(Offset.zero).dy;
        final screenH = MediaQuery.of(context).size.height;
        final normalizedY = (yPos / screenH) - 0.5;
        
        // Translates up to 15px in reverse direction to scrolling for parallax
        return Transform.translate(
          offset: Offset(0, normalizedY * 15),
          child: child,
        );
      },
    );
  }
}


class TypeAHeroCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String tag;
  final List<Color> gradientColors;
  final IconData actionIcon;
  final VoidCallback onTap;

  const TypeAHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.gradientColors,
    required this.actionIcon,
    required this.onTap,
  });

  @override
  State<TypeAHeroCard> createState() => _TypeAHeroCardState();
}

class _TypeAHeroCardState extends State<TypeAHeroCard> with SingleTickerProviderStateMixin {
  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTapWrapper(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _breathController,
        builder: (context, child) {
          final breath = CurvedAnimation(parent: _breathController, curve: Curves.easeInOut).value;
          
          return Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.8 + (0.2 * breath)], // Shifts gradient diagonally
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: widget.gradientColors[0].withValues(alpha: 0.3 + (0.15 * breath)),
                  blurRadius: 24 + (12 * breath), // Glow expands dynamically
                  offset: Offset(0, 12 + (8 * breath)), 
                ),
              ],
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.tag.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.title,
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(widget.actionIcon, color: widget.gradientColors[0], size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypeBGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double height;

  const TypeBGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTapWrapper(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: ParallaxScrollLayer(child: child),
          ),
        ),
      ),
    );
  }
}

class TypeCClayCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final double height;
  final bool isDark;

  const TypeCClayCard({
    super.key,
    required this.child,
    required this.backgroundColor,
    this.onTap,
    this.height = 180,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTapWrapper(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black12 : const Color(0x08000000),
              blurRadius: 8,
              offset: const Offset(0, -4),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: ParallaxScrollLayer(child: child),
      ),
    );
  }
}
