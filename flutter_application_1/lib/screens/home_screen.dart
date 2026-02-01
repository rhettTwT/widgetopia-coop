import 'package:flutter/material.dart';
import 'package:widgetopia/screens/widget_detail_screen.dart';
import 'package:widgetopia/widgets/ambient_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Discover",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E241C),
                    ),
                  ),
                  Icon(Icons.search, color: Color(0xFF2E241C)),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _Chip(label: "For You", selected: true),
                    _Chip(label: "Aesthetic"),
                    _Chip(label: "Fandom"),
                    _Chip(label: "Meme"),
                    _Chip(label: "Minimal"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Trending collections
              const _SectionHeader(title: "Trending Collections"),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: const [
                  CollectionCard(title: "Wu Pack", count: "12 widgets", color: Color(0xFFE6F4F1)),
                  CollectionCard(title: "Shang Pack", count: "18 widgets", color: Color(0xFFF8EFE6)),
                  CollectionCard(title: "Clan Pack", count: "15 widgets", color: Color(0xFFEDEBEA)),
                  CollectionCard(title: "Cozy Pack", count: "20 widgets", color: Color(0xFFFDECEF)),
                ],
              ),

              const SizedBox(height: 28),

              // Featured
              const _SectionHeader(title: "Featured Today"),
              const SizedBox(height: 12),
              const FeaturedCard(),

              const SizedBox(height: 28),

              // For You Feed
              const _SectionHeader(title: "For You"),
              const SizedBox(height: 12),

              const FeedCard(title: "Minimal Focus Widget", tag: "productivity"),
              const FeedCard(title: "Cozy Night Quote Pack", tag: "cozy"),
              const FeedCard(title: "Study Timer Aesthetic", tag: "minimal"),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- CHIPS ----------------

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;

  const _Chip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF6B4F3A) : const Color(0xFFF1E8DD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF6B4F3A),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------- SECTION HEADER ----------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          " ",
          style: TextStyle(fontSize: 0),
        ),
      ],
    );
  }
}

// ---------------- COLLECTION CARD ----------------

class CollectionCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const CollectionCard({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(count, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ---------------- FEATURED CARD ----------------

class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF2F2F2F), Color(0xFF1A1A1A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(label: Text("Featured"), backgroundColor: Color(0xFFFFC857)),
          Spacer(),
          Text(
            "Cozy Study Timer",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text("Perfect for calm study sessions ☕", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

// ---------------- FEED CARD (Hero + Animation) ----------------

class FeedCard extends StatelessWidget {
  final String title;
  final String tag;

  const FeedCard({super.key, required this.title, required this.tag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) =>
                WidgetDetailScreen(title: title, tag: tag),
            transitionsBuilder: (_, animation, __, child) {
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
      },
      child: Hero(
        tag: title,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 170,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2933),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(label: Text(tag), backgroundColor: Colors.white24),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
