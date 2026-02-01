import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

enum TimerMode { normal, pomodoro, custom }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;

  bool running = false;
  int seconds = 1500;
  int maxSeconds = 1500;

  TimerMode mode = TimerMode.normal;

  // Pomodoro
  int work = 25 * 60;
  int shortBreak = 5 * 60;
  int longBreak = 15 * 60;
  String phase = "Work";
  int cycle = 0;

  // Custom timers
  List<Map<String, dynamic>> customTimers = [];

  // ---------------- CORE ----------------

  void startPause() {
    if (running) {
      _timer?.cancel();
      setState(() => running = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (seconds > 0) {
          setState(() => seconds--);
        } else {
          finish();
        }
      });
      setState(() => running = true);
    }
  }

  void reset() {
    _timer?.cancel();
    setState(() {
      seconds = maxSeconds;
      running = false;
    });
  }

  Future<void> finish() async {
    _timer?.cancel();
    setState(() => running = false);

    HapticFeedback.heavyImpact();
    await _player.play(AssetSource('sounds/miku-alarm.mp3'));

    if (mode == TimerMode.pomodoro) nextPomodoro();
  }

  // ---------------- HELPERS ----------------

  String format(int s) =>
      "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  double get progress => 1 - (seconds / maxSeconds);

  // ---------------- EDIT TIME DIALOG ----------------

  Future<void> editTime(int current, Function(int) onSave) async {
    int minutes = current ~/ 60;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit duration"),
        content: StatefulBuilder(
          builder: (context, setD) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$minutes minutes",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                min: 1,
                max: 180,
                value: minutes.toDouble(),
                onChanged: (v) => setD(() => minutes = v.toInt()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              onSave(minutes * 60);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------------- POMODORO ----------------

  void startPomodoro() {
    setState(() {
      mode = TimerMode.pomodoro;
      phase = "Work";
      cycle = 0;
      seconds = work;
      maxSeconds = seconds;
      running = false;
    });
  }

  void nextPomodoro() {
    setState(() {
      if (phase == "Work") {
        cycle++;
        if (cycle % 4 == 0) {
          phase = "Long Break";
          seconds = longBreak;
        } else {
          phase = "Short Break";
          seconds = shortBreak;
        }
      } else {
        phase = "Work";
        seconds = work;
      }
      maxSeconds = seconds;
    });
  }

  // ---------------- CUSTOM ----------------

  Future<void> addCustom() async {
    TextEditingController name = TextEditingController();
    TextEditingController mins = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("New Timer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(hintText: "Name")),
            TextField(
                controller: mins,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "Minutes")),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (name.text.isEmpty || mins.text.isEmpty) return;

              setState(() {
                customTimers.add({
                  "name": name.text,
                  "seconds": int.parse(mins.text) * 60,
                });
              });

              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Timer")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Tabs
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8C8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _tab("Normal", TimerMode.normal),
                  _tab("Pomodoro", TimerMode.pomodoro),
                  _tab("Custom", TimerMode.custom),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Potato (only Pomodoro)
            if (mode == TimerMode.pomodoro)
              Column(
                children: [
                  Image.asset("assets/images/potato1.png", height: 110),
                  const SizedBox(height: 6),
                  Text(
                    phase,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Timer Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (mode == TimerMode.normal) {
                          editTime(seconds, (v) {
                            setState(() {
                              seconds = v;
                              maxSeconds = v;
                            });
                          });
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 200,
                            width: 200,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                            ),
                          ),
                          Text(
                            format(seconds),
                            style: const TextStyle(
                                fontSize: 48, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    if (mode == TimerMode.normal)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text("Tap timer to edit"),
                      ),

                    if (mode == TimerMode.pomodoro)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                              onPressed: () =>
                                  editTime(work, (v) => setState(() => work = v)),
                              child: const Text("Work")),
                          TextButton(
                              onPressed: () => editTime(shortBreak,
                                  (v) => setState(() => shortBreak = v)),
                              child: const Text("Short")),
                          TextButton(
                              onPressed: () => editTime(longBreak,
                                  (v) => setState(() => longBreak = v)),
                              child: const Text("Long")),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(running ? Icons.pause : Icons.play_arrow),
                  label: Text(running ? "Pause" : "Start"),
                  onPressed: startPause,
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.restart_alt),
                  label: const Text("Reset"),
                  onPressed: reset,
                ),
              ],
            ),

            // Custom section
            if (mode == TimerMode.custom) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: addCustom,
                icon: const Icon(Icons.add),
                label: const Text("Add Timer"),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: customTimers
                      .map((t) => ListTile(
                            title: Text(t["name"]),
                            trailing:
                                Text("${(t["seconds"] ~/ 60)} min"),
                            onTap: () {
                              setState(() {
                                seconds = t["seconds"];
                                maxSeconds = seconds;
                              });
                            },
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, TimerMode m) {
    final selected = mode == m;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            running = false;
            mode = m;
            if (m == TimerMode.pomodoro) startPomodoro();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFB703) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: Text(label)),
        ),
      ),
    );
  }
}
