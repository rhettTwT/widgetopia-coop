import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';
import '../models/saved_widget_model.dart';
import '../services/habit_service.dart';
import '../services/home_widget_service.dart';
import '../services/saved_widgets_service.dart';
import '../widgets/detail_hero_shell.dart';

// ─── Color Palettes ───
const _habitColors = [
  Color(0xFF4FC3F7),
  Color(0xFFE040FB),
  Color(0xFF00E5FF),
  Color(0xFFFFCA28),
  Color(0xFF69F0AE),
  Color(0xFFFF7043),
  Color(0xFFAB47BC),
  Color(0xFFEF5350),
];

const _habitEmojis = [
  "🏃", "💧", "📖", "🧘", "🥗", "💪", "🎯", "🌅",
  "💤", "🎨", "🎵", "✍️", "🧠", "🫀", "🍎", "🚴",
];

const _dayLabels = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];

// ──────────────────────────────────────────
//  Theme data (matches timer/quote/notepad)
// ──────────────────────────────────────────
class _HabitScreenTheme {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color textColor;
  final Color cardColor;

  const _HabitScreenTheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.textColor,
    required this.cardColor,
  });
}

const List<_HabitScreenTheme> _themes = [
  _HabitScreenTheme(
    name: 'Latte',
    primary: Color(0xFFD4A574),
    secondary: Color(0xFFE8C9A0),
    accent: Color(0xFFC08552),
    background: Color(0xFFFFF8EE),
    textColor: Color(0xFF4A3728),
    cardColor: Color(0xFFFFF0DC),
  ),
  _HabitScreenTheme(
    name: 'Berry',
    primary: Color(0xFFD4728C),
    secondary: Color(0xFFE8A0B4),
    accent: Color(0xFFC05272),
    background: Color(0xFFFFF0F3),
    textColor: Color(0xFF4A2838),
    cardColor: Color(0xFFFFE0E8),
  ),
  _HabitScreenTheme(
    name: 'Matcha',
    primary: Color(0xFF74B88A),
    secondary: Color(0xFFA0D4B0),
    accent: Color(0xFF52996A),
    background: Color(0xFFF0FFF4),
    textColor: Color(0xFF28472E),
    cardColor: Color(0xFFDCF5E4),
  ),
  _HabitScreenTheme(
    name: 'Lavender',
    primary: Color(0xFF9B8EC4),
    secondary: Color(0xFFBDB2D8),
    accent: Color(0xFF7B6EA4),
    background: Color(0xFFF5F0FF),
    textColor: Color(0xFF352E4A),
    cardColor: Color(0xFFEAE0FF),
  ),
];

// ═══════════════════════════════════════════════════════
//  MAIN SCREEN — Widget Detail Style
// ═══════════════════════════════════════════════════════
class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen>
    with TickerProviderStateMixin {
  List<HabitModel> _habits = [];
  bool _loading = true;

  // Theme
  int _themeIndex = 0;
  _HabitScreenTheme get _theme => _themes[_themeIndex];

  bool _isFavorite = false;

  late AnimationController _breathController;
  late Animation<double> _breathAnim;

  int get _completedToday => _habits.where((h) => h.isCompletedToday).length;

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
    _load();
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final habits = await HabitService.getAll();
    setState(() {
      _habits = habits;
      _loading = false;
    });
    _updateHomeWidget();
  }

  Future<void> _save() async {
    await HabitService.saveAll(_habits);
    _updateHomeWidget();
  }

  void _updateHomeWidget() {
    HomeWidgetService.updateHabitProgress(_completedToday, _habits.length, habits: _habits);
    HomeWidgetService.updateHabitHeatmap(_habits);
  }

  void _toggleHabit(HabitModel habit) {
    setState(() => habit.toggleToday());
    _save();
  }

  void _deleteHabit(String id) {
    setState(() => _habits.removeWhere((h) => h.id == id));
    _save();
  }

  void _openDetail(HabitModel habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _HabitDetailScreen(
          habit: habit,
          theme: _theme,
          onUpdate: () {
            setState(() {});
            _save();
          },
        ),
      ),
    );
  }

  void _showAddHabit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateHabitSheet(
        theme: _theme,
        onSave: (habit) {
          setState(() => _habits.add(habit));
          _save();
        },
      ),
    );
  }

  void _setTheme(int index) => setState(() => _themeIndex = index);

  // ══════════════════════════════════════
  //  BUILD — Widget Detail Page Style
  // ══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _theme.background,
        body: Center(child: CircularProgressIndicator(color: _theme.accent)),
      );
    }

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
                  child: _buildHabitListSection(),
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

  Widget _buildHeroPreview() {
    final bestStreak = _habits.isEmpty
        ? 0
        : _habits.map((h) => h.currentStreak).reduce(max);

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
      emotionalLabel: 'Build Momentum 🔥',
      decorationSeed: 77,
      content: _buildHabitHeroContent(bestStreak),
    );
  }

  Widget _buildHabitHeroContent(int bestStreak) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _theme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.local_fire_department_rounded,
            size: 26,
            color: _theme.accent,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$bestStreak',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: _theme.textColor,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'day streak',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _theme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$_completedToday/${_habits.length} today',
          style: TextStyle(
            fontSize: 12,
            color: _theme.textColor.withValues(alpha: 0.4),
          ),
        ),
        if (_habits.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _habits.isEmpty
                  ? 0
                  : _completedToday / _habits.length,
              minHeight: 4,
              backgroundColor:
                  _theme.primary.withValues(alpha: 0.15),
              color: _theme.primary,
            ),
          ),
        ],
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
                child: Text(
                  'Habit Tracker',
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
                    Text('4.9',
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
            'Build lasting habits with streak tracking, heatmap visualization, and daily check-ins. Stay accountable and watch your consistency grow.',
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
            children: ['#habits', '#streaks', '#daily', '#heatmap']
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
                value: '10.8k',
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

  // ────────── Habit List Section ──────────

  Widget _buildHabitListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes_rounded,
                    size: 18,
                    color: _theme.textColor.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Text(
                  'My Habits',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _theme.textColor,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _showAddHabit,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: _theme.accent),
                    const SizedBox(width: 3),
                    Text('Add',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _theme.accent,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_habits.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _theme.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.track_changes_rounded,
                    size: 48,
                    color: _theme.textColor.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Text('No habits yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _theme.textColor.withValues(alpha: 0.5),
                    )),
                const SizedBox(height: 4),
                Text('Tap Add to create your first habit',
                    style: TextStyle(
                      fontSize: 13,
                      color: _theme.textColor.withValues(alpha: 0.35),
                    )),
              ],
            ),
          )
        else
          ...List.generate(_habits.length, (i) {
            final habit = _habits[i];
            final habitColor =
                _habitColors[habit.colorIndex % _habitColors.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: _theme.primary.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: _theme.primary.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    children: [
                      Text(habit.emoji,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _theme.textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openDetail(habit),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: habitColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.bar_chart_rounded,
                              color: habitColor, size: 16),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _confirmDelete(context, habit),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Mini Heatmap
                  _MiniHeatmap(
                    habit: habit,
                    color: habitColor,
                    emptyColor: _theme.cardColor,
                  ),
                  const SizedBox(height: 12),

                  // Day chips
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          children: List.generate(7, (d) {
                            final active = habit.targetDays[d];
                            return Container(
                              width: 26,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active
                                    ? habitColor.withValues(alpha: 0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(5),
                                border: active
                                    ? null
                                    : Border.all(
                                        color: _theme.primary
                                            .withValues(alpha: 0.15),
                                        width: 1),
                              ),
                              child: Text(
                                _dayLabels[d],
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: active
                                      ? habitColor
                                      : _theme.textColor
                                          .withValues(alpha: 0.4),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Check-in button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleHabit(habit),
                      icon: Icon(
                        habit.isCompletedToday
                            ? Icons.check_circle
                            : Icons.add_circle_outline,
                        size: 18,
                      ),
                      label: Text(
                        habit.isCompletedToday ? 'Done!' : 'Check in',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: habit.isCompletedToday
                            ? habitColor.withValues(alpha: 0.15)
                            : habitColor,
                        foregroundColor:
                            habit.isCompletedToday ? habitColor : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _confirmDelete(BuildContext context, HabitModel habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Habit?",
            style: TextStyle(color: _theme.textColor)),
        content: Text(
          "\"${habit.name}\" and all its data will be removed.",
          style: TextStyle(color: _theme.textColor.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: TextStyle(
                    color: _theme.textColor.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteHabit(habit.id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
                      : Border.all(color: t.primary.withValues(alpha: 0.12)),
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
          type: 'habit',
          title: 'Habit Tracker',
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
}

// ═══════════════════════════════════════════════════════
//  MINI HEATMAP (7 rows x 7 cols — last 7 weeks)
// ═══════════════════════════════════════════════════════
class _MiniHeatmap extends StatelessWidget {
  final HabitModel habit;
  final Color color;
  final Color emptyColor;

  const _MiniHeatmap({
    required this.habit,
    required this.color,
    required this.emptyColor,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfThisWeek = today.subtract(Duration(days: today.weekday % 7));
    final gridStart = startOfThisWeek.subtract(const Duration(days: 42));

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = (constraints.maxWidth - 6 * 3) / 7;
        return Column(
          children: List.generate(7, (row) {
            return Padding(
              padding: EdgeInsets.only(bottom: row < 6 ? 3 : 0),
              child: Row(
                children: List.generate(7, (col) {
                  final dayOffset = col * 7 + row;
                  final date = gridStart.add(Duration(days: dayOffset));
                  final completed = habit.isCompleted(date);
                  final isToday =
                      date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;
                  final isFuture = date.isAfter(today);

                  return Container(
                    width: cellSize,
                    height: cellSize > 18 ? 18 : cellSize,
                    margin: EdgeInsets.only(right: col < 6 ? 3 : 0),
                    decoration: BoxDecoration(
                      color: isFuture
                          ? emptyColor.withValues(alpha: 0.4)
                          : completed
                          ? color
                          : emptyColor,
                      borderRadius: BorderRadius.circular(4),
                      border: isToday
                          ? Border.all(color: color, width: 2)
                          : null,
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
//  CREATE HABIT BOTTOM SHEET
// ═══════════════════════════════════════════════════════
class _CreateHabitSheet extends StatefulWidget {
  final _HabitScreenTheme theme;
  final Function(HabitModel) onSave;

  const _CreateHabitSheet({required this.theme, required this.onSave});

  @override
  State<_CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends State<_CreateHabitSheet> {
  final _nameController = TextEditingController();
  String _selectedEmoji = "🎯";
  int _selectedColor = 0;
  List<bool> _targetDays = List.filled(7, true);

  _HabitScreenTheme get t => widget.theme;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final habit = HabitModel(
      id: const Uuid().v4(),
      name: name,
      emoji: _selectedEmoji,
      colorIndex: _selectedColor,
      targetDays: _targetDays,
    );

    widget.onSave(habit);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Create New Habit",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: t.textColor,
                )),
            const SizedBox(height: 20),

            // Emoji Picker
            Text("Choose an Icon",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.textColor.withValues(alpha: 0.6),
                )),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _habitEmojis.map((e) {
                final selected = _selectedEmoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? t.accent.withValues(alpha: 0.15)
                          : t.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(color: t.accent, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Name
            Text("Habit Name",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.textColor.withValues(alpha: 0.6),
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: TextStyle(color: t.textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: "e.g. Drink more water",
                hintStyle: TextStyle(
                  color: t.textColor.withValues(alpha: 0.35),
                ),
                filled: true,
                fillColor: t.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Color
            Text("Color",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.textColor.withValues(alpha: 0.6),
                )),
            const SizedBox(height: 10),
            Row(
              children: List.generate(_habitColors.length, (i) {
                final selected = _selectedColor == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: _habitColors[i],
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: t.textColor, width: 3)
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color:
                                    _habitColors[i].withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Target Days
            Text("Target Days",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.textColor.withValues(alpha: 0.6),
                )),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final active = _targetDays[i];
                return GestureDetector(
                  onTap: () => setState(() {
                    _targetDays = List.from(_targetDays);
                    _targetDays[i] = !_targetDays[i];
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: active
                          ? _habitColors[_selectedColor]
                          : t.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dayLabels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? Colors.white
                            : t.textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text("Create Habit",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  HABIT DETAIL SCREEN (full heatmap + stats)
// ═══════════════════════════════════════════════════════
class _HabitDetailScreen extends StatefulWidget {
  final HabitModel habit;
  final _HabitScreenTheme theme;
  final VoidCallback onUpdate;

  const _HabitDetailScreen({
    required this.habit,
    required this.theme,
    required this.onUpdate,
  });

  @override
  State<_HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<_HabitDetailScreen> {
  HabitModel get habit => widget.habit;
  _HabitScreenTheme get t => widget.theme;

  Color get _habitColor => _habitColors[habit.colorIndex % _habitColors.length];

  void _toggleDay(DateTime date) {
    setState(() {
      if (habit.isCompleted(date)) {
        habit.uncheck(date);
      } else {
        habit.checkIn(date);
      }
    });
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: t.textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${habit.emoji}  ${habit.name}",
          style: TextStyle(
            color: t.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Stats Cards
          Row(
            children: [
              _DetailStat(
                icon: Icons.local_fire_department_rounded,
                value: "${habit.currentStreak}",
                label: "Current Streak",
                color: Colors.orange,
                theme: t,
              ),
              const SizedBox(width: 12),
              _DetailStat(
                icon: Icons.check_circle_outline,
                value: "${habit.totalCompletions}",
                label: "Total Check-ins",
                color: _habitColor,
                theme: t,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DetailStat(
                icon: Icons.percent_rounded,
                value: _completionRate(),
                label: "Completion Rate",
                color: const Color(0xFF69F0AE),
                theme: t,
              ),
              const SizedBox(width: 12),
              _DetailStat(
                icon: Icons.calendar_today_rounded,
                value: "${_daysSinceCreation()}",
                label: "Days Tracked",
                color: const Color(0xFF4FC3F7),
                theme: t,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Full Heatmap
          Text("Activity",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: t.textColor,
              )),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: t.primary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _FullHeatmap(
              habit: habit,
              color: _habitColor,
              emptyColor: t.cardColor,
              textColor: t.textColor.withValues(alpha: 0.5),
              onTapDay: _toggleDay,
            ),
          ),
          const SizedBox(height: 28),

          // Check In Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => habit.toggleToday());
                widget.onUpdate();
              },
              icon: Icon(
                habit.isCompletedToday
                    ? Icons.check_circle
                    : Icons.add_circle_outline,
                size: 22,
              ),
              label: Text(
                habit.isCompletedToday ? "Completed Today ✓" : "Check in Today",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: habit.isCompletedToday
                    ? _habitColor.withValues(alpha: 0.15)
                    : _habitColor,
                foregroundColor:
                    habit.isCompletedToday ? _habitColor : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Target Days
          Text("Target Days",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: t.textColor,
              )),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final active = habit.targetDays[i];
              return Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? _habitColor.withValues(alpha: 0.2)
                      : t.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: active
                      ? Border.all(color: _habitColor, width: 2)
                      : null,
                ),
                child: Text(
                  _dayLabels[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? _habitColor
                        : t.textColor.withValues(alpha: 0.5),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _completionRate() {
    final days = _daysSinceCreation();
    if (days == 0) return "0%";
    final rate = (habit.totalCompletions / days * 100).round();
    return "$rate%";
  }

  int _daysSinceCreation() {
    return DateTime.now().difference(habit.createdAt).inDays + 1;
  }
}

// ─── Detail Stat Card ───
class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final _HabitScreenTheme theme;

  const _DetailStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                )),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.textColor.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  FULL HEATMAP (rows = days of week, cols = weeks)
// ═══════════════════════════════════════════════════════
class _FullHeatmap extends StatelessWidget {
  final HabitModel habit;
  final Color color;
  final Color emptyColor;
  final Color textColor;
  final Function(DateTime) onTapDay;

  const _FullHeatmap({
    required this.habit,
    required this.color,
    required this.emptyColor,
    required this.textColor,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    const weeks = 12;
    final startOfThisWeek = today.subtract(Duration(days: today.weekday % 7));
    final gridStart =
        startOfThisWeek.subtract(Duration(days: (weeks - 1) * 7));

    final rowLabels = ["S", "M", "T", "W", "T", "F", "S"];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 20;
        final cellSize = (availableWidth - (weeks - 1) * 3) / weeks;
        final clampedSize = cellSize.clamp(10.0, 24.0);

        return Column(
          children: List.generate(7, (row) {
            return Padding(
              padding: EdgeInsets.only(bottom: row < 6 ? 3 : 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    child: Text(rowLabels[row],
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                  const SizedBox(width: 4),
                  ...List.generate(weeks, (col) {
                    final dayOffset = col * 7 + row;
                    final date = gridStart.add(Duration(days: dayOffset));
                    final completed = habit.isCompleted(date);
                    final isToday = date.year == today.year &&
                        date.month == today.month &&
                        date.day == today.day;
                    final isFuture = date.isAfter(today);

                    return GestureDetector(
                      onTap: isFuture ? null : () => onTapDay(date),
                      child: Container(
                        width: clampedSize,
                        height: clampedSize,
                        margin:
                            EdgeInsets.only(right: col < weeks - 1 ? 3 : 0),
                        decoration: BoxDecoration(
                          color: isFuture
                              ? emptyColor.withValues(alpha: 0.4)
                              : completed
                                  ? color
                                  : emptyColor,
                          borderRadius: BorderRadius.circular(4),
                          border: isToday
                              ? Border.all(color: color, width: 2)
                              : null,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
