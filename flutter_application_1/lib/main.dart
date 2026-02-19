import 'package:flutter/material.dart';
import 'package:widgetopia/screens/home_screen.dart';
import 'package:widgetopia/screens/saved_screen.dart';
import 'package:widgetopia/screens/home_dashboard_screen.dart';

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
          background: const Color(0xFFFFF4D6),
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
  int index = 0;

  final pages = const [
    HomeScreen(),
    HomeDashboardScreen(), // 👈 this is now your real home screen
    ExploreScreen(),
    TrendingScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        backgroundColor: const Color(0xFFFFF4D6),
        indicatorColor: const Color(0xFFE6F4F1),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.search), label: "Explore"),
          NavigationDestination(icon: Icon(Icons.trending_up), label: "Trending"),
          NavigationDestination(icon: Icon(Icons.bookmark), label: "Saved"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

/// TEMP PLACEHOLDERS (we'll design later)

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Explore")),
    );
  }
}

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Trending")),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Profile")),
    );
  }
}
