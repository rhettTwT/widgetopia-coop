import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:widgetopia/data/widget_data.dart';
import 'package:widgetopia/models/widget_item.dart';
import 'package:widgetopia/widgets/widget_card.dart';
import 'package:widgetopia/screens/widget_detail_screen.dart';
import 'package:widgetopia/screens/habit_tracker_screen.dart';
import 'package:widgetopia/screens/timer_screen.dart';
import 'package:widgetopia/screens/calendar_screen.dart';
import 'package:widgetopia/screens/quote_screen.dart';
import 'package:widgetopia/screens/notepad_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedFilter = "All";

  final _filters = ["All", "Cozy", "Minimal", "Personal", "Inspire"];

  List<WidgetItem> get _filtered {
    if (_selectedFilter == "All") return widgetFeed;
    return widgetFeed
        .where(
            (w) => w.tag.toUpperCase() == _selectedFilter.toUpperCase())
        .toList();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Container(color: const Color(0xFFFFF8EE)),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD6A5).withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE5EC).withValues(alpha: 0.5),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(color: Colors.transparent),
          ),

          // Content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        const Text(
                          "🧩",
                          style: TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "All Widgets",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E241C),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search,
                                color: Color(0xFF4A3B2A), size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filters
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _filters.map((f) {
                          final selected = _selectedFilter == f;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedFilter = f),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF6B4F3A)
                                    : Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF6B4F3A)
                                              .withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF6B4F3A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                // Widget Grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _filtered[index];
                        return WidgetCard(
                          item: item,
                          onTap: () => _navigateToWidget(item),
                        );
                      },
                      childCount: _filtered.length,
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
