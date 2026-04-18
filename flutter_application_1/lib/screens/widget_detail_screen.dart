import 'package:flutter/material.dart';
import 'package:widgetopia/widgets/quote_widget_preview.dart';
import 'package:widgetopia/widgets/pomodoro_widget_preview.dart';
import 'package:widgetopia/widgets/notepad_widget_preview.dart';
import 'package:widgetopia/widgets/habit_widget_preview.dart';
import 'package:widgetopia/widgets/mood_widget_preview.dart';
import 'package:widgetopia/models/saved_widget_model.dart';
import 'package:widgetopia/services/saved_widgets_service.dart';
import 'package:widgetopia/data/widget_data.dart';
import 'package:widgetopia/widgets/widget_card.dart';
import 'package:widgetopia/widgets/detail_hero_shell.dart';

// ──────────────────────────────────────────
//  Theme data — distinct palette per variation
// ──────────────────────────────────────────
class _DetailTheme {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color textColor;
  final Color cardColor;

  const _DetailTheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.textColor,
    required this.cardColor,
  });
}

const List<_DetailTheme> _themes = [
  _DetailTheme(
    name: 'Latte',
    primary: Color(0xFFD4A574),
    secondary: Color(0xFFE8C9A0),
    accent: Color(0xFFC08552),
    background: Color(0xFFFFF8EE),
    textColor: Color(0xFF4A3728),
    cardColor: Color(0xFFFFF0DC),
  ),
  _DetailTheme(
    name: 'Berry',
    primary: Color(0xFFD4728C),
    secondary: Color(0xFFE8A0B4),
    accent: Color(0xFFC05272),
    background: Color(0xFFFFF0F3),
    textColor: Color(0xFF4A2838),
    cardColor: Color(0xFFFFE0E8),
  ),
  _DetailTheme(
    name: 'Matcha',
    primary: Color(0xFF74B88A),
    secondary: Color(0xFFA0D4B0),
    accent: Color(0xFF52996A),
    background: Color(0xFFF0FFF4),
    textColor: Color(0xFF28472E),
    cardColor: Color(0xFFDCF5E4),
  ),
  _DetailTheme(
    name: 'Lavender',
    primary: Color(0xFF9B8EC4),
    secondary: Color(0xFFBDB2D8),
    accent: Color(0xFF7B6EA4),
    background: Color(0xFFF5F0FF),
    textColor: Color(0xFF352E4A),
    cardColor: Color(0xFFEAE0FF),
  ),
];

class WidgetDetailScreen extends StatefulWidget {
  final String title;
  final String tag;
  final String type;

  const WidgetDetailScreen({
    super.key,
    required this.title,
    required this.tag,
    required this.type,
  });

  @override
  State<WidgetDetailScreen> createState() => _WidgetDetailScreenState();
}

class _WidgetDetailScreenState extends State<WidgetDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  bool _checking = true;
  bool _isFavorite = false;
  int _themeIndex = 0;

  _DetailTheme get _theme => _themes[_themeIndex];

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
    _checkSaved();
    SavedWidgetsService.changeNotifier.addListener(_checkSaved);
  }

  @override
  void dispose() {
    SavedWidgetsService.changeNotifier.removeListener(_checkSaved);
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _checkSaved() async {
    final saved = await SavedWidgetsService.isAlreadySaved(widget.type);
    if (!mounted) return;
    setState(() {
      _isSaved = saved;
      _checking = false;
    });
  }

  Future<void> _toggleSave() async {
    if (_isSaved) {
      await SavedWidgetsService.deleteByType(widget.type);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Widget removed 🗑️'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _theme.accent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      final model = SavedWidgetModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: widget.type,
        title: widget.title,
        config: {'theme': _themeIndex},
        createdAt: DateTime.now(),
      );
      await SavedWidgetsService.save(model);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Widget added! ✨'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _theme.accent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _setTheme(int index) => setState(() => _themeIndex = index);

  Widget _buildPreview() {
    switch (widget.type) {
      case 'quote':
        return const QuoteWidgetPreview(
          quote: 'Lets get this shit started',
          author: 'Me',
        );
      case 'pomodoro':
        return const PomodoroWidgetPreview();
      case 'notepad':
        return const NotepadWidgetPreview(theme: '');
      case 'habit':
        return const HabitWidgetPreview(interactive: true);
      case 'mood':
        return const MoodWidgetPreview(interactive: true);
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.widgets_rounded,
                size: 40,
                color: _theme.accent.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _theme.textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.tag,
              style: TextStyle(
                fontSize: 12,
                color: _theme.textColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        );
    }
  }

  // Helper to map widget type to an emotional label
  String get _emotionalLabel {
    switch (widget.type) {
      case 'quote':
        return 'Daily Wisdom ✨';
      case 'pomodoro':
        return 'Deep Focus ☕';
      case 'habit':
        return 'Build Momentum 🔥';
      case 'mood':
        return 'Feel & Reflect 🌿';
      case 'notepad':
        return 'Your Thoughts 📝';
      default:
        return 'Your Style ✨';
    }
  }

  // Helper to get widget-specific tags
  List<String> get _widgetTags {
    switch (widget.type) {
      case 'quote':
        return ['#quotes', '#inspiration', '#daily'];
      case 'pomodoro':
        return ['#focus', '#timer', '#productivity'];
      case 'habit':
        return ['#habits', '#streaks', '#daily'];
      case 'mood':
        return ['#mood', '#wellness', '#reflect'];
      case 'notepad':
        return ['#notes', '#creative', '#thoughts'];
      default:
        return ['#widget', '#aesthetic', '#minimal'];
    }
  }

  // Helper to get widget-specific description
  String get _widgetDescription {
    switch (widget.type) {
      case 'quote':
        return 'Daily inspiration delivered right to your home screen. Curated quotes to start your mornings right.';
      case 'pomodoro':
        return 'A warm, minimal pomodoro timer with gentle animations. Perfect for focused study sessions.';
      case 'habit':
        return 'Build lasting habits with streak tracking and daily check-ins. Watch your consistency grow.';
      case 'mood':
        return 'Track your emotions with beautiful mood check-ins and weekly analysis charts.';
      case 'notepad':
        return 'Jot down your thoughts quickly. A clean, minimal notepad right on your home screen.';
      default:
        return 'This widget brings a perfect balance of functionality and aesthetics to your home screen. Customize it to match your vibe.';
    }
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
              // ── Hero preview area ──
              SliverToBoxAdapter(child: _buildHeroPreview()),

              // ── Info card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoCard(),
                ),
              ),

              // ── Theme Variations ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildThemeVariations(),
                ),
              ),

              // ── You might also like ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: _buildRecommendations(),
                ),
              ),

              // Bottom padding for the fixed button
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // ── Fixed "Add Widget" button ──
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
      emotionalLabel: _emotionalLabel,
      decorationSeed: widget.type.hashCode,
      content: _buildPreview(),
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
                  widget.title,
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
                  child: Text(
                    'W',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _theme.accent,
                    ),
                  ),
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
            _widgetDescription,
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
            children: _widgetTags
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
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _theme.accent,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _statBadge(
                icon: Icons.download_rounded,
                value: '12.4k',
                label: 'downloads',
                badgeColor: const Color(0xFFFFF0DC),
                iconColor: _theme.primary,
              ),
              const SizedBox(width: 12),
              _statBadge(
                icon: Icons.bookmark_rounded,
                value: '8.2k',
                label: 'saves',
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
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _theme.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: _theme.textColor.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
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
                    Text(
                      t.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: t.textColor,
                      ),
                    ),
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

  // ────────── Recommendations ──────────

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded,
                size: 18, color: _theme.textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              'You might also like',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (ctx, idx) => const SizedBox(width: 16),
            itemBuilder: (_, i) {
              final item = widgetFeed[(i + 3) % widgetFeed.length];
              return SizedBox(
                width: 140,
                child: WidgetCard(
                  item: item,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WidgetDetailScreen(
                          title: item.title,
                          tag: item.tag,
                          type: item.type,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ────────── Add Widget Button (Gradient CTA) ──────────

  Widget _buildAddWidgetButton() {
    if (_checking) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: _toggleSave,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _isSaved
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_theme.primary, _theme.accent],
                ),
          color: _isSaved ? _theme.cardColor : null,
          borderRadius: BorderRadius.circular(18),
          border: _isSaved
              ? Border.all(color: _theme.primary.withValues(alpha: 0.2))
              : null,
          boxShadow: _isSaved
              ? []
              : [
                  BoxShadow(
                    color: _theme.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSaved ? Icons.bookmark_remove_outlined : Icons.download_rounded,
              color: _isSaved ? _theme.accent : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isSaved ? '✓ Saved — Tap to remove' : 'Add Widget',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _isSaved ? _theme.accent : Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
