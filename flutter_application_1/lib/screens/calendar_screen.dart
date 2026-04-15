import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgetopia/models/saved_widget_model.dart';
import 'package:widgetopia/services/saved_widgets_service.dart';
import 'package:widgetopia/widgets/detail_hero_shell.dart';

// ──────────────────────────────────────────
//  Calendar theme data (matches timer)
// ──────────────────────────────────────────
class _CalTheme {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color textColor;
  final Color cardColor;

  const _CalTheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.textColor,
    required this.cardColor,
  });
}

const List<_CalTheme> _themes = [
  _CalTheme(
    name: 'Latte',
    primary: Color(0xFFD4A574),
    secondary: Color(0xFFE8C9A0),
    accent: Color(0xFFC08552),
    background: Color(0xFFFFF8EE),
    textColor: Color(0xFF4A3728),
    cardColor: Color(0xFFFFF0DC),
  ),
  _CalTheme(
    name: 'Berry',
    primary: Color(0xFFD4728C),
    secondary: Color(0xFFE8A0B4),
    accent: Color(0xFFC05272),
    background: Color(0xFFFFF0F3),
    textColor: Color(0xFF4A2838),
    cardColor: Color(0xFFFFE0E8),
  ),
  _CalTheme(
    name: 'Matcha',
    primary: Color(0xFF74B88A),
    secondary: Color(0xFFA0D4B0),
    accent: Color(0xFF52996A),
    background: Color(0xFFF0FFF4),
    textColor: Color(0xFF28472E),
    cardColor: Color(0xFFDCF5E4),
  ),
  _CalTheme(
    name: 'Lavender',
    primary: Color(0xFF9B8EC4),
    secondary: Color(0xFFBDB2D8),
    accent: Color(0xFF7B6EA4),
    background: Color(0xFFF5F0FF),
    textColor: Color(0xFF352E4A),
    cardColor: Color(0xFFEAE0FF),
  ),
];

// Event category colors for visual variety
const List<Color> _eventAccents = [
  Color(0xFFD4A574),
  Color(0xFFD4728C),
  Color(0xFF74B88A),
  Color(0xFF9B8EC4),
  Color(0xFFE8C9A0),
  Color(0xFFC05272),
];

// ──────────────────────────────────────────
//  Calendar Screen — Widget Detail Style
// ──────────────────────────────────────────
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  // Theme
  int _themeIndex = 0;
  _CalTheme get _theme => _themes[_themeIndex];

  // Calendar state
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isFavorite = false;

  // Events: "yyyy-M-d" -> List<Map> with {text, done}
  Map<String, List<Map<String, dynamic>>> _events = {};
  late SharedPreferences _prefs;

  // Animation
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
    _loadData();
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  // ────────── Persistence ──────────

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString('calendar_events_v2');
    final themeIdx = _prefs.getInt('calendar_theme_index') ?? 0;
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _events = decoded.map((key, value) => MapEntry(
            key,
            (value as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
          ));
    }
    setState(() => _themeIndex = themeIdx);
  }

  Future<void> _saveEvents() async {
    await _prefs.setString('calendar_events_v2', jsonEncode(_events));
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  List<Map<String, dynamic>> _eventsFor(DateTime d) =>
      _events[_dayKey(d)] ?? [];

  bool _hasEvents(DateTime d) => (_events[_dayKey(d)]?.isNotEmpty ?? false);

  Future<void> _addEvent(String text) async {
    final key = _dayKey(_selectedDay);
    _events.putIfAbsent(key, () => []);
    _events[key]!.add({'text': text, 'done': false});
    await _saveEvents();
    setState(() {});
  }

  Future<void> _toggleEvent(int index) async {
    final key = _dayKey(_selectedDay);
    if (_events[key] != null && index < _events[key]!.length) {
      _events[key]![index]['done'] = !(_events[key]![index]['done'] ?? false);
      await _saveEvents();
      setState(() {});
    }
  }

  Future<void> _deleteEvent(int index) async {
    final key = _dayKey(_selectedDay);
    _events[key]?.removeAt(index);
    if (_events[key]?.isEmpty ?? false) _events.remove(key);
    await _saveEvents();
    setState(() {});
  }

  Future<void> _editEvent(int index, String newText) async {
    final key = _dayKey(_selectedDay);
    if (_events[key] != null && index < _events[key]!.length) {
      _events[key]![index]['text'] = newText;
      await _saveEvents();
      setState(() {});
    }
  }

  void _setTheme(int index) {
    setState(() => _themeIndex = index);
    _prefs.setInt('calendar_theme_index', index);
  }

  // ────────── Calendar helpers ──────────

  DateTime get _firstDayOfMonth =>
      DateTime(_focusedMonth.year, _focusedMonth.month, 1);

  int get _daysInMonth =>
      DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

  int get _startWeekday => _firstDayOfMonth.weekday; // 1=Mon, 7=Sun

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());

  void _prevMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  // ══════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _theme.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeroPreview()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: _buildCalendarPreview(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildEventsSection(),
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
  // ────────── Hero Preview ──────────

  Widget _buildHeroPreview() {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(_focusedMonth);
    final dayName = DateFormat('EEEE').format(now);

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
      emotionalLabel: 'Plan Your Days 📅',
      decorationSeed: 77,
      onContentTap: () {
        setState(() {
          _selectedDay = _selectedDay.add(const Duration(days: 1));
          // If we jump into next month, follow along
          if (_selectedDay.month != _focusedMonth.month ||
              _selectedDay.year != _focusedMonth.year) {
            _focusedMonth = DateTime(_selectedDay.year, _selectedDay.month);
          }
        });
      },
      content: _buildCalendarHeroContent(monthName, dayName, now),
    );
  }

  Widget _buildCalendarHeroContent(String monthName, String dayName, DateTime now) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          monthName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            color: _theme.textColor,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_focusedMonth.year}',
          style: TextStyle(
            fontSize: 12,
            color: _theme.textColor.withValues(alpha: 0.4),
          ),
        ),
        Divider(
          color: _theme.primary.withValues(alpha: 0.15),
          height: 20,
        ),
        Text(
          dayName,
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            color: _theme.textColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _theme.primary.withValues(alpha: 0.15),
            border: Border.all(
              color: _theme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '${now.day}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _theme.accent,
              ),
            ),
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
          // Title + Rating
          Row(
            children: [
              Expanded(
                child: Text(
                  'Aesthetic Calendar',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _theme.textColor,
                  ),
                ),
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
                    Text(
                      '4.9',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Creator
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

          // Description
          Text(
            'A warm, minimal calendar widget with soft pastel tones, elegant typography, and daily event tracking. Organize your days beautifully.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: _theme.textColor.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 14),

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['#minimal', '#planner', '#aesthetic', '#cozy']
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

          // Stats row
          Row(
            children: [
              _statBadge(
                icon: Icons.download_rounded,
                value: '8.7k',
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
                value: '1.8k',
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

  // ────────── Calendar Preview (interactive) ──────────

  Widget _buildCalendarPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.visibility_rounded,
                size: 18, color: _theme.textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              'Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Calendar card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _theme.cardColor,
                _theme.secondary.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: _theme.primary.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: _theme.primary.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Month header with navigation
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _prevMonth,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chevron_left_rounded,
                            size: 20, color: _theme.textColor),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          DateFormat('MMMM').format(_focusedMonth),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                            fontStyle: FontStyle.italic,
                            color: _theme.textColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${_focusedMonth.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _theme.textColor.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _nextMonth,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chevron_right_rounded,
                            size: 20, color: _theme.textColor),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Day-of-week headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                      .map((d) => SizedBox(
                            width: 36,
                            child: Center(
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _theme.textColor
                                      .withValues(alpha: 0.4),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),

              const SizedBox(height: 6),

              // Calendar grid
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                child: _buildCalendarGrid(),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final cells = <Widget>[];
    final blanks = _startWeekday - 1; // Mon=1, so 0 blanks if 1st is Mon

    // leading blank cells
    for (int i = 0; i < blanks; i++) {
      cells.add(const SizedBox(width: 36, height: 38));
    }

    // day cells
    for (int day = 1; day <= _daysInMonth; day++) {
      final date =
          DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isSelected = _isSameDay(date, _selectedDay);
      final isToday = _isToday(date);
      final hasEvt = _hasEvents(date);
      final isSunday = date.weekday == 7;

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDay = date),
          child: SizedBox(
            width: 36,
            height: 38,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? _theme.primary
                        : isToday
                            ? _theme.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                    border: isToday && !isSelected
                        ? Border.all(
                            color: _theme.primary.withValues(alpha: 0.4),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday || isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : isSunday
                                ? _theme.accent
                                : _theme.textColor
                                    .withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
                if (hasEvt)
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? _theme.primary
                          : _theme.accent.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Build rows of 7
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final end = (i + 7).clamp(0, cells.length);
      final row = cells.sublist(i, end);
      // pad last row if needed
      while (row.length < 7) {
        row.add(const SizedBox(width: 36, height: 38));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: row,
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  // ────────── Events Section ──────────

  Widget _buildEventsSection() {
    final dayName = DateFormat('EEEE').format(_selectedDay);
    final events = _eventsFor(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header (script style like Planbella)
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w300,
                color: _theme.textColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_selectedDay.day}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w200,
                color: _theme.textColor.withValues(alpha: 0.35),
              ),
            ),
            const Spacer(),
            // Add event button
            GestureDetector(
              onTap: _showAddEventSheet,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _theme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded,
                    size: 22, color: _theme.accent),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Thin vertical-line event list (Planbella style)
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_note_rounded,
                      size: 36,
                      color: _theme.textColor.withValues(alpha: 0.15)),
                  const SizedBox(height: 8),
                  Text(
                    'No events yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: _theme.textColor.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add one',
                    style: TextStyle(
                      fontSize: 12,
                      color: _theme.textColor.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(events.length, (i) {
            final evt = events[i];
            final done = evt['done'] == true;
            final accentColor =
                _eventAccents[i % _eventAccents.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Vertical accent line
                    Container(
                      width: 2.5,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Event content
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 14),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: done
                              ? _theme.cardColor.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _theme.primary.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Checkbox
                            GestureDetector(
                              onTap: () => _toggleEvent(i),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: done
                                        ? _theme.primary
                                        : _theme.primary
                                            .withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  color: done
                                      ? _theme.primary
                                          .withValues(alpha: 0.15)
                                      : Colors.transparent,
                                ),
                                child: done
                                    ? Icon(Icons.check_rounded,
                                        size: 15, color: _theme.accent)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                evt['text'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: done
                                      ? _theme.textColor
                                          .withValues(alpha: 0.35)
                                      : _theme.textColor,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor:
                                      _theme.textColor.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            // Actions
                            GestureDetector(
                              onTap: () => _showEditEventSheet(i),
                              child: Icon(Icons.edit_rounded,
                                  size: 16,
                                  color: _theme.textColor
                                      .withValues(alpha: 0.25)),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _deleteEvent(i),
                              child: Icon(Icons.close_rounded,
                                  size: 16,
                                  color: _theme.textColor
                                      .withValues(alpha: 0.25)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
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
            Text(
              'Theme Variations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              ),
            ),
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
          type: 'calendar',
          title: 'Aesthetic Calendar',
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
            Text(
              'Add Widget',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────── Bottom Sheets ──────────

  void _showAddEventSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: _theme.background,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _theme.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Event',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('EEEE, MMMM d').format(_selectedDay),
              style: TextStyle(
                fontSize: 13,
                color: _theme.textColor.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: TextStyle(color: _theme.textColor),
              decoration: InputDecoration(
                hintText: 'What\'s happening?',
                hintStyle:
                    TextStyle(color: _theme.textColor.withValues(alpha: 0.35)),
                filled: true,
                fillColor: _theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _theme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  if (ctrl.text.trim().isNotEmpty) {
                    _addEvent(ctrl.text.trim());
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Add',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEventSheet(int index) {
    final events = _eventsFor(_selectedDay);
    if (index >= events.length) return;
    final ctrl = TextEditingController(text: events[index]['text'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: _theme.background,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _theme.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Event',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _theme.textColor,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _deleteEvent(index);
                    Navigator.pop(ctx);
                  },
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade300),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: TextStyle(color: _theme.textColor),
              decoration: InputDecoration(
                hintText: 'Event name',
                hintStyle:
                    TextStyle(color: _theme.textColor.withValues(alpha: 0.35)),
                filled: true,
                fillColor: _theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _theme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  if (ctrl.text.trim().isNotEmpty) {
                    _editEvent(index, ctrl.text.trim());
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Save',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
