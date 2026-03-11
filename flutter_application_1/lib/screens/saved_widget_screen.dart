import 'package:flutter/material.dart';
import 'package:widgetopia/models/saved_widget_model.dart';
import 'package:widgetopia/services/saved_widgets_service.dart';
import 'package:widgetopia/widgets/quote_widget_preview.dart';
import 'package:widgetopia/widgets/pomodoro_widget_preview.dart';
import 'package:widgetopia/widgets/notepad_widget_preview.dart';
import 'package:widgetopia/widgets/habit_widget_preview.dart';
import 'package:widgetopia/screens/widget_detail_screen.dart';
import 'package:widgetopia/screens/habit_tracker_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  late Future<List<SavedWidgetModel>> _savedWidgets;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _savedWidgets = SavedWidgetsService.getAll();
  }

  Widget _buildPreview(SavedWidgetModel item) {
    switch (item.type) {
      case "quote":
        return const QuoteWidgetPreview(
          quote: "Saved Quote",
          author: "You",
        );
      case "pomodoro":
        return const PomodoroWidgetPreview();
      case "notepad":
        return const NotepadWidgetPreview(theme: '');
      case "habit":
        return const HabitWidgetPreview(interactive: true);
      default:
        return Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFF1E8DD),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text("Widget Preview",
                style: TextStyle(color: Color(0xFF8C776A))),
          ),
        );
    }
  }

  void _openWidget(SavedWidgetModel item) {
    if (item.type == "habit") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HabitTrackerScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WidgetDetailScreen(
            title: item.title,
            tag: item.type,
            type: item.type,
          ),
        ),
      );
    }
  }

  Future<void> _deleteWidget(SavedWidgetModel item) async {
    await SavedWidgetsService.delete(item.id);
    setState(() => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Saved Widgets",
          style: TextStyle(
            color: Color(0xFF4A3B2A),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<SavedWidgetModel>>(
        future: _savedWidgets,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A574)),
            );
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.widgets_outlined,
                      size: 64,
                      color: const Color(0xFF8C776A).withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    "No saved widgets yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8C776A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Save widgets from the explore page\nto see them here",
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF8C776A).withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context2, index2) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final item = items[index];

              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 28),
                ),
                onDismissed: (_) => _deleteWidget(item),
                child: GestureDetector(
                  onTap: () => _openWidget(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Widget type label
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _typeColor(item.type)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _typeColor(item.type),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A3728),
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: const Color(0xFF8C776A)
                                    .withValues(alpha: 0.5),
                                size: 20),
                          ],
                        ),
                      ),
                      _buildPreview(item),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case "pomodoro":
        return const Color(0xFFD4A574);
      case "quote":
        return const Color(0xFFFF6B6B);
      case "calendar":
        return const Color(0xFF4ECDC4);
      case "notepad":
        return const Color(0xFFFFB347);
      case "habit":
        return const Color(0xFF7B61FF);
      default:
        return const Color(0xFF8C776A);
    }
  }
}
