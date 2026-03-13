import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:widgetopia/screens/widget_detail_screen.dart';
import 'package:widgetopia/widgets/ambient_background.dart';
import 'package:widgetopia/screens/notepad_detail_screen.dart';
import 'package:widgetopia/screens/timer_screen.dart';
import 'package:widgetopia/screens/calendar_screen.dart';
import 'package:widgetopia/screens/quote_screen.dart';
import 'package:widgetopia/screens/habit_tracker_screen.dart';
import 'package:widgetopia/screens/mood_tracker_screen.dart';
import 'package:widgetopia/utils/theme_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Discover",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  Icon(Icons.search, color: c.textPrimary),
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

              FeedCard(
                title: "Aesthetic Calendar",
                tag: "minimal",
                type: "calendar",
              ),

              FeedCard(
                title: "Habit Tracker",
                tag: "personal",
                type: "habit",
              ),

              FeedCard(
                title: "Mood Tracker",
                tag: "wellbeing",
                type: "mood",
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
    final c = ThemeProvider.colorsOf(context);
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? c.chipSelectedBg : c.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : c.accent,
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
    final c = ThemeProvider.colorsOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.textPrimary)),
        Text("See all", style: TextStyle(color: c.textMuted)),
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
    final c = ThemeProvider.colorsOf(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.collectionCard(color),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(color: c.textMuted)),
        ],
      ),
    );
  }
}

class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return Container(
      height: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(colors: c.isDark
            ? [const Color(0xFF2A2218), const Color(0xFF1A1410)]
            : [const Color(0xFF2F2F2F), const Color(0xFF1A1A1A)]),
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
    if (type == "quote") {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (c, a, s) => const QuoteScreen(),
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

    if (type == "notepad") {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (c, a, s) => const NotepadDetailScreen(),
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

    if (type == "calendar") {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (c, a, s) => const CalendarScreen(),
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

    if (type == "habit") {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (c, a, s) => const HabitTrackerScreen(),
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

    if (type == "mood") {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (c, a, s) => const MoodTrackerScreen(),
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

    if (type == "calendar") {
      return GestureDetector(
        onTap: () => _navigate(context),
        child: const _CalendarFeedCard(),
      );
    }

    if (type == "notepad") {
      return GestureDetector(
        onTap: () => _navigate(context),
        child: const _NotepadFeedCard(),
      );
    }

    if (type == "quote") {
      return GestureDetector(
        onTap: () => _navigate(context),
        child: const _QuoteFeedCard(),
      );
    }

    if (type == "habit") {
      return GestureDetector(
        onTap: () => _navigate(context),
        child: const _HabitFeedCard(),
      );
    }

    if (type == "mood") {
      return GestureDetector(
        onTap: () => _navigate(context),
        child: const _MoodFeedCard(),
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

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    final cardBg = c.feedCardBg;
    final primary = c.primary;
    final accent = c.accent;
    final textColor = c.textPrimary;

    return AnimatedBuilder(
      animation: _breathAnim,
      builder: (context, child) {
        final bv = _breathAnim.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: c.isDark ? 0.08 : (0.15 + bv * 0.08)),
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
                  const Text(
                    '☕',
                    style: TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cozy Study Timer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Focus',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent,
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
                        trackColor: primary.withValues(alpha: 0.2),
                        progressColor: primary,
                      ),
                      child: Center(
                        child: Text(
                          _format(_seconds),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
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
                            color: textColor.withValues(alpha: 0.5),
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
                                    colors: [primary, accent],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          primary.withValues(alpha: 0.3),
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
                                color: accent.withValues(alpha: 0.7),
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
                  backgroundColor: primary.withValues(alpha: 0.15),
                  color: primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────── Calendar Feed Card (Home Screen) ───────────

class _CalendarFeedCard extends StatelessWidget {
  const _CalendarFeedCard();

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);
    final dayName = DateFormat('EEE').format(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.feedCardBgAlt,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: c.isDark ? 0.08 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Aesthetic Calendar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Planner',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mini calendar preview
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: c.primary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${now.day}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: c.accent,
                      ),
                    ),
                    Text(
                      dayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$monthName ${now.year}',
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w300,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap card to expand →',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.accent.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final isToday = i == (now.weekday - 1);
              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday
                      ? c.primary
                      : c.primary.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: Text(
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? Colors.white
                          : c.textPrimary.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────── Notepad Feed Card (Home Screen) ───────────

class _NotepadFeedCard extends StatelessWidget {
  const _NotepadFeedCard();

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.feedCardBgAlt,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: c.isDark ? 0.08 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Personal Notepad',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...List.generate(3, (i) {
            final texts = ['Buy groceries 🛒', 'Finish assignment', 'Call mom ☎️'];
            final dones = [false, true, false];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: dones[i]
                            ? c.primary
                            : c.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      color: dones[i]
                          ? c.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                    ),
                    child: dones[i]
                        ? Icon(Icons.check_rounded,
                            size: 13, color: c.accent)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      texts[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: dones[i]
                            ? c.textPrimary.withValues(alpha: 0.35)
                            : c.textPrimary,
                        decoration: dones[i]
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor:
                            c.textPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Tap card to expand →',
              style: TextStyle(
                fontSize: 12,
                color: c.accent.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────── Quote Feed Card (Home Screen) ───────────

class _QuoteFeedCard extends StatelessWidget {
  const _QuoteFeedCard();

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.feedCardBgAlt,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: c.isDark ? 0.08 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💬', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Daily Quote',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Inspire',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: c.primary.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u201C',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: c.primary.withValues(alpha: 0.25),
                    height: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Small steps every day lead to big changes.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: c.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '— Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.accent.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Tap card to expand →',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.accent.withValues(alpha: 0.7),
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

// ─────────── Habit Feed Card (Home Screen) ───────────

class _HabitFeedCard extends StatelessWidget {
  const _HabitFeedCard();

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    const habitPrimary = Color(0xFF7B61FF);
    const habitAccent = Color(0xFF6B4FE0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.feedCardBgAlt,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: habitPrimary.withValues(alpha: c.isDark ? 0.08 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Habit Tracker',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: habitPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Track',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: habitAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Center(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(35, (i) {
                final filled = [0,1,3,5,7,8,10,14,15,17,19,21,22,24,25,28,29,30,32,34].contains(i);
                return Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: filled
                        ? habitPrimary.withValues(alpha: 0.2 + (i % 5) * 0.18)
                        : c.isDark
                            ? const Color(0xFF2A2520)
                            : const Color(0xFFEDE5D8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickStat(label: 'Habits', value: '4', color: habitPrimary),
              const _QuickStat(
                  label: 'Streak', value: '7 🔥', color: Color(0xFFFF7043)),
              const _QuickStat(
                  label: 'Today', value: '2/4', color: Color(0xFF69F0AE)),
            ],
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Tap card to expand →',
              style: TextStyle(
                fontSize: 12,
                color: habitAccent.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodFeedCard extends StatelessWidget {
  const _MoodFeedCard();

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    const moodPrimary = Color(0xFFFF8FAB);
    const moodAccent = Color(0xFFC95D7B);
    const moodSequence = ['😞', '😕', '😌', '😊', '🤩'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.feedCardBg,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: moodPrimary.withValues(alpha: c.isDark ? 0.08 : 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💛', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Mood Tracker',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: moodPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Reflect',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: moodAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: moodPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: c.isDark ? 0.08 : 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('😊', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily emotional check-in',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Log your mood, add notes, and notice trends.',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(moodSequence.length, (index) {
              return Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: index == 3
                      ? moodPrimary.withValues(alpha: 0.18)
                      : c.chipBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: index == 3
                        ? moodPrimary.withValues(alpha: 0.5)
                        : c.divider,
                  ),
                ),
                child: Text(
                  moodSequence[index],
                  style: const TextStyle(fontSize: 20),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _QuickStat(label: 'Logs', value: '12', color: moodPrimary),
              _QuickStat(
                  label: 'Streak', value: '5d', color: Color(0xFF4ECDC4)),
              _QuickStat(
                  label: 'Top mood', value: 'Good', color: Color(0xFFFFC75F)),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Tap card to expand →',
              style: TextStyle(
                fontSize: 12,
                color: moodAccent.withValues(alpha: 0.72),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}
