import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:widgetopia/screens/widget_detail_screen.dart';
import 'package:widgetopia/widgets/ambient_background.dart';
import 'package:widgetopia/screens/notpad_detail_screen.dart';
import 'package:widgetopia/screens/timer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Discover",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E241C),
                    ),
                  ),
                  Icon(Icons.search, color: Color(0xFF2E241C)),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _Chip(label: "For You", selected: true),
                    _Chip(label: "Aesthetic"),
                    _Chip(label: "Fandom"),
                    _Chip(label: "Meme"),
                    _Chip(label: "Minimal"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const _SectionHeader(title: "Trending Collections"),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: const [
                  CollectionCard(title: "Wu Pack", count: "12 widgets", color: Color(0xFFE6F4F1)),
                  CollectionCard(title: "Shang Pack", count: "18 widgets", color: Color(0xFFF8EFE6)),
                  CollectionCard(title: "Clan Pack", count: "15 widgets", color: Color(0xFFEDEBEA)),
                  CollectionCard(title: "Cozy Pack", count: "20 widgets", color: Color(0xFFFDECEF)),
                ],
              ),

              const SizedBox(height: 28),

              const _SectionHeader(title: "Featured Today"),
              const SizedBox(height: 12),
              const FeaturedCard(),

              const SizedBox(height: 28),

              const _SectionHeader(title: "For You"),
              const SizedBox(height: 12),

              FeedCard(
                title: "Cozy Study Timer",
                tag: "cozy",
                type: "pomodoro",
              ),

              FeedCard(
                title: "Daily Quote",
                tag: "quote",
                type: "quote",
              ),

              FeedCard(
                title: "Personal Notepad",
                tag: "notes",
                type: "notepad",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- UI PARTS ----------------

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  const _Chip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF6B4F3A) : const Color(0xFFF1E8DD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF6B4F3A),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text("See all", style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class CollectionCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  const CollectionCard({super.key, required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(count, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFF2F2F2F), Color(0xFF1A1A1A)]),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 16)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(label: Text("Featured"), backgroundColor: Color(0xFFFFC857)),
          Spacer(),
          Text("Cozy Study Timer", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text("Perfect for calm study sessions ☕", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class FeedCard extends StatelessWidget {
  final String title;
  final String tag;
  final String type;

  const FeedCard({super.key, required this.title, required this.tag, required this.type});

  void _navigate(BuildContext context) {
    if (type == "notepad") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotepadDetailScreen()),
      );
      return;
    }

    if (type == "pomodoro") {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (c, a, s) => const TimerScreen(),
          transitionsBuilder: (c, animation, s, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (c, a, s) => WidgetDetailScreen(
          title: title,
          tag: tag,
          type: type,
        ),
        transitionsBuilder: (c, animation, s, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (type == "pomodoro") {
      return GestureDetector(
        onTap: () => _navigate(context),
        child: const _CozyTimerCard(),
      );
    }

    return GestureDetector(
      onTap: () => _navigate(context),
      child: Hero(
        tag: title,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 170,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2933),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 14)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(label: Text(tag), backgroundColor: Colors.white24),
                const Spacer(),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────── Cozy Timer Card (Home Screen) ───────────

class _CozyTimerCard extends StatefulWidget {
  const _CozyTimerCard();

  @override
  State<_CozyTimerCard> createState() => _CozyTimerCardState();
}

class _CozyTimerCardState extends State<_CozyTimerCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _running = false;
  int _seconds = 25 * 60;
  final int _maxSeconds = 25 * 60;

  late AnimationController _breathController;
  late Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  void _startPause() {
    if (_running) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_seconds > 0) {
          setState(() => _seconds--);
        } else {
          _timer?.cancel();
          setState(() => _running = false);
        }
      });
    }
    setState(() => _running = !_running);
  }

  String _format(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  double get _progress => _maxSeconds > 0 ? 1 - (_seconds / _maxSeconds) : 0;

  static const _cardBg = Color(0xFFFFF0DC);
  static const _primary = Color(0xFFD4A574);
  static const _accent = Color(0xFFC08552);
  static const _textColor = Color(0xFF4A3728);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathAnim,
      builder: (context, child) {
        final bv = _breathAnim.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.15 + bv * 0.08),
                blurRadius: 24 + bv * 10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top row: label + tag
              Row(
                children: [
                  Text(
                    '☕',
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Cozy Study Timer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Focus',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Timer ring + time
              Row(
                children: [
                  // Mini ring
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CustomPaint(
                      painter: _MiniRingPainter(
                        progress: _progress,
                        trackColor: _primary.withValues(alpha: 0.2),
                        progressColor: _primary,
                      ),
                      child: Center(
                        child: Text(
                          _format(_seconds),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Right side: controls + info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '25 min session',
                          style: TextStyle(
                            fontSize: 13,
                            color: _textColor.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Play/Pause button
                            GestureDetector(
                              onTap: _startPause,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [_primary, _accent],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          _primary.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _running
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Open full timer link
                            Text(
                              'Tap card to expand →',
                              style: TextStyle(
                                fontSize: 12,
                                color: _accent.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: _primary.withValues(alpha: 0.15),
                  color: _primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _MiniRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter old) =>
      old.progress != progress;
}
