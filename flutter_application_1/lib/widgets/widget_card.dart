import 'package:flutter/material.dart';
import '../models/widget_item.dart';
import '../utils/theme_provider.dart';
import 'widget_customization_sheet.dart';

/// ─── Figma-style Widget Discovery Card ───
/// Shows a preview image with rating badge, heart/save icon,
/// title, creator with colored dot, downloads, and a category indicator.
class WidgetCard extends StatefulWidget {
  final WidgetItem item;
  final VoidCallback onTap;
  final VoidCallback? onSave;
  final bool isSaved;

  const WidgetCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onSave,
    this.isSaved = false,
  });

  @override
  State<WidgetCard> createState() => _WidgetCardState();
}

class _WidgetCardState extends State<WidgetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _scaleAnim;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _saved = widget.isSaved;
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 1,
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  void _toggleSave() {
    setState(() => _saved = !_saved);
    widget.onSave?.call();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.item;
    final c = ThemeProvider.colorsOf(context);
    return GestureDetector(
      onTapDown: (_) => _hoverCtrl.forward(),
      onTapUp: (_) {
        _hoverCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _hoverCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: c.shadow.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Image Preview Area ───
              AspectRatio(
                aspectRatio: 1.25,
                child: Stack(
                  children: [
                    // Preview image / colored placeholder
                    Container(
                      decoration: BoxDecoration(
                        color: w.cardColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: _WidgetPreviewThumb(type: w.type),
                      ),
                    ),
                  // Save/heart button (top right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              WidgetCustomizationSheet.show(
                                context,
                                widgetId: w.id,
                                widgetTitle: w.title,
                                widgetType: w.type,
                                accentColor: w.creatorColor,
                              );
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: c.cardBg.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: c.shadow.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(Icons.more_vert_rounded, size: 18, color: c.textSecondary),
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleSave,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _saved
                                    ? const Color(0xFFFF6B6B)
                                    : c.cardBg.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: c.shadow.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _saved
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 18,
                                color: _saved
                                    ? Colors.white
                                    : c.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Info Section ───
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      w.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Creator row
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: w.creatorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            w.creator,
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Downloads + dots
                    Row(
                      children: [
                        Icon(Icons.download_outlined,
                            size: 14,
                            color: c.textSecondary.withValues(alpha: 0.7)),
                        const SizedBox(width: 3),
                        Text(
                          w.downloads,
                          style: TextStyle(
                            fontSize: 11,
                            color: c.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                        const Spacer(),
                        // Dot indicators
                        ...List.generate(
                          2,
                          (i) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? c.primary
                                  : c.primary.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small icon-based preview thumbnail for the card
class _WidgetPreviewThumb extends StatelessWidget {
  final String type;
  const _WidgetPreviewThumb({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (type) {
      case "pomodoro":
        icon = Icons.timer_outlined;
        color = const Color(0xFFD4A574);
        break;
      case "quote":
        icon = Icons.format_quote_rounded;
        color = const Color(0xFFFF6B6B);
        break;
      case "calendar":
        icon = Icons.calendar_month_rounded;
        color = const Color(0xFF4ECDC4);
        break;
      case "notepad":
        icon = Icons.note_alt_outlined;
        color = const Color(0xFFFFB347);
        break;
      case "habit":
        icon = Icons.check_circle_outline_rounded;
        color = const Color(0xFF7B61FF);
        break;
      case "mood":
        icon = Icons.mood_rounded;
        color = const Color(0xFFFF8FAB);
        break;
      case "art_shuffle":
        icon = Icons.palette_outlined;
        color = const Color(0xFFE040FB);
        break;
      case "exam_planner":
        icon = Icons.school_outlined;
        color = const Color(0xFF42A5F5);
        break;
      case "sunrise_sunset":
        icon = Icons.wb_twilight_rounded;
        color = const Color(0xFFFF7043);
        break;
      case "day_progress":
        icon = Icons.hourglass_bottom_rounded;
        color = const Color(0xFF26A69A);
        break;
      case "agenda":
        icon = Icons.view_agenda_outlined;
        color = const Color(0xFF5C6BC0);
        break;
      case "weekly_agenda":
        icon = Icons.date_range_rounded;
        color = const Color(0xFF66BB6A);
        break;
      default:
        icon = Icons.widgets_outlined;
        color = const Color(0xFF8C776A);
    }
    return Icon(icon, size: 48, color: color.withValues(alpha: 0.6));
  }
}
