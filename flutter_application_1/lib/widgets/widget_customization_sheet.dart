import 'package:flutter/material.dart';
import 'package:widgetopia/utils/theme_provider.dart';
import 'package:widgetopia/services/saved_widgets_service.dart';
import 'package:widgetopia/models/saved_widget_model.dart';

/// A unified customization bottom sheet for any widget card.
/// Provides size, theme color, layout, and "Add to Home" options.
class WidgetCustomizationSheet extends StatefulWidget {
  final String widgetId;
  final String widgetTitle;
  final String widgetType;
  final Color accentColor;

  const WidgetCustomizationSheet({
    super.key,
    required this.widgetId,
    required this.widgetTitle,
    required this.widgetType,
    required this.accentColor,
  });

  static void show(
    BuildContext context, {
    required String widgetId,
    required String widgetTitle,
    required String widgetType,
    required Color accentColor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WidgetCustomizationSheet(
        widgetId: widgetId,
        widgetTitle: widgetTitle,
        widgetType: widgetType,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<WidgetCustomizationSheet> createState() =>
      _WidgetCustomizationSheetState();
}

class _WidgetCustomizationSheetState extends State<WidgetCustomizationSheet> {
  int _selectedSize = 1; // 0=small, 1=medium, 2=large
  int _selectedTheme = 0;
  bool _compact = false;

  final _themeColors = const [
    Color(0xFFD4A574),
    Color(0xFF7B61FF),
    Color(0xFF4ECDC4),
    Color(0xFFFF6B6B),
    Color(0xFFE040FB),
  ];

  final _sizeLabels = const ['Small', 'Medium', 'Large'];

  Future<void> _addToHome() async {
    await SavedWidgetsService.save(
      SavedWidgetModel(
        id: widget.widgetId,
        type: widget.widgetType,
        title: widget.widgetTitle,
        config: {
          'size': _selectedSize,
          'theme': _selectedTheme,
          'compact': _compact,
        },
        createdAt: DateTime.now(),
      )
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.widgetTitle} added to Saved!'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: widget.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customize',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        widget.widgetTitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Size Picker ───
          _SectionLabel(label: 'Widget Size', colors: c),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(3, (i) {
                final selected = _selectedSize == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSize = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? widget.accentColor.withValues(alpha: 0.12)
                            : c.chipBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? widget.accentColor.withValues(alpha: 0.4)
                              : c.divider,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _sizeLabels[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? widget.accentColor : c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 22),

          // ─── Theme Color Picker ───
          _SectionLabel(label: 'Accent Color', colors: c),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(_themeColors.length, (i) {
                final selected = _selectedTheme == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTheme = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _themeColors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? c.textPrimary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color:
                                    _themeColors[i].withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 22),

          // ─── Layout Toggle ───
          _SectionLabel(label: 'Layout', colors: c),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _ToggleOption(
                  label: 'Expanded',
                  icon: Icons.fullscreen_rounded,
                  selected: !_compact,
                  accentColor: widget.accentColor,
                  onTap: () => setState(() => _compact = false),
                ),
                const SizedBox(width: 10),
                _ToggleOption(
                  label: 'Compact',
                  icon: Icons.compress_rounded,
                  selected: _compact,
                  accentColor: widget.accentColor,
                  onTap: () => setState(() => _compact = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ─── Add to Home Button ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _addToHome,
                icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                label: const Text(
                  'Add to Saved',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppColors colors;
  const _SectionLabel({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(alpha: 0.12)
                : c.chipBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accentColor.withValues(alpha: 0.4)
                  : c.divider,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? accentColor : c.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accentColor : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
