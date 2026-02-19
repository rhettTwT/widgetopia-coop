import 'package:flutter/material.dart';
import '../models/saved_widget_model.dart';
import '../services/saved_widgets_service.dart';
import '../widgets/quote_widget_preview.dart';
import '../widgets/pomodoro_widget_preview.dart';
import '../widgets/notepad_widget_preview.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  List<SavedWidgetModel> widgets = [];

  @override
  void initState() {
    super.initState();
    _loadWidgets();
  }

  Future<void> _loadWidgets() async {
    final data = await SavedWidgetsService.getAll();
    setState(() => widgets = data);
  }

  Widget _buildPreview(SavedWidgetModel item) {
    switch (item.type) {
      case "quote":
        return QuoteWidgetPreview(
          quote: item.config["quote"] ?? "Stay focused",
          author: item.config["author"] ?? "You",
        );
      case "pomodoro":
        return const PomodoroWidgetPreview();
      case "notepad":
        return const NotepadWidgetPreview();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Home Widgets")),
      body: widgets.isEmpty
          ? const Center(child: Text("No widgets added yet"))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widgets.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                setState(() {
                  final item = widgets.removeAt(oldIndex);
                  widgets.insert(newIndex, item);
                });
                SavedWidgetsService.saveOrder(widgets);
              },
              itemBuilder: (context, index) {
                final item = widgets[index];

                return Container(
                  key: ValueKey(item.id),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Stack(
                    children: [
                      _buildPreview(item),

                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () async {
                            await SavedWidgetsService.delete(item.id);
                            _loadWidgets();
                          },
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
