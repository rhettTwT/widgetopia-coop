import 'dart:async';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';

class BatteryScreen extends StatefulWidget {
  const BatteryScreen({super.key});

  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen> {
  final Battery _battery = Battery();

  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;

  StreamSubscription<BatteryState>? _batteryStateSub;
  Timer? _levelTimer;

  @override
  void initState() {
    super.initState();
    _initBattery();
  }

  Future<void> _initBattery() async {
    // Initial values
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;

    if (!mounted) return;
    setState(() {
      _batteryLevel = level;
      _batteryState = state;
    });

    // Listen to charging state
    _batteryStateSub =
        _battery.onBatteryStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _batteryState = state);
    });

    // Refresh battery level every 15 seconds
    _levelTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) async {
        final level = await _battery.batteryLevel;
        if (!mounted) return;
        setState(() => _batteryLevel = level);
      },
    );
  }

  @override
  void dispose() {
    _batteryStateSub?.cancel();
    _levelTimer?.cancel();
    super.dispose();
  }

  IconData get _statusIcon {
    switch (_batteryState) {
      case BatteryState.charging:
        return Icons.battery_charging_full;
      case BatteryState.full:
        return Icons.battery_full;
      case BatteryState.discharging:
        return Icons.battery_std;
      default:
        return Icons.battery_unknown;
    }
  }

  String get _statusText {
    switch (_batteryState) {
      case BatteryState.charging:
        return 'Charging';
      case BatteryState.full:
        return 'Full';
      case BatteryState.discharging:
        return 'Discharging';
      default:
        return 'Unknown';
    }
  }

  Color get _levelColor {
    if (_batteryLevel <= 20) return Colors.red;
    if (_batteryLevel <= 50) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battery')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _statusIcon,
                  size: 60,
                  color: _levelColor,
                ),
                const SizedBox(height: 12),
                Text(
                  '$_batteryLevel%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _levelColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _statusText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _batteryLevel / 100,
                  color: _levelColor,
                  minHeight: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
