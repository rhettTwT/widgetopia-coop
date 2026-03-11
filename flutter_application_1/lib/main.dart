import 'package:flutter/material.dart';
import 'package:widgetopia/screens/home_screen.dart';
import 'package:widgetopia/screens/search_screen.dart';
import 'package:widgetopia/screens/saved_widget_screen.dart';
import 'package:widgetopia/screens/profile_screen.dart';

void main() {
  runApp(const WidgetopiaApp());
}

class WidgetopiaApp extends StatelessWidget {
  const WidgetopiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Widgetopia',
      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFDFA8),
          surface: const Color(0xFFFFF4D6),
        ),

        scaffoldBackgroundColor: const Color(0xFFFFF4D6),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFDFA8),
          foregroundColor: Color(0xFF4A3B2A),
          elevation: 0,
          centerTitle: true,
        ),

        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A3B2A),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A3B2A),
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Color(0xFF4A3B2A),
          ),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    SearchScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];

  static const _navBg = Color(0xFFFFF8EE);
  static const _activeColor = Color(0xFF6B4F3A);
  static const _inactiveColor = Color(0xFFB0A090);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _navBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.explore_rounded,
                  activeIcon: Icons.explore,
                  label: "Discover",
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                  activeColor: _activeColor,
                  inactiveColor: _inactiveColor,
                ),
                _NavItem(
                  icon: Icons.search_rounded,
                  activeIcon: Icons.search,
                  label: "Search",
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                  activeColor: _activeColor,
                  inactiveColor: _inactiveColor,
                ),
                _NavItem(
                  icon: Icons.bookmark_border_rounded,
                  activeIcon: Icons.bookmark_rounded,
                  label: "Saved",
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                  activeColor: _activeColor,
                  inactiveColor: _inactiveColor,
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: "Profile",
                  selected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                  activeColor: _activeColor,
                  inactiveColor: _inactiveColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


