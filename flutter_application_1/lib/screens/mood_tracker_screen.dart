import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/mood_data.dart';
import '../models/mood_entry_model.dart';
import '../models/saved_widget_model.dart';
import '../services/mood_service.dart';
import '../services/saved_widgets_service.dart';
import '../services/home_widget_service.dart';
import '../widgets/detail_hero_shell.dart';

// ──────────────────────────────────────────
//  Theme data (matches timer/quote/notepad/habit)
// ──────────────────────────────────────────
class _MoodScreenTheme {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color textColor;
  final Color cardColor;

  const _MoodScreenTheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.textColor,
    required this.cardColor,
  });
}

const List<_MoodScreenTheme> _themes = [
  _MoodScreenTheme(
    name: 'Latte',
    primary: Color(0xFFD4A574),
    secondary: Color(0xFFE8C9A0),
    accent: Color(0xFFC08552),
    background: Color(0xFFFFF8EE),
    textColor: Color(0xFF4A3728),
    cardColor: Color(0xFFFFF0DC),
  ),
  _MoodScreenTheme(
    name: 'Berry',
    primary: Color(0xFFD4728C),
    secondary: Color(0xFFE8A0B4),
    accent: Color(0xFFC05272),
    background: Color(0xFFFFF0F3),
    textColor: Color(0xFF4A2838),
    cardColor: Color(0xFFFFE0E8),
  ),
  _MoodScreenTheme(
    name: 'Matcha',
    primary: Color(0xFF74B88A),
    secondary: Color(0xFFA0D4B0),
    accent: Color(0xFF52996A),
    background: Color(0xFFF0FFF4),
    textColor: Color(0xFF28472E),
    cardColor: Color(0xFFDCF5E4),
  ),
  _MoodScreenTheme(
    name: 'Lavender',
    primary: Color(0xFF9B8EC4),
    secondary: Color(0xFFBDB2D8),
    accent: Color(0xFF7B6EA4),
    background: Color(0xFFF5F0FF),
    textColor: Color(0xFF352E4A),
    cardColor: Color(0xFFEAE0FF),
  ),
];

// ══════════════════════════════════════
//  Mood Tracker Screen — Widget Detail Style
// ══════════════════════════════════════
class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _noteController = TextEditingController();
  List<MoodEntryModel> _entries = [];
  String? _selectedMoodId;
  bool _loading = true;
  bool _saving = false;
  late DateTime _calendarMonth;

  // Theme
  int _themeIndex = 0;
  _MoodScreenTheme get _theme => _themes[_themeIndex];
  bool _isFavorite = false;

  late AnimationController _breathController;
  late Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calendarMonth = DateTime(now.year, now.month);
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _breathController.dispose();
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
  int get _checkInCount => _entries.length;

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
        backgroundColor: _theme.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _updateHomeWidget() {
    if (_selectedMoodId != null) {
      final m = moodById(_selectedMoodId);
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final weekColors = <String>[];
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final entry = _entryForDate(_entries, date);
        if (entry != null) {
          final mood = moodById(entry.moodId);
          weekColors.add(
              '#${mood.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}');
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

  void _setTheme(int index) => setState(() => _themeIndex = index);

  // ══════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _theme.background,
        body: Center(child: CircularProgressIndicator(color: _theme.accent)),
      );
    }

    final selectedMood = moodById(_selectedMoodId);

    return Scaffold(
      backgroundColor: _theme.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeroPreview(selectedMood)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: _buildCheckInSection(selectedMood),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildNoteSection(selectedMood),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildMoodAnalysis(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildCalendarSection(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildInfluencesSection(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: _buildThemeVariations(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: _buildAddWidgetButton(),
          ),
        ],
      ),
    );
  }

  // ────────── Hero Preview ──────────

  Widget _buildHeroPreview(MoodOption selectedMood) {
    return DetailHeroShell(
      primary: _theme.primary,
      secondary: _theme.secondary,
      accent: _theme.accent,
      cardColor: _theme.cardColor,
      background: _theme.background,
      textColor: _theme.textColor,
      breathAnimation: _breathAnim,
      onBack: () => Navigator.pop(context),
      isFavorite: _isFavorite,
      onFavoriteToggle: () => setState(() => _isFavorite = !_isFavorite),
      onShare: () {},
      emotionalLabel: 'Feel & Reflect 🌿',
      decorationSeed: 55,
      onContentTap: () {
        final ids = moodOptions.map((m) => m.id).toList();
        final curIdx = ids.indexOf(_selectedMoodId ?? ids.first);
        setState(() => _selectedMoodId = ids[(curIdx + 1) % ids.length]);
        _saveToday();
      },
      content: _buildMoodHeroContent(selectedMood),
    );
  }

  Widget _buildMoodHeroContent(MoodOption selectedMood) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: selectedMood.color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              selectedMood.emoji,
              style: const TextStyle(fontSize: 30),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          selectedMood.label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _theme.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _checkInCount > 0
              ? '$_checkInCount check-ins'
              : 'No check-ins yet',
          style: TextStyle(
            fontSize: 12,
            color: _theme.textColor.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  // ────────── Info Card ──────────

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _theme.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: _theme.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Mood Tracker',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _theme.textColor,
                    )),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFB800), size: 18),
                    const SizedBox(width: 3),
                    Text('4.7',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _theme.textColor,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _theme.secondary.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('W',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _theme.accent,
                      )),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'by Widgetopia Studio',
                style: TextStyle(
                  fontSize: 13,
                  color: _theme.textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Track your emotions daily with beautiful mood check-ins, weekly analysis charts, and monthly calendar insights. Understand your emotional patterns.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: _theme.textColor.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['#mood', '#emotions', '#daily', '#wellness']
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _theme.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(tag,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _theme.accent,
                          )),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBadge(
                icon: Icons.download_rounded,
                value: '14.1k',
                label: 'downloads',
                badgeColor: const Color(0xFFFFF0DC),
                iconColor: _theme.primary,
              ),
              const SizedBox(width: 12),
              _statBadge(
                icon: Icons.palette_rounded,
                value: '4',
                label: 'themes',
                badgeColor: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF74B88A),
              ),
              const SizedBox(width: 12),
              _statBadge(
                icon: Icons.rate_review_rounded,
                value: '2.6k',
                label: 'reviews',
                badgeColor: const Color(0xFFF3E5F5),
                iconColor: const Color(0xFF9B8EC4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge({
    required IconData icon,
    required String value,
    required String label,
    required Color badgeColor,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 4),
                Text(value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _theme.textColor,
                    )),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  color: _theme.textColor.withValues(alpha: 0.45),
                )),
          ],
        ),
      ),
    );
  }

  // ────────── Check-In Section ──────────

  Widget _buildCheckInSection(MoodOption selectedMood) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _theme.primary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: _theme.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _checkInCount > 0
                ? '${_ordinal(_checkInCount)} CHECK-IN'
                : 'FIRST CHECK-IN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: _theme.textColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How are you today?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _theme.textColor,
            ),
          ),
          const SizedBox(height: 20),
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
                      width: selected ? 56 : 48,
                      height: selected ? 56 : 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: option.color.withValues(
                          alpha: selected ? 0.85 : 0.18,
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
                                  color: option.color.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        option.emoji,
                        style: TextStyle(fontSize: selected ? 26 : 22),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: selected
                            ? option.color
                            : _theme.textColor.withValues(alpha: 0.45),
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

  // ────────── Note + Save ──────────

  Widget _buildNoteSection(MoodOption selectedMood) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _theme.primary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: _theme.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add a note',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _theme.textColor,
              )),
          const SizedBox(height: 4),
          Text('A short reflection helps you spot trends.',
              style: TextStyle(
                  fontSize: 13,
                  color: _theme.textColor.withValues(alpha: 0.5))),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: _theme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 3,
              style: TextStyle(color: _theme.textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'What influenced your mood today?',
                hintStyle: TextStyle(
                    color: _theme.textColor.withValues(alpha: 0.3)),
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
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.favorite_rounded, size: 18),
              label: Text(
                _todayEntry == null
                    ? "Save today's mood"
                    : "Update today's mood",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _theme.accent,
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

  // ────────── Mood Analysis ──────────

  Widget _buildMoodAnalysis() {
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
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _theme.primary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: _theme.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mood Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              )),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('This week',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _theme.textColor,
                  )),
              const Spacer(),
              _navCircle(Icons.chevron_left_rounded),
              const SizedBox(width: 8),
              _navCircle(Icons.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _MoodChartPainter(weekMoods: weekMoods),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                .map((d) => Text(d,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _theme.textColor.withValues(alpha: 0.45),
                    )))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _navCircle(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _theme.cardColor,
        border: Border.all(color: _theme.primary.withValues(alpha: 0.15)),
      ),
      child: Icon(icon,
          size: 20, color: _theme.textColor.withValues(alpha: 0.5)),
    );
  }

  // ────────── Calendar ──────────

  Widget _buildCalendarSection() {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final monthLabel = DateFormat('MMM yyyy').format(_calendarMonth);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _theme.primary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: _theme.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(monthLabel,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _theme.textColor,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _calendarMonth = DateTime(year, month - 1);
                }),
                child: _navCircle(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() {
                  _calendarMonth = DateTime(year, month + 1);
                }),
                child: _navCircle(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((d) => SizedBox(
                      width: 38,
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _theme.textColor.withValues(alpha: 0.5),
                            )),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          _buildCalendarGrid(startWeekday, daysInMonth, year, month),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
      int startWeekday, int daysInMonth, int year, int month) {
    final today = DateTime.now();
    final rows = <Widget>[];
    int day = 1;
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
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          cells.add(_buildCalendarDay(day, entry, isToday));
          day++;
        }
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: cells,
        ),
      ));
    }
    return Column(children: rows);
  }

  Widget _buildCalendarDay(int day, MoodEntryModel? entry, bool isToday) {
    final mood = entry != null ? moodById(entry.moodId) : null;
    final hasEntry = entry != null;

    return SizedBox(
      width: 38,
      height: 48,
      child: Column(
        children: [
          Text('$day',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                color: isToday
                    ? _theme.accent
                    : _theme.textColor.withValues(alpha: 0.5),
              )),
          const SizedBox(height: 2),
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
                      color: _theme.primary.withValues(alpha: 0.4),
                      width: 1.5)
                  : null,
            ),
            child: hasEntry
                ? Text(_moodFace(mood!.id),
                    style: const TextStyle(fontSize: 16))
                : (isToday
                    ? Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _theme.primary.withValues(alpha: 0.4),
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

  // ────────── Influences ──────────

  Widget _buildInfluencesSection() {
    final influences = [
      _InfluenceItem(
          'Exercise', Icons.fitness_center_rounded, const Color(0xFF4ECDC4)),
      _InfluenceItem(
          'Sleep', Icons.bedtime_rounded, const Color(0xFF7B61FF)),
      _InfluenceItem(
          'Social', Icons.people_rounded, const Color(0xFFFF8FAB)),
      _InfluenceItem(
          'Work', Icons.work_rounded, const Color(0xFFFFC75F)),
      _InfluenceItem(
          'Nature', Icons.park_rounded, const Color(0xFF69F0AE)),
      _InfluenceItem(
          'Food', Icons.restaurant_rounded, const Color(0xFFFF7043)),
      _InfluenceItem(
          'Music', Icons.music_note_rounded, const Color(0xFF7CC6FE)),
      _InfluenceItem(
          'Reading', Icons.menu_book_rounded, const Color(0xFF8E7DF2)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _theme.primary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: _theme.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mood influences',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              )),
          const SizedBox(height: 6),
          Text(
            "Discover what adds to negative and positive aspects of your day",
            style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: _theme.textColor.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: influences.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: item.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 16, color: item.color),
                    const SizedBox(width: 6),
                    Text(item.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: item.color,
                        )),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ────────── Theme Variations ──────────

  Widget _buildThemeVariations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette_rounded,
                size: 18, color: _theme.textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text('Theme Variations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _theme.textColor,
                )),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_themes.length, (i) {
            final t = _themes[i];
            final sel = i == _themeIndex;
            return GestureDetector(
              onTap: () => _setTheme(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 76,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: sel
                      ? t.primary.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: sel
                      ? Border.all(color: t.primary, width: 2)
                      : Border.all(
                          color: t.primary.withValues(alpha: 0.12)),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: t.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dot(t.primary, 14),
                        const SizedBox(width: 4),
                        _dot(t.secondary, 14),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(t.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: t.textColor,
                        )),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _dot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // ────────── Add Widget Button ──────────

  Widget _buildAddWidgetButton() {
    return GestureDetector(
      onTap: () async {
        final widget = SavedWidgetModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'mood',
          title: 'Mood Tracker',
          config: {'theme': _themeIndex},
          createdAt: DateTime.now(),
        );
        await SavedWidgetsService.save(widget);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Widget added! ✨'),
            backgroundColor: _theme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_theme.primary, _theme.accent],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _theme.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Add Widget',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                )),
          ],
        ),
      ),
    );
  }

  // ────────── Helpers ──────────

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

  _MoodChartPainter({required this.weekMoods});

  double _moodToY(MoodOption mood, double height) {
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
      for (int i = 0; i < points.length; i++) {
        _drawMoodDot(canvas, points[i], moods[i]);
      }
      if (points.isEmpty) {
        final placeholderPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.08)
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

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final color1 = moods[i].color;
      final color2 = moods[i + 1].color;

      final linePaint = Paint()
        ..shader = LinearGradient(colors: [color1, color2])
            .createShader(Rect.fromPoints(p1, p2))
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(p1.dx, p1.dy);
      final controlX = (p2.dx - p1.dx) * 0.5;
      path.cubicTo(
          p1.dx + controlX, p1.dy, p2.dx - controlX, p2.dy, p2.dx, p2.dy);
      canvas.drawPath(path, linePaint);
    }

    if (points.length >= 2) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, h);
      fillPath.lineTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlX = (p2.dx - p1.dx) * 0.5;
        fillPath.cubicTo(
            p1.dx + controlX, p1.dy, p2.dx - controlX, p2.dy, p2.dx, p2.dy);
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

    for (int i = 0; i < points.length; i++) {
      _drawMoodDot(canvas, points[i], moods[i]);
    }
  }

  void _drawMoodDot(Canvas canvas, Offset center, MoodOption mood) {
    final glowPaint = Paint()
      ..color = mood.color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 14, glowPaint);

    final dotPaint = Paint()
      ..color = mood.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10, dotPaint);

    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, innerPaint);

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
