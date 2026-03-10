import 'dart:async';
import 'package:flutter/material.dart';

class PomodoroWidgetPreview extends StatefulWidget {
  const PomodoroWidgetPreview({super.key});

  @override
  State<PomodoroWidgetPreview> createState() => _PomodoroWidgetPreviewState();
}

class _PomodoroWidgetPreviewState extends State<PomodoroWidgetPreview> {
  Timer? _timer;
  bool running = false;

  int seconds = 25 * 60;
  int maxSeconds = 25 * 60;

  void startPause() {
    if (running) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (seconds > 0) {
          setState(() => seconds--);
        } else {
          _timer?.cancel();
        }
      });
    }
    setState(() => running = !running);
  }

  String format(int s) =>
      "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  double get progress => 1 - (seconds / maxSeconds);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2F2F2F), Color(0xFF1A1A1A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 16),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pomodoro",
            style: TextStyle(color: Colors.white70),
          ),
          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                format(seconds),
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              GestureDetector(
                onTap: startPause,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    running ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: const Color(0xFFFFB703),
            ),
          ),
        ],
      ),
    );
  }
}
