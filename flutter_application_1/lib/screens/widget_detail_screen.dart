import 'package:flutter/material.dart';
import 'package:widgetopia/widgets/quote_widget_preview.dart';
import 'package:widgetopia/widgets/pomodoro_widget_preview.dart';
import 'package:widgetopia/widgets/notepad_widget_preview.dart';
import 'package:widgetopia/widgets/habit_widget_preview.dart';
import 'package:widgetopia/widgets/mood_widget_preview.dart';
import 'package:widgetopia/models/saved_widget_model.dart';
import 'package:widgetopia/services/saved_widgets_service.dart';

class WidgetDetailScreen extends StatelessWidget {
  final String title;
  final String tag;
  final String type;

  const WidgetDetailScreen({
    super.key,
    required this.title,
    required this.tag,
    required this.type,
  });

  Widget _buildPreview() {
    switch (type) {
      case "quote":
        return const QuoteWidgetPreview(
          quote: "Lets get this shit started",
          author: "Me",
        );
      case "pomodoro":
        return const PomodoroWidgetPreview();
      case "notepad":
        return const NotepadWidgetPreview(theme: '');
      case "habit":
        return const HabitWidgetPreview(interactive: true);
      case "mood":
        return const MoodWidgetPreview(interactive: true);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER + HERO CARD
            Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      color: const Color(0xFF1F2933),
                    ),
                  ),
                ),

                Positioned(
                  top: 28,
                  left: 28,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                Positioned(
                  top: 28,
                  right: 28,
                  child: Row(
                    children: const [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.share),
                      ),
                      SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.favorite_border),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 24,
                  left: 32,
                  right: 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(
                        label: Text(tag),
                        backgroundColor: const Color(0xFFFFC857),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Perfect for your home screen ✨",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    /// PREVIEW CARD
                    Center(child: _buildPreview()),

                    const SizedBox(height: 28),

                    /// ABOUT
                    const Text(
                      "About this widget",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "This widget is designed to match your vibe and sit beautifully on your home screen. Customize it however you like.",
                      style: TextStyle(color: Colors.black54),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            /// FIXED BOTTOM BUTTON
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EE),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: const Color(0xFF6B4F3A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () async {
                  final widget = SavedWidgetModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: type,
                    title: title,
                    config: {},
                    createdAt: DateTime.now(),
                  );

                  await SavedWidgetsService.save(widget);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Widget saved 💾")),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text("Add to Home Screen"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
