import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:widgetopia/models/timer_preset_model.dart';
import 'package:widgetopia/services/timer_preset_service.dart';

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
//  Timer Screen
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
    _pulseAnim = Tween(begin: 1.0, end: 1.06).animate(
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
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_seconds > 0) {
          setState(() => _seconds--);
        } else {
          _onFinish();
        }
      });
      _pulseController.repeat(reverse: true);
      setState(() => _running = true);
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

  // ══════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _theme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildTimerRing(),
                    const SizedBox(height: 28),
                    _buildControls(),
                    const SizedBox(height: 20),
                    _buildPomodoroIndicator(),
                    const SizedBox(height: 28),
                    _buildPresetsSection(),
                    const SizedBox(height: 28),
                    _buildThemePicker(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────── App Bar ──────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _theme.cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: _theme.textColor, size: 22),
            ),
          ),
          const Spacer(),
          Text(
            'Cozy Timer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _theme.textColor,
            ),
          ),
          const Spacer(),
          // Invisible spacer to center the title
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  // ────────── Timer Ring ──────────

  Widget _buildTimerRing() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _breathAnim]),
      builder: (context, child) {
        final scale = _running ? _pulseAnim.value : 1.0;
        final breathVal = _breathAnim.value;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _theme.primary
                      .withValues(alpha: 0.15 + breathVal * 0.1),
                  blurRadius: 40 + breathVal * 20,
                  spreadRadius: 5 + breathVal * 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ring painter
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(
                    painter: _TimerRingPainter(
                      progress: _progress,
                      trackColor: _theme.secondary.withValues(alpha: 0.3),
                      progressColor: _theme.primary,
                      glowColor: _theme.accent,
                      strokeWidth: 10,
                    ),
                  ),
                ),
                // Inner frosted circle
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _theme.cardColor.withValues(alpha: 0.7),
                    border: Border.all(
                      color: _theme.primary.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Phase badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: _theme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _phase,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _theme.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Time display
                      GestureDetector(
                        onTap: _running ? null : _editTimeDirect,
                        child: Text(
                          _format(_seconds),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: _theme.textColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      if (!_running)
                        Text(
                          'tap to edit',
                          style: TextStyle(
                            fontSize: 11,
                            color: _theme.textColor.withValues(alpha: 0.35),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  // ────────── Controls ──────────

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _controlButton(
          icon: Icons.refresh_rounded,
          label: 'Reset',
          onTap: _reset,
        ),
        const SizedBox(width: 20),
        // Big play/pause
        GestureDetector(
          onTap: _startPause,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_theme.primary, _theme.accent],
              ),
              boxShadow: [
                BoxShadow(
                  color: _theme.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 20),
        _controlButton(
          icon: Icons.skip_next_rounded,
          label: 'Skip',
          onTap: () {
            _timer?.cancel();
            _pulseController.stop();
            _pulseController.reset();
            setState(() => _running = false);
            _autoAdvancePhase();
          },
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _theme.cardColor,
              border: Border.all(
                color: _theme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: _theme.textColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _theme.textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ────────── Pomodoro dots ──────────

  Widget _buildPomodoroIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final done = i < (_pomodoroCount % 4);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: done ? 28 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: done
                ? _theme.primary
                : _theme.secondary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
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
            Text(
              'Presets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              ),
            ),
            GestureDetector(
              onTap: _addPreset,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _theme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: _theme.accent),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 14,
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
        const SizedBox(height: 14),
        SizedBox(
          height: 100,
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
                  separatorBuilder: (c, i) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _presetCard(i),
                ),
        ),
      ],
    );
  }

  Widget _presetCard(int index) {
    final p = _presets[index];
    final active = index == _activePresetIndex;

    return GestureDetector(
      onTap: () => _selectPreset(index),
      onLongPress: () => _editPreset(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active
              ? _theme.primary.withValues(alpha: 0.15)
              : _theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? Border.all(color: _theme.primary, width: 2)
              : Border.all(
                  color: _theme.primary.withValues(alpha: 0.08), width: 1),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _theme.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(p.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              p.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? _theme.accent : _theme.textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${p.minutes} min',
              style: TextStyle(
                fontSize: 11,
                color: _theme.textColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────── Theme Picker ──────────

  Widget _buildThemePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _theme.textColor,
          ),
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
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      sel ? t.primary.withValues(alpha: 0.15) : t.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: sel
                      ? Border.all(color: t.primary, width: 2)
                      : Border.all(color: t.primary.withValues(alpha: 0.15)),
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
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
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
