import 'package:flutter/material.dart';

class NotepadWidgetPreview extends StatelessWidget {
  final String title;
  final List<String> previewItems;
  final String theme; // original, dark, pastel, neon

  const NotepadWidgetPreview({
    super.key,
    this.title = "My Notes",
    this.previewItems = const [
      "Buy groceries",
      "Finish assignment",
      "Call mom",
    ],
    this.theme = "original",
  });

  Color get _bg {
    switch (theme) {
      case "dark":
        return const Color(0xFF1F2933);
      case "pastel":
        return const Color(0xFFFFE4EC);
      case "neon":
        return const Color(0xFF2B0015);
      default:
        return const Color(0xFFFFF4EC);
    }
  }

  Color get _fg {
    return theme == "dark" || theme == "neon"
        ? Colors.white
        : const Color(0xFF2E241C);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _fg,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...previewItems.take(3).map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 18, color: _fg.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(color: _fg),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
