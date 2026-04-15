import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium, immersive hero shell used on every widget detail screen.
///
/// Provides a layered coffee-style background with grain texture,
/// blurred blobs, radial glow, depth lighting, and frosted-glass
/// overlay controls — wrapping any [content] widget passed in.
///
/// Supports live reactive preview: content changes cross-fade smoothly,
/// and an optional [onContentTap] makes the hero card tappable with
/// a satisfying scale-bounce + border-glow micro-animation.
class DetailHeroShell extends StatefulWidget {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color cardColor;
  final Color background;
  final Color textColor;

  /// The centred widget preview (timer ring, quote card, etc.)
  final Widget content;

  /// Breathing / pulse animation driven by the parent screen.
  final Animation<double> breathAnimation;

  /// Navigation callbacks.
  final VoidCallback onBack;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onShare;

  /// Optional tap callback for the hero content card.
  /// When provided, tapping the card fires a scale-bounce + border-glow
  /// and invokes this callback — letting each screen wire its own action.
  final VoidCallback? onContentTap;

  /// Optional emotional label shown at the bottom of the hero
  /// e.g. "Deep Focus ☕"
  final String? emotionalLabel;

  /// Deterministic seed for random blob / sparkle placement.
  final int decorationSeed;

  const DetailHeroShell({
    super.key,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.cardColor,
    required this.background,
    required this.textColor,
    required this.content,
    required this.breathAnimation,
    required this.onBack,
    required this.isFavorite,
    required this.onFavoriteToggle,
    this.onShare,
    this.onContentTap,
    this.emotionalLabel,
    this.decorationSeed = 42,
  });

  @override
  State<DetailHeroShell> createState() => _DetailHeroShellState();
}

class _DetailHeroShellState extends State<DetailHeroShell>
    with TickerProviderStateMixin {
  // ── Tap scale-bounce animation ──
  late AnimationController _tapScaleController;
  late Animation<double> _tapScaleAnim;

  // ── Tap border-glow animation ──
  late AnimationController _tapGlowController;
  late Animation<double> _tapGlowAnim;

  @override
  void initState() {
    super.initState();

    _tapScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _tapScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.96)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_tapScaleController);

    _tapGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tapGlowAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.12, end: 0.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 0.12)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_tapGlowController);
  }

  @override
  void dispose() {
    _tapScaleController.dispose();
    _tapGlowController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onContentTap == null) return;
    HapticFeedback.lightImpact();
    _tapScaleController.forward(from: 0);
    _tapGlowController.forward(from: 0);
    widget.onContentTap!();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.4, 0.75, 1.0],
          colors: [
            Color.lerp(widget.cardColor, const Color(0xFF3E2723), 0.12)!, // espresso hint
            widget.cardColor,
            widget.secondary.withValues(alpha: 0.45),
            widget.background,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primary.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: widget.accent.withValues(alpha: 0.06),
            blurRadius: 80,
            spreadRadius: -10,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // ── Layer 1: Blurred blobs ──
            ..._buildBlurredBlobs(),

            // ── Layer 2: Grain / noise texture ──
            Positioned.fill(
              child: CustomPaint(
                painter: _GrainPainter(
                  opacity: 0.035,
                  seed: widget.decorationSeed,
                ),
              ),
            ),

            // ── Layer 3: Radial glow behind content ──
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.1),
                    radius: 0.6,
                    colors: [
                      widget.primary.withValues(alpha: 0.10),
                      widget.primary.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // ── Layer 4: Inner highlight (top light) ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // ── Layer 5: Steam-like curves ──
            Positioned.fill(
              child: CustomPaint(
                painter: _SteamCurvesPainter(
                  color: widget.primary.withValues(alpha: 0.04),
                  seed: widget.decorationSeed,
                ),
              ),
            ),

            // ── Layer 6: Sparkle dots ──
            ..._buildSparkles(),

            // ── Layer 7: Interactive content card with depth ──
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  widget.breathAnimation,
                  _tapScaleAnim,
                  _tapGlowAnim,
                ]),
                builder: (context, child) {
                  final borderAlpha = widget.onContentTap != null
                      ? _tapGlowAnim.value
                      : 0.12;
                  return GestureDetector(
                    onTap: _handleTap,
                    child: Transform.scale(
                      scale: _tapScaleAnim.value,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 230),
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            // Close shadow (depth)
                            BoxShadow(
                              color: widget.primary.withValues(
                                  alpha: 0.08 +
                                      widget.breathAnimation.value * 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                            // Far glow (ambient)
                            BoxShadow(
                              color: widget.primary.withValues(
                                  alpha: 0.10 +
                                      widget.breathAnimation.value * 0.06),
                              blurRadius:
                                  32 + widget.breathAnimation.value * 10,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color:
                                widget.primary.withValues(alpha: borderAlpha),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Smooth cross-fade for content changes
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: widget.content,
                            ),
                            // Tap hint icon
                            if (widget.onContentTap != null)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: AnimatedBuilder(
                                  animation: widget.breathAnimation,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: 0.15 +
                                          widget.breathAnimation.value * 0.1,
                                      child: Icon(
                                        Icons.touch_app_rounded,
                                        size: 14,
                                        color: widget.primary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Layer 8: Emotional label ──
            if (widget.emotionalLabel != null)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.primary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      widget.emotionalLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.textColor.withValues(alpha: 0.55),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Layer 9: Overlay controls (frosted glass) ──
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FrostedIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: widget.onBack,
                      textColor: widget.textColor,
                    ),
                    Row(
                      children: [
                        _FrostedIconButton(
                          icon: widget.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          onTap: widget.onFavoriteToggle,
                          iconColor:
                              widget.isFavorite ? Colors.redAccent : null,
                          textColor: widget.textColor,
                        ),
                        const SizedBox(width: 8),
                        if (widget.onShare != null)
                          _FrostedIconButton(
                            icon: Icons.share_rounded,
                            onTap: widget.onShare!,
                            textColor: widget.textColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Blurred blob decorations ───
  List<Widget> _buildBlurredBlobs() {
    final rng = Random(widget.decorationSeed);
    final List<Widget> blobs = [];
    final blobColors = [
      widget.primary.withValues(alpha: 0.10),
      widget.secondary.withValues(alpha: 0.12),
      widget.accent.withValues(alpha: 0.06),
      const Color(0xFFFFD6C0).withValues(alpha: 0.10), // warm peach
      const Color(0xFFF5E6D3).withValues(alpha: 0.12), // light cream
    ];

    for (int i = 0; i < 6; i++) {
      final size = 50.0 + rng.nextDouble() * 80;
      blobs.add(
        Positioned(
          left: -20 + rng.nextDouble() * 360,
          top: -20 + rng.nextDouble() * 320,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blobColors[i % blobColors.length],
              ),
            ),
          ),
        ),
      );
    }
    return blobs;
  }

  // ─── Sparkle dot decorations ───
  List<Widget> _buildSparkles() {
    final rng = Random(widget.decorationSeed + 100);
    final List<Widget> sparkles = [];

    for (int i = 0; i < 14; i++) {
      final dotSize = 2.5 + rng.nextDouble() * 4;
      sparkles.add(
        Positioned(
          left: rng.nextDouble() * 360,
          top: rng.nextDouble() * 320,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.primary.withValues(
                  alpha: 0.12 + rng.nextDouble() * 0.12),
            ),
          ),
        ),
      );
    }
    return sparkles;
  }
}

// ═══════════════════════════════════════
//  Frosted-Glass Icon Button
// ═══════════════════════════════════════

class _FrostedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color textColor;

  const _FrostedIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.50),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? textColor.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  Grain / Noise Texture Painter
// ═══════════════════════════════════════

class _GrainPainter extends CustomPainter {
  final double opacity;
  final int seed;

  _GrainPainter({required this.opacity, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final paint = Paint();
    final step = 4.0;

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final v = rng.nextDouble();
        paint.color = (v > 0.5 ? Colors.white : Colors.black)
            .withValues(alpha: opacity * (0.3 + v * 0.7));
        canvas.drawRect(Rect.fromLTWH(x, y, step, step), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) =>
      old.opacity != opacity || old.seed != seed;
}

// ═══════════════════════════════════════
//  Steam-like Curves Painter
// ═══════════════════════════════════════

class _SteamCurvesPainter extends CustomPainter {
  final Color color;
  final int seed;

  _SteamCurvesPainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final rng = Random(seed + 200);

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final startX = size.width * (0.2 + rng.nextDouble() * 0.6);
      final startY = size.height * (0.5 + rng.nextDouble() * 0.4);

      path.moveTo(startX, startY);

      // Gentle S-curve rising upward
      final cp1x = startX + (rng.nextDouble() - 0.5) * 60;
      final cp1y = startY - 40 - rng.nextDouble() * 40;
      final cp2x = startX + (rng.nextDouble() - 0.5) * 80;
      final cp2y = cp1y - 30 - rng.nextDouble() * 30;
      final endX = startX + (rng.nextDouble() - 0.5) * 50;
      final endY = cp2y - 20 - rng.nextDouble() * 20;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, endX, endY);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SteamCurvesPainter old) =>
      old.color != color || old.seed != seed;
}
