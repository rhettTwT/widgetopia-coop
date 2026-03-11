import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:widgetopia/data/widget_data.dart';
import 'package:widgetopia/models/widget_item.dart';
import 'package:widgetopia/widgets/widget_card.dart';
import 'package:widgetopia/screens/widget_detail_screen.dart';
import 'package:widgetopia/screens/habit_tracker_screen.dart';
import 'package:widgetopia/screens/timer_screen.dart';
import 'package:widgetopia/screens/calendar_screen.dart';
import 'package:widgetopia/screens/quote_screen.dart';
import 'package:widgetopia/screens/notepad_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = "";

  static const _bg = Color(0xFFFFF8EE);
  static const _textColor = Color(0xFF4A3728);
  static const _hintColor = Color(0xFFB0A090);
  static const _accent = Color(0xFF6B4F3A);

  // Recent/popular search suggestions
  final _suggestions = [
    "Timer",
    "Calendar",
    "Habit",
    "Quote",
    "Notepad",
    "Cozy",
    "Minimal",
  ];

  // Category quick-access chips
  final _categories = [
    _Category("🎯", "Productivity", const Color(0xFF4FC3F7)),
    _Category("🎨", "Aesthetic", const Color(0xFFE040FB)),
    _Category("📝", "Notes", const Color(0xFFFFB347)),
    _Category("⏱️", "Timers", const Color(0xFFD4A574)),
    _Category("💬", "Quotes", const Color(0xFFFF6B6B)),
    _Category("📅", "Planners", const Color(0xFF4ECDC4)),
  ];

  List<WidgetItem> get _results {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return widgetFeed.where((w) {
      return w.title.toLowerCase().contains(q) ||
          w.subtitle.toLowerCase().contains(q) ||
          w.tag.toLowerCase().contains(q) ||
          w.type.toLowerCase().contains(q) ||
          w.creator.toLowerCase().contains(q);
    }).toList();
  }

  void _search(String text) {
    setState(() => _query = text);
  }

  void _searchTag(String tag) {
    _controller.text = tag;
    _search(tag);
    _focusNode.unfocus();
  }

  void _navigateToWidget(WidgetItem item) {
    Widget screen;
    switch (item.type) {
      case "pomodoro":
        screen = const TimerScreen();
        break;
      case "habit":
        screen = const HabitTrackerScreen();
        break;
      case "calendar":
        screen = const CalendarScreen();
        break;
      case "quote":
        screen = const QuoteScreen();
        break;
      case "notepad":
        screen = const NotepadDetailScreen();
        break;
      default:
        screen = WidgetDetailScreen(
          title: item.title,
          tag: item.tag,
          type: item.type,
        );
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (c, a, s) => screen,
        transitionsBuilder: (c, animation, s, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.isNotEmpty;
    final results = _results;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(color: _bg),
          // Glow blobs
          Positioned(
            top: -60,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD6A5).withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE5EC).withValues(alpha: 0.45),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(color: Colors.transparent),
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    "Search",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Search Bar ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _search,
                      style: const TextStyle(
                        fontSize: 16,
                        color: _textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search widgets, packs, creators...",
                        hintStyle: TextStyle(
                          color: _hintColor,
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _hintColor,
                          size: 22,
                        ),
                        suffixIcon: hasQuery
                            ? GestureDetector(
                                onTap: () {
                                  _controller.clear();
                                  _search("");
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: _hintColor,
                                  size: 20,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Results or Browse Content ───
                Expanded(
                  child: hasQuery
                      ? _buildResults(results)
                      : _buildBrowse(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search Results ───
  Widget _buildResults(List<WidgetItem> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: _hintColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              "No widgets found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try a different search term",
              style: TextStyle(
                fontSize: 14,
                color: _hintColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final item = results[i];
        return WidgetCard(
          item: item,
          onTap: () => _navigateToWidget(item),
        );
      },
    );
  }

  // ─── Browse (when no query) ───
  Widget _buildBrowse() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        // Categories
        const Text(
          "Browse Categories",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: _categories.map((cat) {
            return GestureDetector(
              onTap: () => _searchTag(cat.label),
              child: Container(
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: cat.color.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(cat.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cat.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 28),

        // Popular searches
        const Text(
          "Popular Searches",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _suggestions.map((s) {
            return GestureDetector(
              onTap: () => _searchTag(s),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 16,
                      color: _accent.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 28),

        // All widgets preview
        const Text(
          "All Widgets",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemCount: widgetFeed.length,
          itemBuilder: (context, i) {
            final item = widgetFeed[i];
            return WidgetCard(
              item: item,
              onTap: () => _navigateToWidget(item),
            );
          },
        ),
      ],
    );
  }
}

class _Category {
  final String emoji;
  final String label;
  final Color color;
  const _Category(this.emoji, this.label, this.color);
}
