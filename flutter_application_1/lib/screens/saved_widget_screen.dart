import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:widgetopia/models/saved_widget_model.dart';
import 'package:widgetopia/services/saved_widgets_service.dart';
import 'package:widgetopia/screens/timer_screen.dart';
import 'package:widgetopia/screens/quote_screen.dart';
import 'package:widgetopia/screens/notepad_detail_screen.dart';
import 'package:widgetopia/screens/calendar_screen.dart';
import 'package:widgetopia/screens/habit_tracker_screen.dart';
import 'package:widgetopia/screens/mood_tracker_screen.dart';
import 'package:widgetopia/screens/widget_detail_screen.dart';
import 'package:widgetopia/utils/theme_provider.dart';
import 'package:intl/intl.dart';

// ─── Sort options ───
enum _SortMode { newest, oldest, az, type }

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<SavedWidgetModel> _all = [];
  bool _loading = true;
  bool _gridMode = false;
  _SortMode _sort = _SortMode.newest;

  @override
  void initState() {
    super.initState();
    _load();
    SavedWidgetsService.changeNotifier.addListener(_onServiceChange);
  }

  @override
  void dispose() {
    SavedWidgetsService.changeNotifier.removeListener(_onServiceChange);
    super.dispose();
  }

  void _onServiceChange() => _load();

  Future<void> _load() async {
    final all = await SavedWidgetsService.getAll();
    if (!mounted) return;
    setState(() {
      _all = all;
      _loading = false;
    });
  }

  List<SavedWidgetModel> get _pinned =>
      _all.where((w) => w.isPinned).toList()
        ..sort((a, b) =>
            (a.pinnedAt ?? a.createdAt).compareTo(b.pinnedAt ?? b.createdAt));

  List<SavedWidgetModel> get _unpinned {
    final list = _all.where((w) => !w.isPinned).toList();
    switch (_sort) {
      case _SortMode.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortMode.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _SortMode.az:
        list.sort((a, b) =>
            a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()));
        break;
      case _SortMode.type:
        list.sort((a, b) => a.type.compareTo(b.type));
        break;
    }
    return list;
  }

  // ─── Navigation ───
  void _open(SavedWidgetModel item) {
    Widget page;
    switch (item.type) {
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
        page = WidgetDetailScreen(
            title: item.displayTitle, tag: item.type, type: item.type);
    }
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (c, a, s) => page,
        transitionsBuilder: (c, anim, s, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                  position: Tween(
                          begin: const Offset(0, 0.04), end: Offset.zero)
                      .animate(curved),
                  child: child));
        },
      ),
    );
  }

  // ─── Actions ───
  Future<void> _delete(SavedWidgetModel item) async {
    await SavedWidgetsService.delete(item.id);
  }

  Future<void> _togglePin(SavedWidgetModel item) async {
    HapticFeedback.lightImpact();
    await SavedWidgetsService.togglePin(item.id);
  }

  void _showContextMenu(SavedWidgetModel item) {
    final c = ThemeProvider.colorsOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContextSheet(
        item: item,
        colors: c,
        onPin: () async {
          Navigator.pop(context);
          await _togglePin(item);
        },
        onRename: () {
          Navigator.pop(context);
          _showRenameDialog(item);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _delete(item);
        },
      ),
    );
  }

  void _showRenameDialog(SavedWidgetModel item) {
    final c = ThemeProvider.colorsOf(context);
    final ctrl = TextEditingController(text: item.displayTitle);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.feedCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Widget',
            style: TextStyle(
                color: c.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter a name…',
            hintStyle: TextStyle(color: c.textSecondary),
            filled: true,
            fillColor: c.chipBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                await SavedWidgetsService.rename(item.id, newName);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ─── Build ───
  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saved',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                              letterSpacing: -0.5,
                            )),
                        Text(
                          '${_all.length} widget${_all.length == 1 ? '' : 's'}',
                          style: TextStyle(
                              fontSize: 14, color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Grid / list toggle
                  GestureDetector(
                    onTap: () => setState(() => _gridMode = !_gridMode),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.chipBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _gridMode
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        color: c.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Sort chips ──
            if (_all.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SortChip(
                          label: 'Newest',
                          selected: _sort == _SortMode.newest,
                          onTap: () =>
                              setState(() => _sort = _SortMode.newest)),
                      _SortChip(
                          label: 'Oldest',
                          selected: _sort == _SortMode.oldest,
                          onTap: () =>
                              setState(() => _sort = _SortMode.oldest)),
                      _SortChip(
                          label: 'A–Z',
                          selected: _sort == _SortMode.az,
                          onTap: () =>
                              setState(() => _sort = _SortMode.az)),
                      _SortChip(
                          label: 'Type',
                          selected: _sort == _SortMode.type,
                          onTap: () =>
                              setState(() => _sort = _SortMode.type)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 6),

            // ── Body ──
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: c.primary))
                  : _all.isEmpty
                      ? _EmptyState(colors: c)
                      : RefreshIndicator(
                          color: c.primary,
                          onRefresh: _load,
                          child: _gridMode
                              ? _buildGrid(c)
                              : _buildList(c),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Grid mode ───
  Widget _buildGrid(AppColors c) {
    final items = [..._pinned, ..._unpinned];
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) =>
          _GridCard(item: items[i], colors: c, onTap: _open, onLongPress: _showContextMenu),
    );
  }

  // ─── List mode ───
  Widget _buildList(AppColors c) {
    final pinned = _pinned;
    final unpinned = _unpinned;

    return CustomScrollView(
      slivers: [
        // Pinned section
        if (pinned.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Row(
                children: [
                  const Text('📌', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text('Pinned to Home',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.sectionHeaderColor)),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ListCard(
                item: pinned[i],
                colors: c,
                onTap: _open,
                onLongPress: _showContextMenu,
                onDismiss: _delete,
              ),
              childCount: pinned.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text('All Saved',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.sectionHeaderColor)),
            ),
          ),
        ],

        if (unpinned.isEmpty && pinned.isEmpty)
          SliverFillRemaining(child: _EmptyState(colors: c))
        else
          SliverReorderableList(
            itemCount: unpinned.length,
            onReorder: (oldIdx, newIdx) async {
              if (newIdx > oldIdx) newIdx--;
              final list = List<SavedWidgetModel>.from(unpinned);
              final item = list.removeAt(oldIdx);
              list.insert(newIdx, item);
              // Merge with pinned and persist
              await SavedWidgetsService.saveOrder([...pinned, ...list]);
            },
            itemBuilder: (_, i) => _ReorderableListCard(
              key: ValueKey(unpinned[i].id),
              item: unpinned[i],
              colors: c,
              index: i,
              onTap: _open,
              onLongPress: _showContextMenu,
              onDismiss: _delete,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ─────────── Grid Card ───────────

class _GridCard extends StatelessWidget {
  final SavedWidgetModel item;
  final AppColors colors;
  final void Function(SavedWidgetModel) onTap;
  final void Function(SavedWidgetModel) onLongPress;

  const _GridCard({
    required this.item,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: () => onTap(item),
      onLongPress: () => onLongPress(item),
      child: Container(
        decoration: BoxDecoration(
          color: c.feedCardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.2 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_emoji(item.type), style: const TextStyle(fontSize: 22)),
                const Spacer(),
                if (item.isPinned)
                  const Text('📌', style: TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.displayTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _typeColor(item.type, c).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.type.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _typeColor(item.type, c),
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Text(
              _timeAgo(item.createdAt),
              style: TextStyle(fontSize: 10, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────── List Card ───────────

class _ListCard extends StatelessWidget {
  final SavedWidgetModel item;
  final AppColors colors;
  final void Function(SavedWidgetModel) onTap;
  final void Function(SavedWidgetModel) onLongPress;
  final Future<void> Function(SavedWidgetModel) onDismiss;

  const _ListCard({
    required this.item,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Dismissible(
        key: Key('dismiss_${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 26),
        ),
        onDismissed: (_) => onDismiss(item),
        child: _CardTile(
            item: item,
            colors: colors,
            onTap: onTap,
            onLongPress: onLongPress),
      ),
    );
  }
}

// Reorderable version (same look, different parent)
class _ReorderableListCard extends StatelessWidget {
  final SavedWidgetModel item;
  final AppColors colors;
  final int index;
  final void Function(SavedWidgetModel) onTap;
  final void Function(SavedWidgetModel) onLongPress;
  final Future<void> Function(SavedWidgetModel) onDismiss;

  const _ReorderableListCard({
    required super.key,
    required this.item,
    required this.colors,
    required this.index,
    required this.onTap,
    required this.onLongPress,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Dismissible(
        key: Key('rd_${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 26),
        ),
        onDismissed: (_) => onDismiss(item),
        child: Row(
          children: [
            Expanded(
              child: _CardTile(
                  item: item,
                  colors: colors,
                  onTap: onTap,
                  onLongPress: onLongPress),
            ),
            const SizedBox(width: 8),
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle_rounded,
                  color: colors.textSecondary.withValues(alpha: 0.4),
                  size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final SavedWidgetModel item;
  final AppColors colors;
  final void Function(SavedWidgetModel) onTap;
  final void Function(SavedWidgetModel) onLongPress;

  const _CardTile({
    required this.item,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: () => onTap(item),
      onLongPress: () => onLongPress(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.feedCardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.15 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    _typeColor(item.type, c).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _emoji(item.type),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.displayTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isPinned) ...[
                        const SizedBox(width: 4),
                        const Text('📌',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _typeColor(item.type, c)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.type,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _typeColor(item.type, c),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(item.createdAt),
                        style: TextStyle(
                            fontSize: 11, color: c.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                color: c.textSecondary.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────── Context Sheet ───────────

class _ContextSheet extends StatelessWidget {
  final SavedWidgetModel item;
  final AppColors colors;
  final VoidCallback onPin;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ContextSheet({
    required this.item,
    required this.colors,
    required this.onPin,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      decoration: BoxDecoration(
        color: c.feedCardBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: c.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(_emoji(item.type),
                    style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.displayTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SheetOption(
            icon: item.isPinned
                ? Icons.push_pin_outlined
                : Icons.push_pin_rounded,
            label: item.isPinned ? 'Unpin from Home' : 'Pin to Home',
            color: const Color(0xFF5C6BC0),
            colors: c,
            onTap: onPin,
          ),
          _SheetOption(
            icon: Icons.edit_rounded,
            label: 'Rename',
            color: c.primary,
            colors: c,
            onTap: onRename,
          ),
          _SheetOption(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: Colors.redAccent,
            colors: c,
            onTap: onDelete,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final AppColors colors;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: label == 'Delete' ? Colors.redAccent : colors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─────────── Sort Chip ───────────

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.accent : c.chipBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : c.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────── Empty State ───────────

class _EmptyState extends StatelessWidget {
  final AppColors colors;

  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🗂️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No saved widgets yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save widgets from the Discover tab\nto see them here.',
            style: TextStyle(
              fontSize: 14,
              color: c.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────── Helpers ───────────

String _emoji(String type) {
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

Color _typeColor(String type, AppColors c) {
  switch (type) {
    case 'pomodoro':
      return c.primary;
    case 'quote':
      return const Color(0xFFFF6B6B);
    case 'calendar':
      return const Color(0xFF4ECDC4);
    case 'notepad':
      return const Color(0xFFFFB347);
    case 'habit':
      return const Color(0xFF7B61FF);
    case 'mood':
      return const Color(0xFFFF8FAB);
    case 'day_progress':
      return const Color(0xFF26A69A);
    case 'agenda':
      return const Color(0xFF5C6BC0);
    case 'weekly_agenda':
      return const Color(0xFF66BB6A);
    case 'exam_planner':
      return const Color(0xFF42A5F5);
    default:
      return c.textSecondary;
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 30) return DateFormat('MMM d').format(dt);
  if (diff.inDays > 1) return '${diff.inDays}d ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inHours > 1) return '${diff.inHours}h ago';
  if (diff.inMinutes > 1) return '${diff.inMinutes}m ago';
  return 'Just now';
}
