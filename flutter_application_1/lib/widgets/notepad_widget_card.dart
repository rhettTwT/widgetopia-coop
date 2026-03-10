import 'package:flutter/material.dart';
import 'package:widgetopia/screens/notepad_detail_screen.dart';

class NotepadWidgetCard extends StatelessWidget {
  const NotepadWidgetCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NotepadDetailScreen(),
          ),
        );
      },
      child: Container(
        height: 170,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF6EFE7),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Notepad Widget",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E241C),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Notes & checklists, always handy",
              style: TextStyle(
                color: Color(0xFF7A6A5A),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                Icons.sticky_note_2_rounded,
                color: Colors.brown.withValues(alpha: 0.25),
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
