import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:widgetopia/models/note_model.dart';
import 'package:widgetopia/models/saved_widget_model.dart';
import 'package:widgetopia/services/saved_widgets_service.dart';

// ──────────────────────────────────────────
//  Notepad theme data (matches timer/calendar)
// ──────────────────────────────────────────
class _NoteTheme {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color textColor;
  final Color cardColor;

  const _NoteTheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.textColor,
    required this.cardColor,
  });
}

const List<_NoteTheme> _themes = [
  _NoteTheme(
    name: 'Latte',
    primary: Color(0xFFD4A574),
    secondary: Color(0xFFE8C9A0),
    accent: Color(0xFFC08552),
    background: Color(0xFFFFF8EE),
    textColor: Color(0xFF4A3728),
    cardColor: Color(0xFFFFF0DC),
  ),
  _NoteTheme(
    name: 'Berry',
    primary: Color(0xFFD4728C),
    secondary: Color(0xFFE8A0B4),
    accent: Color(0xFFC05272),
    background: Color(0xFFFFF0F3),
    textColor: Color(0xFF4A2838),
    cardColor: Color(0xFFFFE0E8),
  ),
  _NoteTheme(
    name: 'Matcha',
    primary: Color(0xFF74B88A),
    secondary: Color(0xFFA0D4B0),
    accent: Color(0xFF52996A),
    background: Color(0xFFF0FFF4),
    textColor: Color(0xFF28472E),
    cardColor: Color(0xFFDCF5E4),
  ),
  _NoteTheme(
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
//  Notepad Screen — Widget Detail Style
// ══════════════════════════════════════
class NotepadDetailScreen extends StatefulWidget {
  const NotepadDetailScreen({super.key});

  @override
  State<NotepadDetailScreen> createState() => _NotepadDetailScreenState();
}

class _NotepadDetailScreenState extends State<NotepadDetailScreen>
    with SingleTickerProviderStateMixin {
  // Theme
  int _themeIndex = 0;
  _NoteTheme get _theme => _themes[_themeIndex];

  // Notes
  final _uuid = const Uuid();
  List<NoteModel> _notes = [];
  NoteModel? _activeNote;
  bool _isFavorite = false;

  late SharedPreferences _prefs;
  late AnimationController _breathController;
  late Animation<double> _breathAnim;

  final TextEditingController _editorCtrl = TextEditingController();

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
    _editorCtrl.dispose();
    super.dispose();
  }

  // ────────── Persistence ──────────

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString('notes');
    final themeIdx = _prefs.getInt('notepad_theme_index') ?? 0;

    if (raw != null) {
      final decoded = jsonDecode(raw) as List;
      _notes = decoded.map((e) => NoteModel.fromJson(e)).toList();
    }

    setState(() {
      _themeIndex = themeIdx;
      if (_notes.isNotEmpty) {
        _activeNote = _notes.first;
        _syncEditor();
      }
    });
  }

  Future<void> _saveNotes() async {
    await _prefs.setString(
      'notes',
      jsonEncode(_notes.map((e) => e.toJson()).toList()),
    );
  }

  void _syncEditor() {
    if (_activeNote != null && _activeNote!.type == NoteType.text) {
      _editorCtrl.text = _activeNote!.text;
    }
  }

  void _createNote(NoteType type) {
    final note = NoteModel(
      id: _uuid.v4(),
      title: type == NoteType.text ? 'New Note' : 'Checklist',
      type: type,
    );
    setState(() {
      _notes.insert(0, note);
      _activeNote = note;
      _syncEditor();
    });
    _saveNotes();
  }

  void _selectNote(NoteModel note) {
    setState(() {
      _activeNote = note;
      _syncEditor();
    });
  }

  void _deleteNote(NoteModel note) {
    setState(() {
      _notes.remove(note);
      if (_activeNote == note) {
        _activeNote = _notes.isNotEmpty ? _notes.first : null;
        _syncEditor();
      }
    });
    _saveNotes();
  }

  void _renameNote(NoteModel note) {
    final ctrl = TextEditingController(text: note.title);
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              'Rename Note',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: TextStyle(color: _theme.textColor),
              decoration: InputDecoration(
                hintText: 'Note title',
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
                    setState(() => note.title = ctrl.text.trim());
                    _saveNotes();
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Save',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Checklist helpers
  void _addChecklistItem(String text) {
    if (_activeNote == null || _activeNote!.type != NoteType.checklist) return;
    setState(() {
      _activeNote!.checklist.add(ChecklistItem(text: text));
    });
    _saveNotes();
  }

  void _toggleChecklistItem(int index) {
    if (_activeNote == null || index >= _activeNote!.checklist.length) return;
    setState(() {
      _activeNote!.checklist[index].done =
          !_activeNote!.checklist[index].done;
    });
    _saveNotes();
  }

  void _deleteChecklistItem(int index) {
    if (_activeNote == null || index >= _activeNote!.checklist.length) return;
    setState(() {
      _activeNote!.checklist.removeAt(index);
    });
    _saveNotes();
  }

  void _setTheme(int index) {
    setState(() => _themeIndex = index);
    _prefs.setInt('notepad_theme_index', index);
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
                  child: _buildNoteTabs(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _buildNoteEditor(),
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
    final noteCount = _notes.length;
    final checkCount = _notes
        .expand((n) => n.checklist)
        .where((c) => c.done)
        .length;
    final totalItems = _notes.expand((n) => n.checklist).length;

    return Container(
      margin: const EdgeInsets.all(16),
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _theme.cardColor,
            _theme.secondary.withValues(alpha: 0.4),
            _theme.background,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _theme.primary.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            ..._buildDecorations(),

            // Centered hero notepad icon
            Center(
              child: AnimatedBuilder(
                animation: _breathAnim,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _theme.primary.withValues(
                              alpha: 0.1 + _breathAnim.value * 0.06),
                          blurRadius: 24 + _breathAnim.value * 8,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: _theme.primary.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pencil icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _theme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            size: 26,
                            color: _theme.accent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Notepad',
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
                          '$noteCount notes',
                          style: TextStyle(
                            fontSize: 12,
                            color: _theme.textColor.withValues(alpha: 0.4),
                          ),
                        ),
                        if (totalItems > 0) ...[
                          const SizedBox(height: 8),
                          // Tiny progress bar for checklists
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: totalItems > 0
                                  ? checkCount / totalItems
                                  : 0,
                              minHeight: 4,
                              backgroundColor:
                                  _theme.primary.withValues(alpha: 0.15),
                              color: _theme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$checkCount/$totalItems done',
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  _theme.textColor.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Nav buttons
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _iconBtn(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        _iconBtn(
                          icon: _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          onTap: () =>
                              setState(() => _isFavorite = !_isFavorite),
                          color: _isFavorite ? Colors.redAccent : null,
                        ),
                        const SizedBox(width: 8),
                        _iconBtn(
                          icon: Icons.share_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon,
            size: 20,
            color: color ?? _theme.textColor.withValues(alpha: 0.7)),
      ),
    );
  }

  List<Widget> _buildDecorations() {
    final rng = Random(42);
    final List<Widget> items = [];
    final blobColors = [
      _theme.primary.withValues(alpha: 0.1),
      _theme.secondary.withValues(alpha: 0.12),
      const Color(0xFFFFD6E0).withValues(alpha: 0.12),
      const Color(0xFFD4E8D0).withValues(alpha: 0.12),
    ];
    for (int i = 0; i < 5; i++) {
      final size = 35.0 + rng.nextDouble() * 55;
      items.add(Positioned(
        left: rng.nextDouble() * 300,
        top: rng.nextDouble() * 250,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: blobColors[i % blobColors.length],
          ),
        ),
      ));
    }
    for (int i = 0; i < 10; i++) {
      final s = 3.0 + rng.nextDouble() * 5;
      items.add(Positioned(
        left: rng.nextDouble() * 340,
        top: rng.nextDouble() * 280,
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _theme.primary
                .withValues(alpha: 0.15 + rng.nextDouble() * 0.15),
          ),
        ),
      ));
    }
    // Tiny line decorations (like ruled paper)
    for (int i = 0; i < 4; i++) {
      items.add(Positioned(
        left: 30 + rng.nextDouble() * 80,
        top: 60 + i * 55.0,
        child: Container(
          width: 60 + rng.nextDouble() * 40,
          height: 1.5,
          decoration: BoxDecoration(
            color: _theme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ));
    }
    return items;
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
                  'Personal Notepad',
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
                      '4.8',
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
            'A cozy, minimal notepad for your thoughts, lists, and quick ideas. Supports both free-text notes and checklists with a warm aesthetic.',
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
            children: ['#notes', '#checklist', '#minimal', '#productivity']
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
                value: '12.3k',
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
                value: '2.4k',
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

  // ────────── Note Tabs (scrollable chips) ──────────

  Widget _buildNoteTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.visibility_rounded,
                size: 18, color: _theme.textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              'Your Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              ),
            ),
            const Spacer(),
            // New note button
            PopupMenuButton<NoteType>(
              onSelected: _createNote,
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _theme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded,
                    size: 20, color: _theme.accent),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: _theme.background,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: NoteType.text,
                  child: Row(
                    children: [
                      Icon(Icons.article_rounded,
                          size: 18, color: _theme.accent),
                      const SizedBox(width: 10),
                      Text('Text Note',
                          style: TextStyle(color: _theme.textColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: NoteType.checklist,
                  child: Row(
                    children: [
                      Icon(Icons.checklist_rounded,
                          size: 18, color: _theme.accent),
                      const SizedBox(width: 10),
                      Text('Checklist',
                          style: TextStyle(color: _theme.textColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal note chips
        if (_notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'Tap + to create your first note',
                style: TextStyle(
                  fontSize: 13,
                  color: _theme.textColor.withValues(alpha: 0.35),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _notes.length,
              separatorBuilder: (context2, index2) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final note = _notes[i];
                final isActive = _activeNote?.id == note.id;
                return GestureDetector(
                  onTap: () => _selectNote(note),
                  onLongPress: () => _showNoteActionsSheet(note),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _theme.primary.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: isActive
                          ? Border.all(color: _theme.primary, width: 1.5)
                          : Border.all(
                              color: _theme.primary.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          note.type == NoteType.text
                              ? Icons.article_outlined
                              : Icons.checklist_rounded,
                          size: 16,
                          color: isActive
                              ? _theme.accent
                              : _theme.textColor.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          note.title.length > 14
                              ? '${note.title.substring(0, 14)}…'
                              : note.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isActive
                                ? _theme.accent
                                : _theme.textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showNoteActionsSheet(NoteModel note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _theme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              note.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              ),
            ),
            const SizedBox(height: 20),
            _actionTile(
              icon: Icons.edit_rounded,
              label: 'Rename',
              onTap: () {
                Navigator.pop(ctx);
                _renameNote(note);
              },
            ),
            _actionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: Colors.red.shade400,
              onTap: () {
                Navigator.pop(ctx);
                _deleteNote(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? _theme.accent),
      title: Text(label,
          style: TextStyle(
            color: color ?? _theme.textColor,
            fontWeight: FontWeight.w500,
          )),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ────────── Note Editor (interactive preview) ──────────

  Widget _buildNoteEditor() {
    if (_activeNote == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _theme.primary.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Icon(Icons.note_add_rounded,
                size: 40, color: _theme.textColor.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(
              'Create a note to get started',
              style: TextStyle(
                fontSize: 14,
                color: _theme.textColor.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      );
    }

    final note = _activeNote!;

    return Container(
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
        border: Border.all(color: _theme.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _theme.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note header bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _theme.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  note.type == NoteType.text
                      ? Icons.article_rounded
                      : Icons.checklist_rounded,
                  size: 18,
                  color: _theme.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _theme.textColor,
                    ),
                  ),
                ),
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    note.type == NoteType.text ? 'Text' : 'Checklist',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _theme.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content area
          if (note.type == NoteType.text) _buildTextEditor(note),
          if (note.type == NoteType.checklist) _buildChecklistEditor(note),
        ],
      ),
    );
  }

  Widget _buildTextEditor(NoteModel note) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          // Ruled-paper lines behind the text field
          Stack(
            children: [
              // Ruled lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _RuledLinesPainter(
                    lineColor: _theme.primary.withValues(alpha: 0.06),
                    lineSpacing: 28,
                  ),
                ),
              ),
              TextField(
                controller: _editorCtrl,
                maxLines: 8,
                minLines: 5,
                style: TextStyle(
                  fontSize: 14,
                  height: 2.0,
                  color: _theme.textColor,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Start writing…',
                  hintStyle: TextStyle(
                    color: _theme.textColor.withValues(alpha: 0.25),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                onChanged: (v) {
                  note.text = v;
                  _saveNotes();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Word count
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${note.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
              style: TextStyle(
                fontSize: 11,
                color: _theme.textColor.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistEditor(NoteModel note) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        children: [
          // Checklist items
          if (note.checklist.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No items yet',
                style: TextStyle(
                  fontSize: 13,
                  color: _theme.textColor.withValues(alpha: 0.3),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...List.generate(note.checklist.length, (i) {
              final item = note.checklist[i];
              final accentColor = [
                _theme.primary,
                const Color(0xFFD4728C),
                const Color(0xFF74B88A),
                const Color(0xFF9B8EC4),
              ][i % 4];

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
                          color: accentColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: item.done
                                ? _theme.cardColor.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _theme.primary.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _toggleChecklistItem(i),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: item.done
                                          ? _theme.primary
                                          : _theme.primary
                                              .withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    color: item.done
                                        ? _theme.primary
                                            .withValues(alpha: 0.15)
                                        : Colors.transparent,
                                  ),
                                  child: item.done
                                      ? Icon(Icons.check_rounded,
                                          size: 15, color: _theme.accent)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: item.done
                                        ? _theme.textColor
                                            .withValues(alpha: 0.35)
                                        : _theme.textColor,
                                    decoration: item.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: _theme.textColor
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _deleteChecklistItem(i),
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

          const SizedBox(height: 8),

          // Add item row
          _AddChecklistItemRow(
            theme: _theme,
            onAdd: _addChecklistItem,
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
          type: 'notepad',
          title: 'Personal Notepad',
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
}

// ──────────────────────────────────────────
//  Add Checklist Item Row
// ──────────────────────────────────────────
class _AddChecklistItemRow extends StatefulWidget {
  final _NoteTheme theme;
  final ValueChanged<String> onAdd;

  const _AddChecklistItemRow({required this.theme, required this.onAdd});

  @override
  State<_AddChecklistItemRow> createState() => _AddChecklistItemRowState();
}

class _AddChecklistItemRowState extends State<_AddChecklistItemRow> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_ctrl.text.trim().isNotEmpty) {
      widget.onAdd(_ctrl.text.trim());
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: TextStyle(fontSize: 14, color: t.textColor),
            decoration: InputDecoration(
              hintText: 'Add item…',
              hintStyle: TextStyle(
                color: t.textColor.withValues(alpha: 0.3),
                fontStyle: FontStyle.italic,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _submit,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [t.primary, t.accent]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: t.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded,
                color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
//  Ruled Lines Painter (for text notes)
// ──────────────────────────────────────────
class _RuledLinesPainter extends CustomPainter {
  final Color lineColor;
  final double lineSpacing;

  _RuledLinesPainter({required this.lineColor, required this.lineSpacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    double y = lineSpacing;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant _RuledLinesPainter old) =>
      old.lineColor != lineColor || old.lineSpacing != lineSpacing;
}
