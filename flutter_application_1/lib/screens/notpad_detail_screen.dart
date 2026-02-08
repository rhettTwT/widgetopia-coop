import 'package:flutter/material.dart';
import 'package:widgetopia/widgets/notepad_widget_preview.dart';
import 'package:widgetopia/models/saved_widget_model.dart';
import 'package:widgetopia/services/saved_widgets_service.dart';

class NotepadDetailScreen extends StatefulWidget {
  const NotepadDetailScreen({super.key});

  @override
  State<NotepadDetailScreen> createState() => _NotepadDetailScreenState();
}

class _NotepadDetailScreenState extends State<NotepadDetailScreen> {
  String theme = "original"; // original, dark, pastel, neon
  Color bgColor = const Color(0xFFFFF4D6);

  void _setTheme(String t) {
    setState(() {
      theme = t;
      switch (t) {
        case "dark":
          bgColor = const Color(0xFF1F2933);
          break;
        case "pastel":
          bgColor = const Color(0xFFFFE4EC);
          break;
        case "neon":
          bgColor = const Color(0xFF2B0015);
          break;
        default:
          bgColor = const Color(0xFFFFF4D6);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HERO
              Hero(
                tag: "notepad",
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
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Chip(
                          label: Text("Featured"),
                          backgroundColor: Color(0xFFFFC857),
                        ),
                        Spacer(),
                        Text(
                          "Personal Notepad",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Your thoughts, right on your home screen 📝",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// PREVIEW
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: NotepadWidgetPreview(theme: theme),
              ),

              const SizedBox(height: 28),

              /// STYLE VARIATIONS
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "🎨 Style Variations",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _StyleCard("Original", () => _setTheme("original")),
                    _StyleCard("Dark", () => _setTheme("dark")),
                    _StyleCard("Pastel", () => _setTheme("pastel")),
                    _StyleCard("Neon", () => _setTheme("neon")),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              /// ADD TO HOME
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
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
                      type: "notepad",
                      title: "Personal Notepad",
                      config: {"theme": theme},
                      createdAt: DateTime.now(),
                    );

                    await SavedWidgetsService.save(widget);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Notepad added to home 💾")),
                    );
                  },
                  child: const Text("Add to Home Screen"),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back"),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StyleCard(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFEDE7DF),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
