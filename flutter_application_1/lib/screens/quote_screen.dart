import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgetopia/models/saved_widget_model.dart';
import 'package:widgetopia/services/saved_widgets_service.dart';
import 'package:widgetopia/services/home_widget_service.dart';

// ──────────────────────────────────────────
//  Quote theme data (matches timer/calendar/notepad)
// ──────────────────────────────────────────
class _QuoteTheme {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color textColor;
  final Color cardColor;

  const _QuoteTheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.textColor,
    required this.cardColor,
  });
}

const List<_QuoteTheme> _themes = [
  _QuoteTheme(
    name: 'Latte',
    primary: Color(0xFFD4A574),
    secondary: Color(0xFFE8C9A0),
    accent: Color(0xFFC08552),
    background: Color(0xFFFFF8EE),
    textColor: Color(0xFF4A3728),
    cardColor: Color(0xFFFFF0DC),
  ),
  _QuoteTheme(
    name: 'Berry',
    primary: Color(0xFFD4728C),
    secondary: Color(0xFFE8A0B4),
    accent: Color(0xFFC05272),
    background: Color(0xFFFFF0F3),
    textColor: Color(0xFF4A2838),
    cardColor: Color(0xFFFFE0E8),
  ),
  _QuoteTheme(
    name: 'Matcha',
    primary: Color(0xFF74B88A),
    secondary: Color(0xFFA0D4B0),
    accent: Color(0xFF52996A),
    background: Color(0xFFF0FFF4),
    textColor: Color(0xFF28472E),
    cardColor: Color(0xFFDCF5E4),
  ),
  _QuoteTheme(
    name: 'Lavender',
    primary: Color(0xFF9B8EC4),
    secondary: Color(0xFFBDB2D8),
    accent: Color(0xFF7B6EA4),
    background: Color(0xFFF5F0FF),
    textColor: Color(0xFF352E4A),
    cardColor: Color(0xFFEAE0FF),
  ),
];

// ──────────────────────────────────────────
//  Built-in quote collection
// ──────────────────────────────────────────
class _Quote {
  final String text;
  final String author;
  final String category;

  const _Quote(this.text, this.author, this.category);
}

const List<_Quote> _builtInQuotes = [
  _Quote('The only way to do great work is to love what you do.', 'Steve Jobs', 'motivation'),
  _Quote('Small steps every day lead to big changes.', 'Unknown', 'growth'),
  _Quote('Be yourself; everyone else is already taken.', 'Oscar Wilde', 'life'),
  _Quote('In the middle of difficulty lies opportunity.', 'Albert Einstein', 'resilience'),
  _Quote('Happiness is not something ready-made. It comes from your own actions.', 'Dalai Lama', 'happiness'),
  _Quote('The best time to plant a tree was 20 years ago. The second best time is now.', 'Chinese Proverb', 'motivation'),
  _Quote('Do what you can, with what you have, where you are.', 'Theodore Roosevelt', 'resilience'),
  _Quote('Not all those who wander are lost.', 'J.R.R. Tolkien', 'life'),
  _Quote('The mind is everything. What you think you become.', 'Buddha', 'mindfulness'),
  _Quote('It does not matter how slowly you go as long as you do not stop.', 'Confucius', 'growth'),
  _Quote('Believe you can and you\'re halfway there.', 'Theodore Roosevelt', 'motivation'),
  _Quote('Life is what happens when you\'re busy making other plans.', 'John Lennon', 'life'),
  _Quote('Simplicity is the ultimate sophistication.', 'Leonardo da Vinci', 'mindfulness'),
  _Quote('The future belongs to those who believe in the beauty of their dreams.', 'Eleanor Roosevelt', 'motivation'),
  _Quote('You must be the change you wish to see in the world.', 'Mahatma Gandhi', 'growth'),
  _Quote('Creativity takes courage.', 'Henri Matisse', 'creativity'),
  _Quote('Everything you can imagine is real.', 'Pablo Picasso', 'creativity'),
  _Quote('A calm mind brings inner strength and self-confidence.', 'Dalai Lama', 'mindfulness'),
  _Quote('What we think, we become.', 'Buddha', 'mindfulness'),
  _Quote('Turn your wounds into wisdom.', 'Oprah Winfrey', 'resilience'),
];

const List<String> _categories = [
  'all',
  'motivation',
  'growth',
  'life',
  'resilience',
  'mindfulness',
  'creativity',
  'happiness',
];

// ══════════════════════════════════════
//  Quote Screen — Widget Detail Style
// ══════════════════════════════════════
class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen>
    with SingleTickerProviderStateMixin {
  // Theme
  int _themeIndex = 0;
  _QuoteTheme get _theme => _themes[_themeIndex];

  // State
  int _currentIndex = 0;
  String _selectedCategory = 'all';
  bool _isFavorite = false;
  List<int> _favoriteIndices = [];
  List<_Quote> _customQuotes = [];

  late SharedPreferences _prefs;
  late AnimationController _breathController;
  late Animation<double> _breathAnim;

  List<_Quote> get _allQuotes => [..._builtInQuotes, ..._customQuotes];

  List<_Quote> get _filteredQuotes {
    if (_selectedCategory == 'all') return _allQuotes;
    return _allQuotes.where((q) => q.category == _selectedCategory).toList();
  }

  _Quote get _currentQuote {
    final filtered = _filteredQuotes;
    if (filtered.isEmpty) return const _Quote('Add your first quote!', 'You', 'all');
    return filtered[_currentIndex % filtered.length];
  }

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
    final themeIdx = _prefs.getInt('quote_theme_index') ?? 0;
    final favs = _prefs.getStringList('quote_favorites') ?? [];
    final customRaw = _prefs.getStringList('quote_custom') ?? [];
    final idx = _prefs.getInt('quote_current_index') ?? 0;

    _favoriteIndices = favs.map((s) => int.tryParse(s) ?? 0).toList();
    _customQuotes = customRaw.map((s) {
      final parts = s.split('|||');
      return _Quote(
        parts.isNotEmpty ? parts[0] : '',
        parts.length > 1 ? parts[1] : 'Unknown',
        parts.length > 2 ? parts[2] : 'motivation',
      );
    }).toList();

    setState(() {
      _themeIndex = themeIdx;
      _currentIndex = idx;
    });

    _updateHomeWidget();
  }

  void _updateHomeWidget() {
    final q = _currentQuote;
    HomeWidgetService.updateQuote(q.text, q.author, category: q.category);
  }

  Future<void> _saveFavorites() async {
    await _prefs.setStringList(
      'quote_favorites',
      _favoriteIndices.map((i) => i.toString()).toList(),
    );
  }

  Future<void> _saveCustomQuotes() async {
    await _prefs.setStringList(
      'quote_custom',
      _customQuotes.map((q) => '${q.text}|||${q.author}|||${q.category}').toList(),
    );
  }

  void _nextQuote() {
    final len = _filteredQuotes.length;
    if (len == 0) return;
    setState(() => _currentIndex = (_currentIndex + 1) % len);
    _prefs.setInt('quote_current_index', _currentIndex);
    _updateHomeWidget();
    HapticFeedback.lightImpact();
  }

  void _prevQuote() {
    final len = _filteredQuotes.length;
    if (len == 0) return;
    setState(() => _currentIndex = (_currentIndex - 1 + len) % len);
    _prefs.setInt('quote_current_index', _currentIndex);
    _updateHomeWidget();
    HapticFeedback.lightImpact();
  }

  void _randomQuote() {
    final len = _filteredQuotes.length;
    if (len <= 1) return;
    int newIdx;
    do {
      newIdx = Random().nextInt(len);
    } while (newIdx == _currentIndex && len > 1);
    setState(() => _currentIndex = newIdx);
    _prefs.setInt('quote_current_index', _currentIndex);
    _updateHomeWidget();
    HapticFeedback.mediumImpact();
  }

  void _toggleFavorite() {
    final idx = _allQuotes.indexOf(_currentQuote);
    setState(() {
      if (_favoriteIndices.contains(idx)) {
        _favoriteIndices.remove(idx);
      } else {
        _favoriteIndices.add(idx);
      }
    });
    _saveFavorites();
  }

  bool get _isCurrentFavorite {
    final idx = _allQuotes.indexOf(_currentQuote);
    return _favoriteIndices.contains(idx);
  }

  void _copyQuote() {
    final q = _currentQuote;
    Clipboard.setData(ClipboardData(text: '"${q.text}" — ${q.author}'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Quote copied! 📋'),
        backgroundColor: _theme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _setTheme(int index) {
    setState(() => _themeIndex = index);
    _prefs.setInt('quote_theme_index', index);
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
                  child: _buildCategoryChips(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildQuoteCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _buildControls(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: _buildCollectionPreview(),
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
    final q = _currentQuote;

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

            // Big quote mark decoration
            Positioned(
              left: 24,
              top: 55,
              child: Text(
                '\u201C',
                style: TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  color: _theme.primary.withValues(alpha: 0.08),
                  height: 0.8,
                ),
              ),
            ),

            // Centered quote preview
            Center(
              child: AnimatedBuilder(
                animation: _breathAnim,
                builder: (context, child) {
                  return Container(
                    width: 220,
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
                        Icon(
                          Icons.format_quote_rounded,
                          size: 28,
                          color: _theme.accent.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.text.length > 60
                              ? '${q.text.substring(0, 60)}…'
                              : q.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            color: _theme.textColor,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Divider(
                          color: _theme.primary.withValues(alpha: 0.12),
                          indent: 30,
                          endIndent: 30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '— ${q.author}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _theme.textColor.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
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
    final rng = Random(99);
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
    for (int i = 0; i < 12; i++) {
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
                  'Daily Quote',
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
                      '4.7',
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
            'A curated collection of motivational, mindful, and creative quotes. Start each day with a dose of inspiration. Add your own favorites too.',
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
            children: ['#quotes', '#motivation', '#daily', '#inspiration']
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
                value: '15.2k',
                label: 'downloads',
                badgeColor: const Color(0xFFFFF0DC),
                iconColor: _theme.primary,
              ),
              const SizedBox(width: 12),
              _statBadge(
                icon: Icons.format_quote_rounded,
                value: '${_allQuotes.length}',
                label: 'quotes',
                badgeColor: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF74B88A),
              ),
              const SizedBox(width: 12),
              _statBadge(
                icon: Icons.rate_review_rounded,
                value: '3.1k',
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

  // ────────── Category Chips ──────────

  Widget _buildCategoryChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_rounded,
                size: 18, color: _theme.textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              'Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final isSelected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    _currentIndex = 0;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _theme.primary.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: _theme.primary, width: 1.5)
                        : Border.all(
                            color: _theme.primary.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    cat[0].toUpperCase() + cat.substring(1),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? _theme.accent
                          : _theme.textColor.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ────────── Quote Card (main display) ──────────

  Widget _buildQuoteCard() {
    final q = _currentQuote;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100) {
            _nextQuote();
          } else if (details.primaryVelocity! > 100) {
            _prevQuote();
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _theme.cardColor,
              _theme.secondary.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _theme.primary.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: _theme.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Big opening quote mark
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '\u201C',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: _theme.primary.withValues(alpha: 0.2),
                  height: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Quote text
            Text(
              q.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: _theme.textColor,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 20),

            // Author divider
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: _theme.primary.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    q.author,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _theme.accent,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: _theme.primary.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                q.category[0].toUpperCase() + q.category.substring(1),
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
    );
  }

  // ────────── Controls ──────────

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _controlBtn(
          icon: Icons.chevron_left_rounded,
          onTap: _prevQuote,
          tooltip: 'Previous',
        ),
        const SizedBox(width: 12),
        _controlBtn(
          icon: Icons.shuffle_rounded,
          onTap: _randomQuote,
          tooltip: 'Random',
          isPrimary: true,
        ),
        const SizedBox(width: 12),
        _controlBtn(
          icon: Icons.chevron_right_rounded,
          onTap: _nextQuote,
          tooltip: 'Next',
        ),
        const SizedBox(width: 20),
        // Divider
        Container(
          width: 1,
          height: 28,
          color: _theme.primary.withValues(alpha: 0.15),
        ),
        const SizedBox(width: 20),
        _controlBtn(
          icon: _isCurrentFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          onTap: _toggleFavorite,
          tooltip: 'Favorite',
          color: _isCurrentFavorite ? Colors.redAccent : null,
        ),
        const SizedBox(width: 12),
        _controlBtn(
          icon: Icons.copy_rounded,
          onTap: _copyQuote,
          tooltip: 'Copy',
        ),
        const SizedBox(width: 12),
        _controlBtn(
          icon: Icons.add_rounded,
          onTap: _showAddQuoteSheet,
          tooltip: 'Add',
        ),
      ],
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isPrimary = false,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isPrimary ? 48 : 40,
        height: isPrimary ? 48 : 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPrimary
              ? _theme.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.6),
          border: isPrimary
              ? Border.all(color: _theme.primary, width: 1.5)
              : Border.all(
                  color: _theme.primary.withValues(alpha: 0.1)),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: _theme.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Icon(icon,
            size: isPrimary ? 24 : 20,
            color: color ?? (isPrimary ? _theme.accent : _theme.textColor.withValues(alpha: 0.5))),
      ),
    );
  }

  // ────────── Collection Preview (mini cards) ──────────

  Widget _buildCollectionPreview() {
    final filtered = _filteredQuotes;
    final previewCount = filtered.length.clamp(0, 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.collections_bookmark_rounded,
                size: 18, color: _theme.textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              'Collection',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              ),
            ),
            const Spacer(),
            Text(
              '${filtered.length} quotes',
              style: TextStyle(
                fontSize: 12,
                color: _theme.textColor.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Mini quote cards
        ...List.generate(previewCount, (i) {
          final q = filtered[i];
          final isActive = i == (_currentIndex % filtered.length);
          final accentColors = [
            _theme.primary,
            const Color(0xFFD4728C),
            const Color(0xFF74B88A),
            const Color(0xFF9B8EC4),
          ];

          return GestureDetector(
            onTap: () {
              setState(() => _currentIndex = i);
              _prefs.setInt('quote_current_index', i);
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Vertical accent line
                    Container(
                      width: 2.5,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColors[i % accentColors.length]
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 14),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? _theme.primary.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: isActive
                              ? Border.all(
                                  color:
                                      _theme.primary.withValues(alpha: 0.3),
                                  width: 1.5)
                              : Border.all(
                                  color:
                                      _theme.primary.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.format_quote_rounded,
                              size: 16,
                              color: isActive
                                  ? _theme.accent
                                  : _theme.textColor.withValues(alpha: 0.2),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                q.text.length > 45
                                    ? '${q.text.substring(0, 45)}…'
                                    : q.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontStyle: FontStyle.italic,
                                  color: isActive
                                      ? _theme.textColor
                                      : _theme.textColor
                                          .withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '— ${q.author.split(' ').last}',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    _theme.textColor.withValues(alpha: 0.3),
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
          );
        }),

        if (filtered.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                '+ ${filtered.length - 4} more quotes',
                style: TextStyle(
                  fontSize: 12,
                  color: _theme.textColor.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
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
          type: 'quote',
          title: 'Daily Quote',
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

  // ────────── Add Quote Sheet ──────────

  void _showAddQuoteSheet() {
    final textCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    String selectedCat = 'motivation';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
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
                'Add Your Quote',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _theme.textColor,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: textCtrl,
                autofocus: true,
                maxLines: 3,
                style: TextStyle(color: _theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Enter the quote…',
                  hintStyle: TextStyle(
                      color: _theme.textColor.withValues(alpha: 0.35)),
                  filled: true,
                  fillColor: _theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: authorCtrl,
                style: TextStyle(color: _theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Author name',
                  hintStyle: TextStyle(
                      color: _theme.textColor.withValues(alpha: 0.35)),
                  filled: true,
                  fillColor: _theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Category selector
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _categories
                      .where((c) => c != 'all')
                      .map((cat) {
                    final isSel = cat == selectedCat;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedCat = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel
                              ? _theme.primary.withValues(alpha: 0.18)
                              : _theme.cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: isSel
                              ? Border.all(
                                  color: _theme.primary, width: 1.5)
                              : Border.all(
                                  color: _theme.primary
                                      .withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          cat[0].toUpperCase() + cat.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSel
                                ? _theme.accent
                                : _theme.textColor
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                    if (textCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        _customQuotes.add(_Quote(
                          textCtrl.text.trim(),
                          authorCtrl.text.trim().isNotEmpty
                              ? authorCtrl.text.trim()
                              : 'Unknown',
                          selectedCat,
                        ));
                      });
                      _saveCustomQuotes();
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Quote',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
