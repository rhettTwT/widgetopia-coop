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

class _WidgetDetailScreenState extends State<WidgetDetailScreen> {
  bool _isSaved = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkSaved();
    SavedWidgetsService.changeNotifier.addListener(_checkSaved);
  }

  @override
  void dispose() {
    SavedWidgetsService.changeNotifier.removeListener(_checkSaved);
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
        const SnackBar(
          content: Text('Widget removed 🗑️'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final model = SavedWidgetModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: widget.type,
        title: widget.title,
        config: {},
        createdAt: DateTime.now(),
      );
      await SavedWidgetsService.save(model);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Widget saved 💾'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
        return Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black12),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.widgets_outlined, color: Colors.black38, size: 48),
                SizedBox(height: 16),
                Text('Widget Preview',
                    style: TextStyle(color: Colors.black54, fontSize: 16)),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildMetric(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildStyleSquare(String label, Color color,
      {Color textColor = Colors.black87}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// TOP NAVIGATION BAR
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share_outlined,
                            color: Colors.black87),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          _isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: _isSaved
                              ? const Color(0xFF6B4F3A)
                              : Colors.black87,
                        ),
                        onPressed: _toggleSave,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// MAIN SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HERO IMAGE
                    Container(
                      height: 260,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.0, 0.4, 0.75, 1.0],
                          colors: [
                            Color(0xFFFFF8F0), // cream
                            Color(0xFFFFE8CC), // warm peach
                            Color(0xFFFFD6A8), // caramel
                            Color(0xFFF5C28A), // golden
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFD4A574),
                            blurRadius: 36,
                            offset: Offset(0, 14),
                            spreadRadius: -8,
                          ),
                          BoxShadow(
                            color: Color(0xFFC08552),
                            blurRadius: 60,
                            offset: Offset(0, 24),
                            spreadRadius: -15,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          children: [
                            // Inner highlight (top light)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 80,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.25),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Radial glow behind icon
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.5,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.25),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Featured badge
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC08552),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFC08552)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Featured',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),

                            // Center icon with glow
                            Center(
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.35),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD4A574)
                                          .withValues(alpha: 0.2),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.widgets_rounded,
                                  size: 48,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// TITLE AND TAG
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Perfect for calm aesthetic 🌸',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 14),
                              ),
                              const Spacer(),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.tag,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// METRICS ROW
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetric('12.4k', 'Downloads'),
                          _buildMetric('8.2k', 'Saves'),
                          _buildMetric('4.9', 'Rating'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    /// STYLE VARIATIONS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                'Style Variations',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.tune,
                                  size: 18, color: Colors.black54),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: [
                              _buildStyleSquare('Original',
                                  const Color(0xFFFFF7ED),
                                  textColor: const Color(0xFFEA580C)),
                              _buildStyleSquare('Dark',
                                  const Color(0xFF1F2933),
                                  textColor: Colors.white),
                              _buildStyleSquare('Pastel',
                                  const Color(0xFFFCE4EC),
                                  textColor: const Color(0xFFD81B60)),
                              _buildStyleSquare('Neon',
                                  const Color(0xFFF0FDF4),
                                  textColor: const Color(0xFF16A34A)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    /// PREVIEW SECTION
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preview',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 16),
                          Center(child: _buildPreview()),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    /// ABOUT SECTION
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'About this widget',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'This widget brings a perfect balance of functionality and aesthetics to your home screen. Customize it to match your vibe and make your phone truly yours.',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    /// YOU MIGHT ALSO LIKE
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'You might also like',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: 4,
                        separatorBuilder: (ctx, idx) =>
                            const SizedBox(width: 16),
                        itemBuilder: (_, i) {
                          final item =
                              widgetFeed[(i + 3) % widgetFeed.length];
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

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: _checking
            ? const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator()))
            : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: _isSaved
                      ? const Color(0xFFE8DDD4)
                      : const Color(0xFF111827),
                  foregroundColor:
                      _isSaved ? const Color(0xFF6B4F3A) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _toggleSave,
                icon: Icon(
                  _isSaved
                      ? Icons.bookmark_remove_outlined
                      : Icons.add,
                  size: 20,
                ),
                label: Text(
                  _isSaved ? '✓ Saved — Tap to remove' : 'Add to Home Screen',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
      ),
    );
  }
}
