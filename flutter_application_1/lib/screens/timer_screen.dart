import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:widgetopia/models/timer_preset_model.dart';
import 'package:widgetopia/services/timer_preset_service.dart';
import 'package:widgetopia/models/saved_widget_model.dart';
import 'package:widgetopia/services/saved_widgets_service.dart';
import 'package:widgetopia/services/home_widget_service.dart';

// ──────────────────────────────────────────
//  Theme data
// ──────────────────────────────────────────
const List<TimerTheme> _themes = [
  TimerTheme(
    name: 'Latte',
    primary: Color(0xFFD4A574),
    secondary: Color(0xFFE8C9A0),
    accent: Color(0xFFC08552),
    background: Color(0xFFFFF8EE),
    textColor: Color(0xFF4A3728),
    cardColor: Color(0xFFFFF0DC),
  ),
  TimerTheme(
    name: 'Berry',
    primary: Color(0xFFD4728C),
    secondary: Color(0xFFE8A0B4),
    accent: Color(0xFFC05272),
    background: Color(0xFFFFF0F3),
    textColor: Color(0xFF4A2838),
    cardColor: Color(0xFFFFE0E8),
  ),
  TimerTheme(
    name: 'Matcha',
    primary: Color(0xFF74B88A),
    secondary: Color(0xFFA0D4B0),
    accent: Color(0xFF52996A),
    background: Color(0xFFF0FFF4),
    textColor: Color(0xFF28472E),
    cardColor: Color(0xFFDCF5E4),
  ),
  TimerTheme(
    name: 'Lavender',
    primary: Color(0xFF9B8EC4),
    secondary: Color(0xFFBDB2D8),
    accent: Color(0xFF7B6EA4),
    background: Color(0xFFF5F0FF),
    textColor: Color(0xFF352E4A),
    cardColor: Color(0xFFEAE0FF),
  ),
];

// ──────────────────────────────────────────
//  Timer Screen — Widget Detail Style
// ──────────────────────────────────────────
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;

  // Timer state
  bool _running = false;
  int _seconds = 25 * 60;
  int _maxSeconds = 25 * 60;

  // Pomodoro state
  String _phase = 'Focus';
  int _pomodoroCount = 0;

  // Presets
  List<TimerPreset> _presets = [];
  int _activePresetIndex = 0;

  // Theme
  int _themeIndex = 0;
  TimerTheme get _theme => _themes[_themeIndex];

  // Favorite
  bool _isFavorite = false;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _breathController;
  late Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  Future<void> _loadData() async {
    final presets = await TimerPresetService.loadPresets();
    final themeIdx = await TimerPresetService.loadThemeIndex();
    setState(() {
      _presets = presets;
      _themeIndex = themeIdx;
      if (_presets.isNotEmpty) {
        _seconds = _presets[0].minutes * 60;
        _maxSeconds = _seconds;
        _phase = _presets[0].label;
      }
    });
    _updateHomeWidget();
  }

  void _updateHomeWidget() {
    final status = _running ? 'Running' : 'Paused';
    HomeWidgetService.updatePomodoro(status, _format(_seconds));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    _pulseController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  // ────────── Core Timer Logic ──────────

  void _startPause() {
    if (_running) {
      _timer?.cancel();
      _pulseController.stop();
      setState(() => _running = false);
      _updateHomeWidget();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_seconds > 0) {
          setState(() => _seconds--);
          if (_seconds % 5 == 0) _updateHomeWidget(); // Update every 5s to save battery
        } else {
          _onFinish();
        }
      });
      _pulseController.repeat(reverse: true);
      setState(() => _running = true);
      _updateHomeWidget();
    }
  }

  void _reset() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _seconds = _maxSeconds;
      _running = false;
    });
    _updateHomeWidget();
  }

  Future<void> _onFinish() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() => _running = false);
    HapticFeedback.heavyImpact();
    try {
      await _player.play(AssetSource('sounds/miku-alarm.mp3'));
    } catch (_) {}

    _pomodoroCount++;
    _autoAdvancePhase();
  }

  void _autoAdvancePhase() {
    if (_phase == 'Focus' || (!_phase.toLowerCase().contains('break'))) {
      final isLongBreak = _pomodoroCount % 4 == 0;
      _selectPhaseByName(isLongBreak ? 'Long Break' : 'Short Break');
    } else {
      _selectPhaseByName('Focus');
    }
  }

  void _selectPhaseByName(String phaseName) {
    TimerPreset? preset;
    for (int i = 0; i < _presets.length; i++) {
      if (_presets[i].label.toLowerCase().contains(phaseName.toLowerCase())) {
        preset = _presets[i];
        _activePresetIndex = i;
        break;
      }
    }
    preset ??= _presets.isNotEmpty ? _presets[0] : null;

    setState(() {
      _phase = phaseName;
      if (preset != null) {
        _seconds = preset.minutes * 60;
        _maxSeconds = _seconds;
      }
    });
    _updateHomeWidget();
  }

  void _selectPreset(int index) {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _activePresetIndex = index;
      _phase = _presets[index].label;
      _seconds = _presets[index].minutes * 60;
      _maxSeconds = _seconds;
      _running = false;
    });
    _updateHomeWidget();
  }

  // ────────── Helpers ──────────

  String _format(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  double get _progress => _maxSeconds > 0 ? 1 - (_seconds / _maxSeconds) : 0;

  // ────────── Theme ──────────

  void _setTheme(int index) {
    setState(() => _themeIndex = index);
    TimerPresetService.saveThemeIndex(index);
  }

  // ────────── Preset CRUD ──────────

  Future<void> _addPreset() async {
    final nameCtrl = TextEditingController();
    int minutes = 25;
    String selectedIcon = '⏱️';
    final icons = [
      '🎯', '☕', '🌿', '🧠', '📖', '🏃', '🎵', '💤', '⏱️', '🔥'
    ];

    final result = await showModalBottomSheet<TimerPreset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: _theme.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _theme.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'New Preset',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _theme.textColor,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: _theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Preset name (e.g. Deep Study)',
                  hintStyle:
                      TextStyle(color: _theme.textColor.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: _theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$minutes minutes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _theme.textColor,
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: _theme.primary,
                  inactiveTrackColor: _theme.secondary.withValues(alpha: 0.3),
                  thumbColor: _theme.accent,
                  overlayColor: _theme.primary.withValues(alpha: 0.15),
                ),
                child: Slider(
                  min: 1,
                  max: 120,
                  value: minutes.toDouble(),
                  onChanged: (v) => setS(() => minutes = v.round()),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Icon',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _theme.textColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: icons.map((ico) {
                  final sel = selectedIcon == ico;
                  return GestureDetector(
                    onTap: () => setS(() => selectedIcon = ico),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: sel
                            ? _theme.primary.withValues(alpha: 0.2)
                            : _theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: sel
                            ? Border.all(color: _theme.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(ico, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _theme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(
                      ctx,
                      TimerPreset(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        label: nameCtrl.text.trim(),
                        minutes: minutes,
                        icon: selectedIcon,
                      ),
                    );
                  },
                  child: const Text('Add Preset',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() => _presets.add(result));
      await TimerPresetService.savePresets(_presets);
    }
  }

  Future<void> _editPreset(int index) async {
    final preset = _presets[index];
    final nameCtrl = TextEditingController(text: preset.label);
    int minutes = preset.minutes;
    String selectedIcon = preset.icon;
    final icons = [
      '🎯', '☕', '🌿', '🧠', '📖', '🏃', '🎵', '💤', '⏱️', '🔥'
    ];

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: _theme.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _theme.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Preset',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _theme.textColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx, 'delete'),
                    icon:
                        Icon(Icons.delete_outline, color: Colors.red.shade300),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: _theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Preset name',
                  hintStyle:
                      TextStyle(color: _theme.textColor.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: _theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$minutes minutes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _theme.textColor,
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: _theme.primary,
                  inactiveTrackColor: _theme.secondary.withValues(alpha: 0.3),
                  thumbColor: _theme.accent,
                  overlayColor: _theme.primary.withValues(alpha: 0.15),
                ),
                child: Slider(
                  min: 1,
                  max: 120,
                  value: minutes.toDouble(),
                  onChanged: (v) => setS(() => minutes = v.round()),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Icon',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _theme.textColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: icons.map((ico) {
                  final sel = selectedIcon == ico;
                  return GestureDetector(
                    onTap: () => setS(() => selectedIcon = ico),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: sel
                            ? _theme.primary.withValues(alpha: 0.2)
                            : _theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: sel
                            ? Border.all(color: _theme.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(ico, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _theme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(
                      ctx,
                      TimerPreset(
                        id: preset.id,
                        label: nameCtrl.text.trim(),
                        minutes: minutes,
                        icon: selectedIcon,
                      ),
                    );
                  },
                  child: const Text('Save Changes',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == 'delete') {
      setState(() {
        _presets.removeAt(index);
        if (_activePresetIndex >= _presets.length) {
          _activePresetIndex = max(0, _presets.length - 1);
        }
        if (_presets.isNotEmpty) {
          _seconds = _presets[_activePresetIndex].minutes * 60;
          _maxSeconds = _seconds;
          _phase = _presets[_activePresetIndex].label;
        }
      });
      await TimerPresetService.savePresets(_presets);
    } else if (result is TimerPreset) {
      setState(() {
        _presets[index] = result;
        if (_activePresetIndex == index) {
          _seconds = result.minutes * 60;
          _maxSeconds = _seconds;
          _phase = result.label;
        }
      });
      await TimerPresetService.savePresets(_presets);
    }
  }

  Future<void> _editTimeDirect() async {
    int minutes = _seconds ~/ 60;
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _theme.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _theme.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Set Duration',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$minutes min',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: _theme.accent,
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: _theme.primary,
                  inactiveTrackColor: _theme.secondary.withValues(alpha: 0.3),
                  thumbColor: _theme.accent,
                  overlayColor: _theme.primary.withValues(alpha: 0.15),
                ),
                child: Slider(
                  min: 1,
                  max: 120,
                  value: minutes.toDouble(),
                  onChanged: (v) => setS(() => minutes = v.round()),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _theme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, minutes),
                  child: const Text('Set Timer',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _seconds = result * 60;
        _maxSeconds = _seconds;
      });
    }
  }

  // ══════════════════════════════════════
  //  BUILD — Widget Detail Page Style
  // ══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _theme.background,
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero preview area ──
              SliverToBoxAdapter(child: _buildHeroPreview()),

              // ── Info card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoCard(),
                ),
              ),

              // ── Preset chips ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildPresetsSection(),
                ),
              ),

              // ── Live Preview section ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: _buildPreviewSection(),
                ),
              ),

              // ── Theme Variations ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: _buildThemeVariations(),
                ),
              ),

              // Bottom padding for the fixed button
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // ── Fixed "Add Widget" button ──
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: _buildAddWidgetButton(),
          ),
        ],
      ),
    );
  }

  // ────────── Hero Preview ──────────

  Widget _buildHeroPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _theme.cardColor,
            _theme.secondary.withValues(alpha: 0.4),
            _theme.background,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _theme.primary.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative sparkles & blobs
            ..._buildDecorations(),

            // Subtle gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      _theme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),

            // Timer widget preview (centered clock display)
            Center(
              child: AnimatedBuilder(
                animation: _breathAnim,
                builder: (context, child) {
                  return Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.85),
                      boxShadow: [
                        BoxShadow(
                          color: _theme.primary.withValues(
                              alpha: 0.12 + _breathAnim.value * 0.08),
                          blurRadius: 30 + _breathAnim.value * 10,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: _theme.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Mini progress ring
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CustomPaint(
                            painter: _TimerRingPainter(
                              progress: _progress,
                              trackColor:
                                  _theme.secondary.withValues(alpha: 0.25),
                              progressColor: _theme.primary,
                              glowColor: _theme.accent,
                              strokeWidth: 6,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _format(_seconds),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: _theme.textColor,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _theme.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _theme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Back / Favorite / Share buttons
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _iconBtn(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        _iconBtn(
                          icon: _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          onTap: () =>
                              setState(() => _isFavorite = !_isFavorite),
                          color: _isFavorite ? Colors.redAccent : null,
                        ),
                        const SizedBox(width: 8),
                        _iconBtn(
                          icon: Icons.share_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: color ?? _theme.textColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  List<Widget> _buildDecorations() {
    final rng = Random(42); // fixed seed for consistent layout
    final List<Widget> decorations = [];

    // Pastel blobs
    final blobColors = [
      _theme.primary.withValues(alpha: 0.12),
      _theme.secondary.withValues(alpha: 0.15),
      const Color(0xFFFFD6E0).withValues(alpha: 0.15), // pink
      const Color(0xFFD4E8D0).withValues(alpha: 0.15), // sage
    ];
    for (int i = 0; i < 5; i++) {
      final size = 40.0 + rng.nextDouble() * 60;
      decorations.add(
        Positioned(
          left: rng.nextDouble() * 300,
          top: rng.nextDouble() * 250,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blobColors[i % blobColors.length],
            ),
          ),
        ),
      );
    }

    // Sparkle dots
    for (int i = 0; i < 12; i++) {
      final dotSize = 3.0 + rng.nextDouble() * 5;
      decorations.add(
        Positioned(
          left: rng.nextDouble() * 340,
          top: rng.nextDouble() * 280,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _theme.primary
                  .withValues(alpha: 0.2 + rng.nextDouble() * 0.15),
            ),
          ),
        ),
      );
    }

    // Diamond shapes
    for (int i = 0; i < 4; i++) {
      final dSize = 8.0 + rng.nextDouble() * 10;
      decorations.add(
        Positioned(
          left: rng.nextDouble() * 320,
          top: rng.nextDouble() * 260,
          child: Transform.rotate(
            angle: pi / 4,
            child: Container(
              width: dSize,
              height: dSize,
              decoration: BoxDecoration(
                color: _theme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      );
    }

    return decorations;
  }

  // ────────── Info Card ──────────

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _theme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: _theme.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Rating
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cozy Timer',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _theme.textColor,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFB800), size: 18),
                    const SizedBox(width: 3),
                    Text(
                      '4.8',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Creator
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _theme.secondary.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'W',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _theme.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'by Widgetopia Studio',
                style: TextStyle(
                  fontSize: 13,
                  color: _theme.textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Description
          Text(
            'A warm, minimal pomodoro timer widget with soft pastel backgrounds and gentle animations. Perfect for your home screen aesthetic.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: _theme.textColor.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 14),

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['#minimal', '#aesthetic', '#pastel', '#cozy']
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _theme.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _theme.accent,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _statBadge(
                icon: Icons.download_rounded,
                value: '12.4k',
                label: 'downloads',
                badgeColor: const Color(0xFFFFF0DC),
                iconColor: _theme.primary,
              ),
              const SizedBox(width: 12),
              _statBadge(
                icon: Icons.palette_rounded,
                value: '4',
                label: 'themes',
                badgeColor: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF74B88A),
              ),
              const SizedBox(width: 12),
              _statBadge(
                icon: Icons.rate_review_rounded,
                value: '2.1k',
                label: 'reviews',
                badgeColor: const Color(0xFFF3E5F5),
                iconColor: const Color(0xFF9B8EC4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge({
    required IconData icon,
    required String value,
    required String label,
    required Color badgeColor,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _theme.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: _theme.textColor.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────── Presets Section ──────────

  Widget _buildPresetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.timer_rounded,
                    size: 18, color: _theme.textColor.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Text(
                  'Presets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _theme.textColor,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _addPreset,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: _theme.accent),
                    const SizedBox(width: 3),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _theme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: _presets.isEmpty
              ? Center(
                  child: Text(
                    'No presets yet — tap Add to create one!',
                    style: TextStyle(
                        color: _theme.textColor.withValues(alpha: 0.4)),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presets.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _presetChip(i),
                ),
        ),
      ],
    );
  }

  Widget _presetChip(int index) {
    final p = _presets[index];
    final active = index == _activePresetIndex;

    return GestureDetector(
      onTap: () => _selectPreset(index),
      onLongPress: () => _editPreset(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 88,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active
              ? _theme.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: active
              ? Border.all(color: _theme.primary, width: 2)
              : Border.all(
                  color: _theme.primary.withValues(alpha: 0.1), width: 1),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _theme.primary.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(p.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              p.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? _theme.accent : _theme.textColor,
              ),
            ),
            Text(
              '${p.minutes}m',
              style: TextStyle(
                fontSize: 10,
                color: _theme.textColor.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────── Live Preview Section ──────────

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.visibility_rounded,
                size: 18, color: _theme.textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              'Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // The live timer preview card
        AnimatedBuilder(
          animation: Listenable.merge([_pulseAnim, _breathAnim]),
          builder: (context, child) {
            final scale = _running ? _pulseAnim.value : 1.0;

            return Transform.scale(
              scale: scale,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _theme.cardColor,
                      _theme.secondary.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _theme.primary.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _theme.primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Phase badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: _theme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _phase,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _theme.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timer display
                    GestureDetector(
                      onTap: _running ? null : _editTimeDirect,
                      child: Text(
                        _format(_seconds),
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          color: _theme.textColor,
                          letterSpacing: 3,
                          height: 1,
                        ),
                      ),
                    ),

                    if (!_running)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'tap to edit',
                          style: TextStyle(
                            fontSize: 11,
                            color: _theme.textColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ),

                    const SizedBox(height: 6),

                    // Theme name label
                    Text(
                      _theme.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _theme.primary.withValues(alpha: 0.7),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Progress bar
                    Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: _theme.secondary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_theme.primary, _theme.accent],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      _theme.primary.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _miniControl(
                          icon: Icons.refresh_rounded,
                          onTap: _reset,
                        ),
                        const SizedBox(width: 16),
                        // Play/Pause button
                        GestureDetector(
                          onTap: _startPause,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_theme.primary, _theme.accent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      _theme.primary.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              _running
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _miniControl(
                          icon: Icons.skip_next_rounded,
                          onTap: () {
                            _timer?.cancel();
                            _pulseController.stop();
                            _pulseController.reset();
                            setState(() => _running = false);
                            _autoAdvancePhase();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Pomodoro dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final done = i < (_pomodoroCount % 4);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: done ? 22 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: done
                                ? _theme.primary
                                : _theme.secondary.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _miniControl({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.7),
          border: Border.all(
            color: _theme.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Icon(icon, color: _theme.textColor, size: 20),
      ),
    );
  }

  // ────────── Theme Variations ──────────

  Widget _buildThemeVariations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette_rounded,
                size: 18, color: _theme.textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              'Theme Variations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_themes.length, (i) {
            final t = _themes[i];
            final sel = i == _themeIndex;
            return GestureDetector(
              onTap: () => _setTheme(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 76,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: sel
                      ? t.primary.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: sel
                      ? Border.all(color: t.primary, width: 2)
                      : Border.all(color: t.primary.withValues(alpha: 0.12)),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: t.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dot(t.primary, 14),
                        const SizedBox(width: 4),
                        _dot(t.secondary, 14),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: t.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _dot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // ────────── Add Widget Button ──────────

  Widget _buildAddWidgetButton() {
    return GestureDetector(
      onTap: () async {
        final widget = SavedWidgetModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'pomodoro',
          title: 'Cozy Timer',
          config: {'theme': _themeIndex},
          createdAt: DateTime.now(),
        );

        await SavedWidgetsService.save(widget);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Widget added! ✨'),
            backgroundColor: _theme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_theme.primary, _theme.accent],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _theme.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Add Widget',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════
//  Custom ring painter
// ══════════════════════════════════════
class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color glowColor;
  final double strokeWidth;

  _TimerRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.glowColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Glow
    if (progress > 0) {
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
    }

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor;
}
