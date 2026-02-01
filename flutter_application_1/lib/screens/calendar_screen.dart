import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late SharedPreferences _prefs;

  /// Stored as:  yyyy-mm-dd -> [event1, event2]
  Map<String, List<String>> _events = {};

  // ---------- INIT ----------
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString('calendar_events');

    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _events = decoded.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        );
      });
    }
  }

  // ---------- HELPERS ----------
  String _dayKey(DateTime day) =>
      '${day.year}-${day.month}-${day.day}';

  List<String> _getEventsForDay(DateTime day) {
    return _events[_dayKey(day)] ?? [];
  }

  Future<void> _saveEvents() async {
    await _prefs.setString(
      'calendar_events',
      jsonEncode(_events),
    );
  }

  Future<void> _addEvent(String event) async {
    if (_selectedDay == null) return;

    final key = _dayKey(_selectedDay!);
    _events.putIfAbsent(key, () => []);
    _events[key]!.add(event);

    await _saveEvents();
    setState(() {});
  }

  Future<void> _deleteEvent(String event) async {
    if (_selectedDay == null) return;

    final key = _dayKey(_selectedDay!);
    _events[key]?.remove(event);

    if (_events[key]?.isEmpty ?? false) {
      _events.remove(key);
    }

    await _saveEvents();
    setState(() {});
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) =>
                isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },

            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },

            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),

          const Divider(),

          Expanded(
            child: _selectedDay == null
                ? const Center(
                    child: Text('Select a day'),
                  )
                : _buildEventList(),
          ),
        ],
      ),

      floatingActionButton: _selectedDay == null
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddEventDialog(),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return const Center(
        child: Text('No events for this day'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        return Card(
          child: ListTile(
            leading: const Icon(Icons.event),
            title: Text(event),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteEvent(event),
            ),
          ),
        );
      },
    );
  }

  // ---------- DIALOG ----------
  void _showAddEventDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Event'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Event name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addEvent(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
