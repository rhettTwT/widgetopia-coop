import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/mood_data.dart';
import '../models/mood_entry_model.dart';
import '../models/saved_widget_model.dart';
import '../services/mood_service.dart';
import '../services/saved_widgets_service.dart';
import '../services/home_widget_service.dart';
import '../utils/theme_provider.dart';
import '../widgets/ambient_background.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final TextEditingController _noteController = TextEditingController();
  List<MoodEntryModel> _entries = [];
  String? _selectedMoodId;
  bool _loading = true;
  bool _saving = false;
  late DateTime _calendarMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calendarMonth = DateTime(now.year, now.month);
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await MoodService.getAll();
    final today = _entryForDate(entries, DateTime.now());
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _selectedMoodId = today?.moodId;
      _noteController.text = today?.note ?? '';
      _loading = false;
    });
  }

  MoodEntryModel? _entryForDate(List<MoodEntryModel> entries, DateTime date) {
    final key = MoodService.dateKey(date);
    for (final entry in entries) {
      if (entry.dateKey == key) return entry;
    }
    return null;
  }

  MoodEntryModel? get _todayEntry => _entryForDate(_entries, DateTime.now());

  Future<void> _saveToday() async {
    if (_selectedMoodId == null || _saving) return;
    setState(() => _saving = true);

    final existing = _todayEntry;
    await MoodService.upsert(
      MoodEntryModel(
        dateKey: MoodService.dateKey(DateTime.now()),
        moodId: _selectedMoodId!,
        note: _noteController.text.trim(),
        createdAt: existing?.createdAt ?? DateTime.now(),
      ),
    );

    await _load();
    _updateHomeWidget();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Mood saved ✨'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: moodById(_selectedMoodId).color,
      ),
    );
  }

  void _updateHomeWidget() {
    if (_selectedMoodId != null) {
      final m = moodById(_selectedMoodId);

      // Build 7-day mood color list (Mon-Sun of current week)
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final weekColors = <String>[];
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final entry = _entryForDate(_entries, date);
        if (entry != null) {
          final mood = moodById(entry.moodId);
          weekColors.add('#${mood.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}');
        } else {
          weekColors.add('#E0D6F0');
        }
      }

      HomeWidgetService.updateMood(
        m.emoji,
        m.label,
        description: m.description,
        checkinCount: _entries.length,
        weekColors: weekColors,
      );
    }
  }

  Future<void> _addWidget() async {
    final widget = SavedWidgetModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'mood',
      title: 'Mood Tracker',
      config: {},
      createdAt: DateTime.now(),
    );
    await SavedWidgetsService.save(widget);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Widget added! ✨'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: moodById(_selectedMoodId).color,
      ),
    );
  }

  int get _checkInCount => _entries.length;

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    final selectedMood = moodById(_selectedMoodId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: c.primary))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    // ── Back button row ──
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: c.cardBg,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: c.shadow.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: c.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── CHECK-IN SECTION ──
                    _buildCheckInSection(c, selectedMood),

                    const SizedBox(height: 28),

                    // ── NOTE + SAVE ──
                    _buildNoteSection(c, selectedMood),

                    const SizedBox(height: 28),

                    // ── MOOD ANALYSIS CHART ──
                    _buildMoodAnalysis(c),

                    const SizedBox(height: 28),

                    // ── MONTHLY CALENDAR ──
                    _buildCalendarSection(c),

                    const SizedBox(height: 28),

                    // ── MOOD INFLUENCES ──
                    _buildInfluencesSection(c),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _addWidget,
            icon: const Icon(Icons.add_home_rounded),
            label: const Text('Add to Home Screen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedMood.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════ CHECK-IN SECTION ═══════════════

  Widget _buildCheckInSection(AppColors c, MoodOption selectedMood) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Check-in counter
          Text(
            _checkInCount > 0
                ? '${_ordinal(_checkInCount)} CHECK-IN'
                : 'FIRST CHECK-IN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How are you today?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          // Mood emoji row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: moodOptions.map((option) {
              final selected = _selectedMoodId == option.id;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedMoodId = option.id);
                  _saveToday();
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: selected ? 60 : 52,
                      height: selected ? 60 : 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: option.color.withValues(
                          alpha: selected ? 0.9 : 0.2,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? option.color
                              : option.color.withValues(alpha: 0.3),
                          width: selected ? 2.5 : 1.5,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: option.color.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        option.emoji,
                        style: TextStyle(fontSize: selected ? 28 : 24),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: selected ? option.color : c.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════ NOTE + SAVE ═══════════════

  Widget _buildNoteSection(AppColors c, MoodOption selectedMood) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a note',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A short reflection helps you spot trends.',
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: c.chipBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 3,
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'What influenced your mood today?',
                hintStyle: TextStyle(color: c.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _selectedMoodId == null ? null : _saveToday,
              icon: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.cardBg,
                      ),
                    )
                  : const Icon(Icons.favorite_rounded, size: 18),
              label: Text(
                _todayEntry == null
                    ? "Save today's mood"
                    : "Update today's mood",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedMood.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════ MOOD ANALYSIS CHART ═══════════════

  Widget _buildMoodAnalysis(AppColors c) {
    // Get this week's mood data (Mon - Sun)
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekMoods = <MoodOption?>[];
    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final entry = _entryForDate(_entries, date);
      weekMoods.add(entry != null ? moodById(entry.moodId) : null);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Analysis',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'This week',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              _navCircle(c, Icons.chevron_left_rounded),
              const SizedBox(width: 8),
              _navCircle(c, Icons.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: 20),
          // Chart area
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _MoodChartPainter(
                weekMoods: weekMoods,
                isDark: c.isDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                .map(
                  (d) => Text(
                    d,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _navCircle(AppColors c, IconData icon) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.chipBg,
        border: Border.all(color: c.divider),
      ),
      child: Icon(icon, size: 20, color: c.textSecondary),
    );
  }

  // ═══════════════ MONTHLY CALENDAR ═══════════════

  Widget _buildCalendarSection(AppColors c) {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun
    final monthLabel = DateFormat('MMM yyyy').format(_calendarMonth);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header
          Row(
            children: [
              Text(
                monthLabel,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _calendarMonth = DateTime(year, month - 1);
                }),
                child: _navCircle(c, Icons.chevron_left_rounded),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() {
                  _calendarMonth = DateTime(year, month + 1);
                }),
                child: _navCircle(c, Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (d) => SizedBox(
                    width: 38,
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          // Calendar grid
          _buildCalendarGrid(c, startWeekday, daysInMonth, year, month),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
    AppColors c,
    int startWeekday,
    int daysInMonth,
    int year,
    int month,
  ) {
    final today = DateTime.now();
    final rows = <Widget>[];
    int day = 1;

    // Calculate total cells needed
    final totalCells = startWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    for (int row = 0; row < rowCount; row++) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        final cellIndex = row * 7 + col;
        if (cellIndex < startWeekday || day > daysInMonth) {
          cells.add(const SizedBox(width: 38, height: 48));
        } else {
          final date = DateTime(year, month, day);
          final entry = _entryForDate(_entries, date);
          final isToday =
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          cells.add(_buildCalendarDay(c, day, entry, isToday));
          day++;
        }
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: cells,
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildCalendarDay(
    AppColors c,
    int day,
    MoodEntryModel? entry,
    bool isToday,
  ) {
    final mood = entry != null ? moodById(entry.moodId) : null;
    final hasEntry = entry != null;

    return SizedBox(
      width: 38,
      height: 48,
      child: Column(
        children: [
          // Day number
          Text(
            '$day',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              color: isToday ? c.primary : c.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          // Mood circle
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasEntry
                  ? mood!.color.withValues(alpha: 0.75)
                  : Colors.transparent,
              border: isToday && !hasEntry
                  ? Border.all(
                      color: c.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    )
                  : null,
            ),
            child: hasEntry
                ? Text(
                    _moodFace(mood!.id),
                    style: const TextStyle(fontSize: 16),
                  )
                : (isToday
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.primary.withValues(alpha: 0.4),
                          ),
                        )
                      : null),
          ),
        ],
      ),
    );
  }

  String _moodFace(String moodId) {
    switch (moodId) {
      case 'awful':
        return '😞';
      case 'low':
        return '😕';
      case 'okay':
        return '😐';
      case 'good':
        return '😊';
      case 'amazing':
        return '😄';
      default:
        return '😊';
    }
  }

  // ═══════════════ MOOD INFLUENCES ═══════════════

  Widget _buildInfluencesSection(AppColors c) {
    final influences = [
      _InfluenceItem(
        'Exercise',
        Icons.fitness_center_rounded,
        const Color(0xFF4ECDC4),
      ),
      _InfluenceItem('Sleep', Icons.bedtime_rounded, const Color(0xFF7B61FF)),
      _InfluenceItem('Social', Icons.people_rounded, const Color(0xFFFF8FAB)),
      _InfluenceItem('Work', Icons.work_rounded, const Color(0xFFFFC75F)),
      _InfluenceItem('Nature', Icons.park_rounded, const Color(0xFF69F0AE)),
      _InfluenceItem('Food', Icons.restaurant_rounded, const Color(0xFFFF7043)),
      _InfluenceItem(
        'Music',
        Icons.music_note_rounded,
        const Color(0xFF7CC6FE),
      ),
      _InfluenceItem(
        'Reading',
        Icons.menu_book_rounded,
        const Color(0xFF8E7DF2),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood influences',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Discover what adds to negative and positive aspects of your day",
            style: TextStyle(fontSize: 13, height: 1.5, color: c.textSecondary),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: influences.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: item.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 16, color: item.color),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: item.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════ HELPERS ═══════════════

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}TH';
    switch (n % 10) {
      case 1:
        return '${n}ST';
      case 2:
        return '${n}ND';
      case 3:
        return '${n}RD';
      default:
        return '${n}TH';
    }
  }
}

// ═══════════════ INFLUENCE ITEM MODEL ═══════════════

class _InfluenceItem {
  final String label;
  final IconData icon;
  final Color color;
  const _InfluenceItem(this.label, this.icon, this.color);
}

// ═══════════════ MOOD LINE CHART PAINTER ═══════════════

class _MoodChartPainter extends CustomPainter {
  final List<MoodOption?> weekMoods;
  final bool isDark;

  _MoodChartPainter({required this.weekMoods, required this.isDark});

  double _moodToY(MoodOption mood, double height) {
    // Map mood to 0..1 from bottom to top
    const ids = ['awful', 'low', 'okay', 'good', 'amazing'];
    final idx = ids.indexOf(mood.id);
    final fraction = idx / (ids.length - 1);
    final margin = 24.0;
    return height - margin - (fraction * (height - 2 * margin));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final segmentW = w / 6;

    // Collect valid points
    final points = <Offset>[];
    final moods = <MoodOption>[];
    for (int i = 0; i < 7; i++) {
      if (weekMoods[i] != null) {
        final x = i * segmentW;
        final y = _moodToY(weekMoods[i]!, h);
        points.add(Offset(x, y));
        moods.add(weekMoods[i]!);
      }
    }

    if (points.length < 2) {
      // Draw just dots if < 2 points
      for (int i = 0; i < points.length; i++) {
        _drawMoodDot(canvas, points[i], moods[i]);
      }

      if (points.isEmpty) {
        // Draw placeholder
        final placeholderPaint = Paint()
          ..color = (isDark ? Colors.white : Colors.black).withValues(
            alpha: 0.08,
          )
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        final path = Path();
        path.moveTo(0, h * 0.6);
        path.cubicTo(w * 0.2, h * 0.3, w * 0.4, h * 0.7, w * 0.5, h * 0.45);
        path.cubicTo(w * 0.6, h * 0.2, w * 0.8, h * 0.5, w, h * 0.35);
        canvas.drawPath(path, placeholderPaint);
      }
      return;
    }

    // Draw smooth curve through points
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final color1 = moods[i].color;
      final color2 = moods[i + 1].color;

      // Gradient line segment
      final linePaint = Paint()
        ..shader = LinearGradient(
          colors: [color1, color2],
        ).createShader(Rect.fromPoints(p1, p2))
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(p1.dx, p1.dy);
      final controlX = (p2.dx - p1.dx) * 0.5;
      path.cubicTo(
        p1.dx + controlX,
        p1.dy,
        p2.dx - controlX,
        p2.dy,
        p2.dx,
        p2.dy,
      );
      canvas.drawPath(path, linePaint);
    }

    // Draw fill under curve
    if (points.length >= 2) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, h);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlX = (p2.dx - p1.dx) * 0.5;
        fillPath.cubicTo(
          p1.dx + controlX,
          p1.dy,
          p2.dx - controlX,
          p2.dy,
          p2.dx,
          p2.dy,
        );
      }

      fillPath.lineTo(points.last.dx, h);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            moods.first.color.withValues(alpha: 0.15),
            moods.first.color.withValues(alpha: 0.01),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw dots on top
    for (int i = 0; i < points.length; i++) {
      _drawMoodDot(canvas, points[i], moods[i]);
    }
  }

  void _drawMoodDot(Canvas canvas, Offset center, MoodOption mood) {
    // Outer glow
    final glowPaint = Paint()
      ..color = mood.color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 14, glowPaint);

    // Main dot
    final dotPaint = Paint()
      ..color = mood.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10, dotPaint);

    // White inner circle
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, innerPaint);

    // Emoji text
    final textPainter = TextPainter(
      text: TextSpan(text: mood.emoji, style: const TextStyle(fontSize: 10)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _MoodChartPainter old) => true;
}
