import 'dart:math';
import 'package:flutter/material.dart';

class QuoteWidgetPreview extends StatefulWidget {
  final String quote;
  final String author;

  const QuoteWidgetPreview({
    super.key,
    required this.quote,
    required this.author,
  });

  @override
  State<QuoteWidgetPreview> createState() => _QuoteWidgetPreviewState();
}

class _QuoteWidgetPreviewState extends State<QuoteWidgetPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final offset = sin(_controller.value * pi * 2) * 6;
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE8D8), Color(0xFFFFF4EC)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFCFA8).withOpacity(0.6),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.quote,
              style: const TextStyle(
                fontSize: 22,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E241C),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.author,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8B7A6B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Grain painter (safe + performant)
class _GrainPainter extends CustomPainter {
  final Random random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.03);

    for (int i = 0; i < 900; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      canvas.drawCircle(
        Offset(x, y),
        0.5, // grain size
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
