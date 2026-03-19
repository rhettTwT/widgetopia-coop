import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide color palette that adapts to light/dark mode.
class AppColors {
  final bool isDark;

  const AppColors._({required this.isDark});

  static const light = AppColors._(isDark: false);
  static const dark = AppColors._(isDark: true);

  // ─── Backgrounds ───
  Color get scaffoldBg => isDark ? const Color(0xFF121212) : const Color(0xFFFFF4D6);
  Color get surfaceBg => isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFF8EE);
  Color get cardBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get navBg => isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFF8EE);

  // ─── Text ───
  Color get textPrimary => isDark ? const Color(0xFFEDE0D4) : const Color(0xFF4A3728);
  Color get textSecondary => isDark ? const Color(0xFF9E8E80) : const Color(0xFF8C776A);
  Color get textMuted => isDark ? const Color(0xFF6B5E52) : const Color(0xFFB0A090);

  // ─── Accent / Primary ───
  Color get primary => isDark ? const Color(0xFFE0B88A) : const Color(0xFFD4A574);
  Color get accent => isDark ? const Color(0xFFD49B6A) : const Color(0xFF6B4F3A);

  // ─── Misc ───
  Color get chipBg => isDark ? const Color(0xFF2A2420) : const Color(0xFFF1E8DD);
  Color get chipSelectedBg => isDark ? const Color(0xFFD49B6A) : const Color(0xFF6B4F3A);
  Color get divider => isDark
      ? const Color(0xFF2E2E2E)
      : const Color(0xFFE8DFD2).withAlpha(153);
  Color get shadow => isDark ? Colors.black54 : Colors.black12;
  Color get glowA => isDark
      ? const Color(0xFFFFD6A5).withAlpha(30)
      : const Color(0xFFFFD6A5).withAlpha(115);
  Color get glowB => isDark
      ? const Color(0xFFFFB4A2).withAlpha(25)
      : const Color(0xFFFFB4A2).withAlpha(100);
  Color get glowC => isDark
      ? const Color(0xFFFFE5EC).withAlpha(25)
      : const Color(0xFFFFE5EC).withAlpha(115);

  // Feed card background
  Color get feedCardBg => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF0DC);
  Color get feedCardBgAlt => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF8EE);

  // Header & toolbar
  Color get headerBg => isDark ? const Color(0xFF1A1612) : const Color(0xFFFFF4D6);
  Color get quickAccessBg => isDark ? const Color(0xFF2A2420) : Colors.white;
  Color get sectionHeaderColor => isDark ? const Color(0xFFBFA98A) : const Color(0xFF8C6E54);

  // Collection card overlay
  Color collectionCard(Color base) =>
      isDark ? Color.lerp(base, Colors.black, 0.6)! : base;
}

/// An InheritedNotifier that propagates [ThemeNotifier] down the tree.
class ThemeProvider extends InheritedNotifier<ThemeNotifier> {
  const ThemeProvider({
    super.key,
    required ThemeNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ThemeNotifier of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeProvider>()!
        .notifier!;
  }

  static AppColors colorsOf(BuildContext context) {
    return of(context).colors;
  }
}

/// ValueNotifier that holds the current dark-mode state and persists it.
class ThemeNotifier extends ChangeNotifier {
  bool _isDark;
  ThemeNotifier({bool isDark = false}) : _isDark = isDark;

  bool get isDark => _isDark;
  AppColors get colors => _isDark ? AppColors.dark : AppColors.light;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
    _persist();
  }

  void setDark(bool value) {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDark);
  }

  static Future<ThemeNotifier> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeNotifier(isDark: prefs.getBool('dark_mode') ?? false);
  }
}
