import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(CalendarApp());
}

class CalendarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calendar App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CalendarHomePage(),
    );
  }
}

class CalendarHomePage extends StatefulWidget {
  @override
  _CalendarHomePageState createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  // 날짜별 일정 저장
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEventsFromJson(); // JSON에서 데이터 불러오기
  }

  // 날짜를 정규화
  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // JSON 파일 경로 가져오기
  Future<File> _getJsonFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/events.json');
  }

  // JSON 파일에서 일정 데이터 불러오기
  Future<void> _loadEventsFromJson() async {
    try {
      final file = await _getJsonFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> jsonData = json.decode(contents);

        setState(() {
          _events = jsonData.map((key, value) {
            return MapEntry(
              DateTime.parse(key),
              List<String>.from(value),
            );
          });
        });
      }
    } catch (e) {
      print("Error loading events: $e");
    }
  }

  // JSON 파일에 일정 데이터 저장
  Future<void> _saveEventsToJson() async {
    final file = await _getJsonFile();
    final jsonData = _events.map((key, value) {
      return MapEntry(key.toIso8601String(), value);
    });
    await file.writeAsString(json.encode(jsonData));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Calendar App'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: (day) => _events[normalizeDate(day)] ?? [],
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = normalizeDate(selectedDay);
                _focusedDay = normalizeDate(focusedDay);
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = normalizeDate(focusedDay);
            },
          ),
          const SizedBox(height: 10),
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Day: ${_selectedDay!.toLocal()}'.split(' ')[0],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _addEventDialog(context),
                    child: Text('Add Event'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Flexible(
            child: _selectedDay != null
                ? ListView(
                    children: (_events[normalizeDate(_selectedDay!)] ?? [])
                        .map((event) => ListTile(
                              title: Text(event),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  _deleteEvent(event); // 삭제 버튼 클릭 시 호출
                                },
                              ),
                            ))
                        .toList(),
                  )
                : Center(child: Text("No events for the selected day.")),
          ),
        ],
      ),
    );
  }

  // 이벤트 추가 Dialog
  Future<void> _addEventDialog(BuildContext context) async {
    TextEditingController _eventController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Event'),
        content: TextField(
          controller: _eventController,
          decoration: InputDecoration(hintText: 'Enter event title'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_eventController.text.isNotEmpty) {
                setState(() {
                  final normalizedDate = normalizeDate(_selectedDay!);
                  if (_events[normalizedDate] != null) {
                    _events[normalizedDate]!.add(_eventController.text);
                  } else {
                    _events[normalizedDate] = [_eventController.text];
                  }
                });
                _saveEventsToJson(); // 일정 저장
              }
              Navigator.of(context).pop();
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  // 이벤트 삭제
  void _deleteEvent(String event) {
    setState(() {
      final normalizedDate = normalizeDate(_selectedDay!);
      _events[normalizedDate]?.remove(event);
      // 만약 해당 날짜에 더 이상 일정이 없으면 날짜를 키에서 삭제
      if (_events[normalizedDate]?.isEmpty ?? true) {
        _events.remove(normalizedDate);
      }
    });
    _saveEventsToJson(); // 삭제된 후 변경된 내용 저장
  }
}
