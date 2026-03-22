import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:async';
import 'package:widgetopia/widgets/ambient_background.dart';
import 'package:widgetopia/screens/mood_tracker_screen.dart';
import 'package:widgetopia/screens/widget_detail_screen.dart';
import 'package:widgetopia/screens/notepad_detail_screen.dart';
import 'package:widgetopia/screens/timer_screen.dart';
import 'package:widgetopia/screens/calendar_screen.dart';
import 'package:widgetopia/screens/quote_screen.dart';
import 'package:widgetopia/screens/habit_tracker_screen.dart';
import 'package:widgetopia/models/saved_widget_model.dart';
import 'package:widgetopia/services/saved_widgets_service.dart';
import '../utils/theme_provider.dart';

// ─── Helpers ───

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

// ─── HomeScreen ───

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SavedWidgetModel> _pinned = [];

  @override
  void initState() {
    super.initState();
    _loadPinned();
    SavedWidgetsService.changeNotifier.addListener(_loadPinned);
  }

  @override
  void dispose() {
    SavedWidgetsService.changeNotifier.removeListener(_loadPinned);
    super.dispose();
  }

  Future<void> _loadPinned() async {
    final pinned = await SavedWidgetsService.getPinned();
    if (!mounted) return;
    setState(() => _pinned = pinned);
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ─── Header ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greeting()},',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: c.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Souvik.',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Cozy Hours pill
                      GestureDetector(
                        onTap: () => _navigate(context, 'pomodoro'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: c.feedCardBg,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: c.primary.withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🌙', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                'Cozy Hours',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── 📌 Pinned Widgets Row (only when pinned items exist) ───
              if (_pinned.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                        child: Row(
                          children: [
                            const Text('📌', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Text(
                              'Pinned',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: c.sectionHeaderColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _pinned.length,
                          separatorBuilder: (ctx, idx) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) => _PinnedChip(
                            item: _pinned[i],
                            colors: c,
                            onTap: () =>
                                _navigate(context, _pinned[i].type),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ─── Hero Pomodoro Card ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, _pinned.isEmpty ? 20 : 14, 20, 0),
                  child: const _HeroPomodoroCard(),
                ),
              ),

              // ─── Section: ✨ For You ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                  child: Text(
                    '✨ For You',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: c.sectionHeaderColor,
                    ),
                  ),
                ),
              ),

              // ─── 2-Column Widget Grid ───
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildListDelegate([
                    _MiniPomodorCard(
                        onTap: () => _navigate(context, 'pomodoro')),
                    _MiniQuoteCard(
                        onTap: () => _navigate(context, 'quote')),
                    _MiniNotepadCard(
                        onTap: () => _navigate(context, 'notepad')),
                    _MiniCalendarCard(
                        onTap: () => _navigate(context, 'calendar')),
                    _MiniHabitCard(
                        onTap: () => _navigate(context, 'habit')),
                    _MiniMoodCard(
                        onTap: () => _navigate(context, 'mood')),
                    _MiniDayProgressCard(
                        onTap: () => _navigate(context, 'day_progress')),
                    _MiniSunriseSunsetCard(
                        onTap: () => _navigate(context, 'sunrise_sunset')),
                    _MiniAgendaCard(
                        onTap: () => _navigate(context, 'agenda')),
                    _MiniWeeklyAgendaCard(
                        onTap: () => _navigate(context, 'weekly_agenda')),
                    _MiniExamPlannerCard(
                        onTap: () => _navigate(context, 'exam_planner')),
                    _MiniArtShuffleCard(
                        onTap: () => _navigate(context, 'art_shuffle')),
                  ]),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String type) {
    Widget page;
    switch (type) {
      case 'pomodoro':
        page = const TimerScreen();
        break;
      case 'quote':
        page = const QuoteScreen();
        break;
      case 'notepad':
        page = const NotepadDetailScreen();
        break;
      case 'calendar':
        page = const CalendarScreen();
        break;
      case 'habit':
        page = const HabitTrackerScreen();
        break;
      case 'mood':
        page = const MoodTrackerScreen();
        break;
      default:
        page = WidgetDetailScreen(title: type, tag: type, type: type);
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (c, a, s) => page,
        transitionsBuilder: (c, animation, s, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                      begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

// ─────────── Pinned Chip (Home) ───────────

class _PinnedChip extends StatelessWidget {
  final SavedWidgetModel item;
  final AppColors colors;
  final VoidCallback onTap;

  const _PinnedChip({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: c.feedCardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.2 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_pinnedEmoji(item.type),
                style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              item.displayTitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _pinnedEmoji(String type) {
    const map = {
      'pomodoro': '☕',
      'quote': '💬',
      'notepad': '📝',
      'calendar': '📅',
      'habit': '🎯',
      'mood': '💛',
      'day_progress': '⏳',
      'sunrise_sunset': '🌅',
      'art_shuffle': '🎨',
      'agenda': '📋',
      'weekly_agenda': '📆',
      'exam_planner': '📚',
    };
    return map[type] ?? '🧩';
  }
}

// ─────────── Hero Pomodoro Card ───────────

class _HeroPomodoroCard extends StatefulWidget {
  const _HeroPomodoroCard();

  @override
  State<_HeroPomodoroCard> createState() => _HeroPomodoroCardState();
}

class _HeroPomodoroCardState extends State<_HeroPomodoroCard> {
  Timer? _timer;
  bool _running = false;
  int _seconds = 25 * 60;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPause() {
    if (_running) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (c, a, s) => const TimerScreen(),
          transitionsBuilder: (c, animation, s, child) {
            final curved = CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween(
                        begin: const Offset(0, 0.04), end: Offset.zero)
                    .animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8D5A3), // warm cream-yellow
              Color(0xFFB5D5C5), // soft sage green
              Color(0xFF8ECAE6), // sky blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8ECAE6).withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FOCUS chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'FOCUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Timer
                  Text(
                    _format(_seconds),
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pomodoro Timer',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Play/Pause button
            Positioned(
              right: 20,
              bottom: 20,
              child: GestureDetector(
                onTap: _startPause,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFF6B7D6A),
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────── Mini Card Shell ───────────

class _MiniCardShell extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Gradient? gradient;

  const _MiniCardShell({
    required this.child,
    required this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: gradient == null ? c.feedCardBg : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.2 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ),
    );
  }
}

// ─── Mini card header row (emoji + title + tag) ───

class _MiniCardHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String tag;
  final Color tagColor;
  final Color tagTextColor;

  const _MiniCardHeader({
    required this.emoji,
    required this.title,
    required this.tag,
    this.tagColor = const Color(0xFFE8DFD2),
    this.tagTextColor = const Color(0xFF6B4F3A),
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: tagColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: tagTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────── Mini Pomodoro Card ───────────

class _MiniPomodorCard extends StatefulWidget {
  final VoidCallback onTap;
  const _MiniPomodorCard({required this.onTap});

  @override
  State<_MiniPomodorCard> createState() => _MiniPomodorCardState();
}

class _MiniPomodorCardState extends State<_MiniPomodorCard> {
  Timer? _timer;
  bool _running = false;
  int _seconds = 25 * 60;
  static const int _maxSeconds = 25 * 60;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
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

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  double get _progress =>
      _maxSeconds > 0 ? 1 - (_seconds / _maxSeconds) : 0;

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return _MiniCardShell(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniCardHeader(
            emoji: '☕',
            title: 'Cozy…',
            tag: 'Focus',
            tagColor: c.primary.withValues(alpha: 0.18),
            tagTextColor: c.accent,
          ),
          const SizedBox(height: 10),
          Text(
            '25 min session',
            style: TextStyle(
              fontSize: 11,
              color: c.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // Mini ring + time + button
          Row(
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: _progress,
                    trackColor: c.primary.withValues(alpha: 0.2),
                    progressColor: c.primary,
                  ),
                  child: Center(
                    child: Text(
                      _fmt(_seconds),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [c.primary, c.accent],
                        ),
                      ),
                      child: Icon(
                        _running
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap →',
                    style: TextStyle(
                      fontSize: 10,
                      color: c.accent.withValues(alpha: 0.65),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Ring Painter
class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;
    const startAngle = -pi / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final prog = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * pi * progress,
      false,
      prog,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress;
}

// ─────────── Mini Quote Card ───────────

class _MiniQuoteCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniQuoteCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return _MiniCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniCardHeader(
            emoji: '💬',
            title: 'Daily…',
            tag: 'Inspire',
            tagColor: c.primary.withValues(alpha: 0.18),
            tagTextColor: c.accent,
          ),
          const SizedBox(height: 12),
          Text(
            '\u201C',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: c.primary.withValues(alpha: 0.3),
              height: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              'Small steps every day lead to big changes.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: c.textPrimary,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap card to expand →',
            style: TextStyle(
              fontSize: 10,
              color: c.accent.withValues(alpha: 0.65),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────── Mini Notepad Card ───────────

class _MiniNotepadCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniNotepadCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    const items = ['Buy groceries 🛒', 'Finish assignment', 'Call mom ☎️'];
    const done = [false, true, false];

    return _MiniCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniCardHeader(
            emoji: '📝',
            title: 'Pers…',
            tag: 'Notes',
            tagColor: c.primary.withValues(alpha: 0.18),
            tagTextColor: c.accent,
          ),
          const SizedBox(height: 10),
          ...List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: done[i]
                            ? c.primary
                            : c.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      color: done[i]
                          ? c.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                    ),
                    child: done[i]
                        ? Icon(Icons.check_rounded,
                            size: 10, color: c.accent)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      items[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: done[i]
                            ? c.textSecondary
                            : c.textPrimary,
                        decoration: done[i]
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor:
                            c.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          Text(
            'Tap to expand →',
            style: TextStyle(
              fontSize: 10,
              color: c.accent.withValues(alpha: 0.65),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────── Mini Calendar Card ───────────

class _MiniCalendarCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniCalendarCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    final now = DateTime.now();
    final monthName = DateFormat('MMM').format(now);

    return _MiniCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniCardHeader(
            emoji: '📅',
            title: 'Aes…',
            tag: 'Planner',
            tagColor: c.primary.withValues(alpha: 0.18),
            tagTextColor: c.accent,
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
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
                    monthName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Mini week row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final isToday = i == (now.weekday - 1);
              return Container(
                width: 22,
                height: 22,
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
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? Colors.white
                          : c.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
          Text(
            'Tap to expand →',
            style: TextStyle(
              fontSize: 10,
              color: c.accent.withValues(alpha: 0.65),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────── Mini Habit Card ───────────

class _MiniHabitCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniHabitCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    const habitPrimary = Color(0xFF7B61FF);
    const habitAccent = Color(0xFF6B4FE0);

    return _MiniCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniCardHeader(
            emoji: '🎯',
            title: 'Habit',
            tag: 'Track',
            tagColor: habitPrimary.withValues(alpha: 0.18),
            tagTextColor: habitAccent,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: Wrap(
                spacing: 3,
                runSpacing: 3,
                children: List.generate(25, (i) {
                  final filled = [0,1,3,5,7,8,10,14,15,17,19,21,22,24].contains(i);
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: filled
                          ? habitPrimary.withValues(alpha: 0.25 + (i % 5) * 0.15)
                          : c.isDark
                              ? const Color(0xFF2A2520)
                              : const Color(0xFFEDE5D8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(value: '4', label: 'Habits', color: habitPrimary),
              const _MiniStat(value: '7🔥', label: 'Streak', color: Color(0xFFFF7043)),
              const _MiniStat(value: '2/4', label: 'Today', color: Color(0xFF69F0AE)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────── Mini Mood Card ───────────

class _MiniMoodCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniMoodCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    const moodPrimary = Color(0xFFFF8FAB);
    const emojis = ['😞', '😕', '😌', '😊', '🤩'];

    return _MiniCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniCardHeader(
            emoji: '💛',
            title: 'Mood',
            tag: 'Reflect',
            tagColor: moodPrimary.withValues(alpha: 0.18),
            tagTextColor: const Color(0xFFC95D7B),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: moodPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('😊', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily check-in',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: emojis
                .asMap()
                .entries
                .map((e) => Text(
                      e.value,
                      style: TextStyle(
                        fontSize: e.key == 3 ? 22 : 16,
                      ),
                    ))
                .toList(),
          ),
          const Spacer(),
          Text(
            'Tap to expand →',
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFFC95D7B).withValues(alpha: 0.65),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────── Mini Day Progress Card ───────────

class _MiniDayProgressCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniDayProgressCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    final now = DateTime.now();
    final progress = (now.hour * 60 + now.minute) / (24 * 60);

    return _MiniCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniCardHeader(
            emoji: '⏳',
            title: 'Day',
            tag: 'Minimal',
            tagColor: const Color(0xFF26A69A).withValues(alpha: 0.15),
            tagTextColor: const Color(0xFF00897B),
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: c.chipBg,
                    color: const Color(0xFF26A69A),
                    strokeCap: StrokeCap.round,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        'done',
                        style: TextStyle(
                          fontSize: 9,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              'Day Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────── Mini Sunrise/Sunset Card ───────────

class _MiniSunriseSunsetCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniSunriseSunsetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _MiniCardShell(
      onTap: onTap,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFB74D), Color(0xFFFF8A65), Color(0xFFE57373)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🌅', style: TextStyle(fontSize: 18)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Sunrise',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Icon(Icons.wb_sunny_outlined,
                      color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  const Text('6:14 AM',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text('Rise',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10)),
                ],
              ),
              Column(
                children: [
                  const Icon(Icons.nights_stay_outlined,
                      color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  const Text('7:42 PM',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text('Set',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10)),
                ],
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─────────── Mini Agenda Card ───────────

class _MiniAgendaCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniAgendaCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    const items = [
      ('09:00', 'Team Sync', Color(0xFF5C6BC0)),
      ('12:30', 'Lunch', Color(0xFFFFB347)),
      ('03:00', 'Design Review', Color(0xFF4ECDC4)),
    ];

    return _MiniCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniCardHeader(
            emoji: '📋',
            title: 'Agenda',
            tag: 'Plans',
            tagColor: const Color(0xFF5C6BC0).withValues(alpha: 0.18),
            tagTextColor: const Color(0xFF3949AB),
          ),
          const SizedBox(height: 8),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 20,
                      decoration: BoxDecoration(
                        color: it.$3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.$1,
                            style: TextStyle(
                                fontSize: 10, color: c.textSecondary),
                          ),
                          Text(
                            it.$2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────── Mini Weekly Agenda Card ───────────

class _MiniWeeklyAgendaCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniWeeklyAgendaCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    const intensities = [0.8, 0.4, 1.0, 0.6, 0.2, 0.0, 0.0];
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIdx = DateTime.now().weekday - 1;

    return _MiniCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniCardHeader(
            emoji: '📆',
            title: 'Weekly',
            tag: 'Planner',
            tagColor: const Color(0xFF66BB6A).withValues(alpha: 0.18),
            tagTextColor: const Color(0xFF388E3C),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final isToday = i == todayIdx;
              return Column(
                children: [
                  Container(
                    width: 22,
                    height: 44,
                    decoration: BoxDecoration(
                      color: intensities[i] > 0
                          ? const Color(0xFF66BB6A).withValues(
                              alpha: intensities[i] * 0.7 + 0.15)
                          : c.chipBg,
                      borderRadius: BorderRadius.circular(6),
                      border: isToday
                          ? Border.all(
                              color: const Color(0xFF66BB6A), width: 1.5)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isToday
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isToday
                          ? c.textPrimary
                          : c.textSecondary,
                    ),
                  ),
                ],
              );
            }),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─────────── Mini Exam Planner Card ───────────

class _MiniExamPlannerCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniExamPlannerCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);

    return _MiniCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniCardHeader(
            emoji: '📚',
            title: 'Exams',
            tag: 'Study',
            tagColor: const Color(0xFF42A5F5).withValues(alpha: 0.18),
            tagTextColor: const Color(0xFF1565C0),
          ),
          const SizedBox(height: 10),
          _MiniExamRow(
            subject: 'Mathematics',
            date: 'Oct 24',
            daysLeft: 2,
            color: const Color(0xFFFF6B6B),
            c: c,
          ),
          const SizedBox(height: 8),
          _MiniExamRow(
            subject: 'Physics',
            date: 'Oct 28',
            daysLeft: 6,
            color: const Color(0xFFFFB347),
            c: c,
          ),
          const Spacer(),
          Text(
            'Tap to view all →',
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF1565C0).withValues(alpha: 0.65),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MiniExamRow extends StatelessWidget {
  final String subject;
  final String date;
  final int daysLeft;
  final Color color;
  final AppColors c;

  const _MiniExamRow({
    required this.subject,
    required this.date,
    required this.daysLeft,
    required this.color,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$date · $daysLeft days',
                style: TextStyle(fontSize: 10, color: c.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────── Mini Art Shuffle Card ───────────

class _MiniArtShuffleCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniArtShuffleCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient as placeholder
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6A3093), Color(0xFFA044FF)],
                ),
              ),
            ),
            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            // Content
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'The Potato Field',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'van Gogh',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shuffle_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────── Mini Stat ───────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: c.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Keep FeedCard exported for any other screen that might reference it
class FeedCard extends StatelessWidget {
  final String title;
  final String tag;
  final String type;

  const FeedCard({super.key, required this.title, required this.tag, required this.type});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
