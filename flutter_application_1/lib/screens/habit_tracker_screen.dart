import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';

// ─── Color Palettes ───
const _habitColors = [
  Color(0xFF4FC3F7), // blue
  Color(0xFFE040FB), // pink/magenta
  Color(0xFF00E5FF), // cyan
  Color(0xFFFFCA28), // amber
  Color(0xFF69F0AE), // green
  Color(0xFFFF7043), // deep orange
  Color(0xFFAB47BC), // purple
  Color(0xFFEF5350), // red
];

const _habitEmojis = [
  "🏃", "💧", "📖", "🧘", "🥗", "💪", "🎯", "🌅",
  "💤", "🎨", "🎵", "✍️", "🧠", "🫀", "🍎", "🚴",
];

const _dayLabels = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];

// ─── Theme Holder ───
class HabitTheme {
  final Color background;
  final Color surface;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color gridEmpty;
  final Color divider;
  final Gradient? backgroundGradient;
  final List<Color> glowColors;

  const HabitTheme({
    required this.background,
    required this.surface,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.gridEmpty,
    required this.divider,
    this.backgroundGradient,
    required this.glowColors,
  });

  static const light = HabitTheme(
    background: Color(0xFFFFF8EE),
    surface: Color(0xFFFFF4D6),
    cardColor: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF4A3B2A),
    textSecondary: Color(0xFF8B7355),
    accent: Color(0xFF6B4F3A),
    gridEmpty: Color(0xFFEDE5D8),
    divider: Color(0xFFE8DFD2),
    glowColors: [Color(0xFFFFD6A5), Color(0xFFFFB4A2), Color(0xFFFFE5EC)],
  );

  static const dark = HabitTheme(
    background: Color(0xFF0D0D0D),
    surface: Color(0xFF1A1A1A),
    cardColor: Color(0xFF1E1E1E),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFF9E9E9E),
    accent: Color(0xFFFFCA28),
    gridEmpty: Color(0xFF2A2A2A),
    divider: Color(0xFF333333),
    glowColors: [Color(0xFF1A237E), Color(0xFF880E4F), Color(0xFF004D40)],
  );
}

// ═══════════════════════════════════════════════════════
//  MAIN SCREEN
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
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habits = await HabitService.getAll();
    setState(() {
      _habits = habits;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await HabitService.saveAll(_habits);
  }

  HabitTheme get _theme => _isDark ? HabitTheme.dark : HabitTheme.light;

  int get _completedToday => _habits.where((h) => h.isCompletedToday).length;

  void _toggleTheme() {
    setState(() => _isDark = !_isDark);
  }

  // ─── Add Habit ───
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

  // ─── Delete Habit ───
  void _deleteHabit(String id) {
    setState(() => _habits.removeWhere((h) => h.id == id));
    _save();
  }

  // ─── Toggle Check-in ───
  void _toggleHabit(HabitModel habit) {
    setState(() => habit.toggleToday());
    _save();
  }

  // ─── Open Detail ───
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

  @override
  Widget build(BuildContext context) {
    final t = _theme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Container(color: t.background),
          // Glow blobs
          Positioned(
            top: -100,
            left: -80,
            child: _Glow(color: t.glowColors[0], size: 260),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: _Glow(color: t.glowColors[1], size: 240),
          ),
          Positioned(
            bottom: -120,
            left: -60,
            child: _Glow(color: t.glowColors[2], size: 280),
          ),
          // Blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(color: Colors.transparent),
          ),
          // Content
          SafeArea(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: t.accent),
                  )
                : CustomScrollView(
                    slivers: [
                      // ─── Header ───
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "My Habits",
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: t.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Build routines that will lead you to success",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: t.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Theme toggle
                              GestureDetector(
                                onTap: _toggleTheme,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: t.cardColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isDark
                                        ? Icons.light_mode_rounded
                                        : Icons.dark_mode_rounded,
                                    color: t.accent,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ─── Stats Row ───
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Row(
                            children: [
                              _StatBadge(
                                value: "${_habits.length}",
                                label: "Total Habits",
                                color: const Color(0xFF4FC3F7),
                                theme: t,
                              ),
                              const SizedBox(width: 16),
                              _StatBadge(
                                value: "$_completedToday",
                                label: "Completed Today",
                                color: const Color(0xFF69F0AE),
                                theme: t,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ─── Create New Habit Button ───
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: GestureDetector(
                            onTap: _showAddHabit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: t.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: t.accent.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.add,
                                        color: t.accent, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    "Create New Habit",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: t.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.chevron_right,
                                      color: t.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ─── Habit Cards ───
                      if (_habits.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Icons.track_changes_rounded,
                                    size: 64,
                                    color: t.textSecondary.withValues(alpha: 0.4)),
                                const SizedBox(height: 16),
                                Text(
                                  "No habits yet",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: t.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tap the button above to create your first habit",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: t.textSecondary.withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _HabitCard(
                                habit: _habits[i],
                                theme: t,
                                onCheckIn: () => _toggleHabit(_habits[i]),
                                onTap: () => _openDetail(_habits[i]),
                                onDelete: () => _deleteHabit(_habits[i].id),
                              ),
                              childCount: _habits.length,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  STAT BADGE
// ═══════════════════════════════════════════════════════
class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final HabitTheme theme;

  const _StatBadge({
    required this.value,
    required this.label,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  GLOW BLOB
// ═══════════════════════════════════════════════════════
class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.45),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  HABIT CARD with Heatmap Grid
// ═══════════════════════════════════════════════════════
class _HabitCard extends StatelessWidget {
  final HabitModel habit;
  final HabitTheme theme;
  final VoidCallback onCheckIn;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.theme,
    required this.onCheckIn,
    required this.onTap,
    required this.onDelete,
  });

  Color get _habitColor =>
      _habitColors[habit.colorIndex % _habitColors.length];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: emoji + name + actions
            Row(
              children: [
                Text(habit.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Stats icon
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _habitColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.bar_chart_rounded,
                        color: _habitColor, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 18),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Mini Heatmap Grid (7 weeks) ──
            _MiniHeatmap(
              habit: habit,
              color: _habitColor,
              emptyColor: theme.gridEmpty,
            ),

            const SizedBox(height: 14),

            // Day labels row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Target day chips
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    children: List.generate(7, (i) {
                      final active = habit.targetDays[i];
                      return Container(
                        width: 28,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active
                              ? _habitColor.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: active
                              ? null
                              : Border.all(
                                  color: theme.gridEmpty, width: 1),
                        ),
                        child: Text(
                          _dayLabels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w400,
                            color: active
                                ? _habitColor
                                : theme.textSecondary,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Check in button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCheckIn,
                icon: Icon(
                  habit.isCompletedToday
                      ? Icons.check_circle
                      : Icons.add_circle_outline,
                  size: 20,
                ),
                label: Text(
                  habit.isCompletedToday ? "Done!" : "Check in",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: habit.isCompletedToday
                      ? _habitColor.withValues(alpha: 0.15)
                      : _habitColor,
                  foregroundColor: habit.isCompletedToday
                      ? _habitColor
                      : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Habit?",
            style: TextStyle(color: theme.textPrimary)),
        content: Text("\"${habit.name}\" and all its data will be removed.",
            style: TextStyle(color: theme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child:
                const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
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
    // Build a 7x7 grid (rows = weeks going back, cols = days of week)
    final today = DateTime.now();
    // Find the start: 6 weeks ago, Sunday
    final startOfThisWeek =
        today.subtract(Duration(days: today.weekday % 7));
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
                  final isToday = date.year == today.year &&
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
  final HabitTheme theme;
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

  HabitTheme get t => widget.theme;

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
        color: t.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "Create New Habit",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // ─── Emoji Picker ───
            Text("Choose an Icon",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.textSecondary)),
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
                          : t.gridEmpty,
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

            // ─── Name ───
            Text("Habit Name",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: TextStyle(color: t.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: "e.g. Drink more water",
                hintStyle: TextStyle(color: t.textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: t.gridEmpty,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Color ───
            Text("Color",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.textSecondary)),
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
                          ? Border.all(color: t.textPrimary, width: 3)
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color:
                                      _habitColors[i].withValues(alpha: 0.4),
                                  blurRadius: 8)
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // ─── Target Days ───
            Text("Target Days",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.textSecondary)),
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
                          : t.gridEmpty,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dayLabels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : t.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),

            // ─── Save Button ───
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor:
                      t == HabitTheme.dark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Create Habit",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
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
  final HabitTheme theme;
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
  HabitTheme get t => widget.theme;

  Color get _habitColor =>
      _habitColors[habit.colorIndex % _habitColors.length];

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
          icon: Icon(Icons.arrow_back_ios_new, color: t.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${habit.emoji}  ${habit.name}",
          style: TextStyle(
            color: t.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── Stats Cards ───
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

          // ─── Section: Full Heatmap ───
          Text(
            "Activity",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _FullHeatmap(
              habit: habit,
              color: _habitColor,
              emptyColor: t.gridEmpty,
              textColor: t.textSecondary,
              onTapDay: _toggleDay,
            ),
          ),

          const SizedBox(height: 28),

          // ─── Check In Button ───
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
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

          // ─── Target Days ───
          Text(
            "Target Days",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: t.textPrimary,
            ),
          ),
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
                      : t.gridEmpty,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      active ? Border.all(color: _habitColor, width: 2) : null,
                ),
                child: Text(
                  _dayLabels[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? _habitColor : t.textSecondary,
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
  final HabitTheme theme;

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
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  FULL HEATMAP (rows = days of week, cols = weeks)
//  Shows last 12 weeks with day labels
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
    // Find starting Sunday 12 weeks ago
    final startOfThisWeek =
        today.subtract(Duration(days: today.weekday % 7));
    final gridStart =
        startOfThisWeek.subtract(Duration(days: (weeks - 1) * 7));

    final rowLabels = ["S", "M", "T", "W", "T", "F", "S"];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 20; // space for labels
        final cellSize = (availableWidth - (weeks - 1) * 3) / weeks;
        final clampedSize = cellSize.clamp(10.0, 24.0);

        return Column(
          children: List.generate(7, (row) {
            return Padding(
              padding: EdgeInsets.only(bottom: row < 6 ? 3 : 0),
              child: Row(
                children: [
                  // Day label
                  SizedBox(
                    width: 16,
                    child: Text(
                      rowLabels[row],
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Cells
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
                        margin: EdgeInsets.only(right: col < weeks - 1 ? 3 : 0),
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
