import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';

/// Compact habit tracker widget preview that can be shown as a saved widget card.
/// Supports inline check-in and shows a mini heatmap.
class HabitWidgetPreview extends StatefulWidget {
  final bool interactive;
  const HabitWidgetPreview({super.key, this.interactive = true});

  @override
  State<HabitWidgetPreview> createState() => _HabitWidgetPreviewState();
}

class _HabitWidgetPreviewState extends State<HabitWidgetPreview> {
  List<HabitModel> _habits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habits = await HabitService.getAll();
    if (mounted) setState(() { _habits = habits; _loading = false; });
  }

  Future<void> _save() async {
    await HabitService.saveAll(_habits);
  }

  int get _completedToday => _habits.where((h) => h.isCompletedToday).length;

  static const _habitColors = [
    Color(0xFF4FC3F7),
    Color(0xFFE040FB),
    Color(0xFF00E5FF),
    Color(0xFFFFCA28),
    Color(0xFF69F0AE),
    Color(0xFFFF7043),
    Color(0xFFAB47BC),
    Color(0xFFEF5350),
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4EE),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD4A574),
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Text("🎯", style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Text(
                "My Habits",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A3728),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A574).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${_habits.length} habits",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC08552),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              _MiniStat(
                value: "${_habits.length}",
                label: "Total",
                color: const Color(0xFF4FC3F7),
              ),
              const SizedBox(width: 12),
              _MiniStat(
                value: "$_completedToday",
                label: "Done today",
                color: const Color(0xFF69F0AE),
              ),
              const SizedBox(width: 12),
              _MiniStat(
                value: _habits.isNotEmpty
                    ? "${_habits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b)}"
                    : "0",
                label: "Best streak",
                color: const Color(0xFFFFCA28),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Habit list (up to 3)
          if (_habits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  "No habits yet — tap to create one!",
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF8C776A).withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          else
            ...List.generate(
              _habits.length > 3 ? 3 : _habits.length,
              (i) => _CompactHabitRow(
                habit: _habits[i],
                color: _habitColors[_habits[i].colorIndex % _habitColors.length],
                interactive: widget.interactive,
                onToggle: () {
                  if (!widget.interactive) return;
                  setState(() => _habits[i].toggleToday());
                  _save();
                },
              ),
            ),

          if (_habits.length > 3) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                "+${_habits.length - 3} more habits",
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFFC08552).withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
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
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF8C776A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactHabitRow extends StatelessWidget {
  final HabitModel habit;
  final Color color;
  final bool interactive;
  final VoidCallback onToggle;

  const _CompactHabitRow({
    required this.habit,
    required this.color,
    required this.interactive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Check button
          GestureDetector(
            onTap: interactive ? onToggle : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: habit.isCompletedToday
                    ? color
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: habit.isCompletedToday
                    ? null
                    : Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
              ),
              child: habit.isCompletedToday
                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          // Name + emoji
          Text(habit.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              habit.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: habit.isCompletedToday
                    ? const Color(0xFF4A3728).withValues(alpha: 0.45)
                    : const Color(0xFF4A3728),
                decoration: habit.isCompletedToday
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: const Color(0xFF4A3728).withValues(alpha: 0.3),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Mini 7-day dots
          ...List.generate(7, (d) {
            final date = today.subtract(Duration(days: 6 - d));
            final completed = habit.isCompleted(date);
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 3),
              decoration: BoxDecoration(
                color: completed
                    ? color
                    : const Color(0xFFE8DFD2),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ],
      ),
    );
  }
}
