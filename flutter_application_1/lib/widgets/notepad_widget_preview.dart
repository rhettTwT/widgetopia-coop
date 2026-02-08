import 'package:flutter/material.dart';

class NotepadWidgetPreview extends StatelessWidget {
  final String title;
  final List<String> previewItems;
  final bool dark;

  const NotepadWidgetPreview({
    super.key,
    this.title = "My Notes",
    this.previewItems = const [
      "Buy groceries",
      "Finish assignment",
      "Call mom",
    ],
    this.dark = false, required String theme,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF1F2933) : const Color(0xFFFFF4EC);
    final fg = dark ? Colors.white : const Color(0xFF2E241C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
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
          Text(title,
              style: TextStyle(
                color: fg,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 12),

          ...previewItems.take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: fg.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(color: fg),
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