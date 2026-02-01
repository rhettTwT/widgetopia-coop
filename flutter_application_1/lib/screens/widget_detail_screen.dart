import 'package:flutter/material.dart';
import 'package:widgetopia/widgets/quote_widget_preview.dart';
import 'package:widgetopia/widgets/pomodoro_widget_preview.dart';
import 'package:widgetopia/widgets/notepad_widget_preview.dart';
import 'package:widgetopia/models/saved_widget_model.dart';
import 'package:widgetopia/services/saved_widgets_service.dart';



class WidgetDetailScreen extends StatelessWidget {
  final String title;
  final String tag;

  const WidgetDetailScreen({
    super.key,
    required this.title,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              /// HERO CARD
              Hero(
                tag: title,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 260,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2933),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Chip(
                          label: Text(tag),
                          backgroundColor: Colors.white24,
                        ),
                        const Spacer(),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Live widget preview",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// CONTENT FADE + SLIDE IN
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      /// REAL PREVIEWS
                      QuoteWidgetPreview(quote: 'Im tired', author: 'fuck you',),
                      const SizedBox(height: 20),
                      PomodoroWidgetPreview(),
                      NotepadWidgetPreview(),

                      const SizedBox(height: 28),

                      /// PRIMARY ACTION
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          backgroundColor: const Color(0xFF6B4F3A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () async {
                          final widget = SavedWidgetModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            type: "quote",
                            title: title,
                            config: {
                              "quote": "Lets get this shit started",
                              "author": "You",
                            },
                            createdAt: DateTime.now(),
                          );

                          await SavedWidgetsService.save(widget);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Widget saved 💾")),
                          );
                        },
                        child: const Text("Add to Home Screen"),
                      ),


                      const SizedBox(height: 12),

                      /// BACK BUTTON
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Back"),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
