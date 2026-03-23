import 'package:flutter/material.dart';
import 'package:widgetopia/screens/home_screen.dart';
import 'package:widgetopia/screens/search_screen.dart';
import 'package:widgetopia/screens/saved_widget_screen.dart';
import 'package:widgetopia/screens/profile_screen.dart';
import 'package:widgetopia/utils/theme_provider.dart';

import 'package:widgetopia/services/home_widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidgetService.initialize();
  final themeNotifier = await ThemeNotifier.load();
  runApp(WidgetopiaApp(themeNotifier: themeNotifier));
}

class WidgetopiaApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const WidgetopiaApp({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      notifier: themeNotifier,
      child: AnimatedBuilder(
        animation: themeNotifier,
        builder: (context, _) {
          final isDark = themeNotifier.isDark;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Widgetopia',
            theme: _buildTheme(false),
            darkTheme: _buildTheme(true),
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            home: const MainNavigation(),
          );
        },
      ),
    );
  }

  static ThemeData _buildTheme(bool isDark) {
    final c = isDark ? AppColors.dark : AppColors.light;
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFFDFA8),
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: c.scaffoldBg,
      ),
      scaffoldBackgroundColor: c.scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? c.surfaceBg : const Color(0xFFFFDFA8),
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: c.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: c.textPrimary,
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      // ─── Floating bottom nav ───
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: c.navBg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: c.isDark ? 0.3 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              if (!c.isDark)
                BoxShadow(
                  color: const Color(0xFFD4A574).withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.explore_rounded,
                activeIcon: Icons.explore,
                label: "Discover",
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
                activeColor: c.accent,
                inactiveColor: c.textMuted,
              ),
              _NavItem(
                icon: Icons.search_rounded,
                activeIcon: Icons.search,
                label: "Search",
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
                activeColor: c.accent,
                inactiveColor: c.textMuted,
              ),
              _NavItem(
                icon: Icons.bookmark_border_rounded,
                activeIcon: Icons.bookmark_rounded,
                label: "Saved",
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
                activeColor: c.accent,
                inactiveColor: c.textMuted,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: "Profile",
                selected: _index == 3,
                onTap: () => setState(() => _index = 3),
                activeColor: c.accent,
                inactiveColor: c.textMuted,
              ),
            ],
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
              ? activeColor.withValues(alpha: 0.12)
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


