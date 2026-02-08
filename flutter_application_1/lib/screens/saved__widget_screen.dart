import 'package:flutter/material.dart';
import 'package:widgetopia/models/saved_widget_model.dart';
import 'package:widgetopia/services/saved_widgets_service.dart';
import 'package:widgetopia/widgets/quote_widget_preview.dart';
import 'package:widgetopia/widgets/pomodoro_widget_preview.dart';
import 'package:widgetopia/widgets/notepad_widget_preview.dart';
import 'package:widgetopia/screens/widget_detail_screen.dart';

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
        return const NotepadWidgetPreview(theme: '',);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saved Widgets")),
      body: FutureBuilder<List<SavedWidgetModel>>(
        future: _savedWidgets,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return const Center(child: Text("No saved widgets yet"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final item = items[index];

              return GestureDetector(
                onTap: () {
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
                },
                child: _buildPreview(item),
              );
            },
          );
        },
      ),
    );
  }
}
