import 'package:flutter/material.dart';

class ScheduleEditor extends StatefulWidget {
  final List<String> weekdayDescriptions;

  const ScheduleEditor({
    super.key,
    required this.weekdayDescriptions,
  });

  @override
  State<ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<ScheduleEditor> {
  final List<String> _days = [
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday",
  ];

  final List<String> _daysPortuguese = [
    "segunda-feira",
    "terça-feira",
    "quarta-feira",
    "quinta-feira",
    "sexta-feira",
    "sábado",
    "domingo",
  ];

  final Map<String, String> _dayNames = {
    "monday": "Segunda-feira",
    "tuesday": "Terça-feira",
    "wednesday": "Quarta-feira",
    "thursday": "Quinta-feira",
    "friday": "Sexta-feira",
    "saturday": "Sábado",
    "sunday": "Domingo",
  };

  final Map<String, bool> _isClosed = {};
  final Map<String, List<TimeRange>> _schedules = {};
  Map<String, dynamic> weekdayDescriptionsParsed = {};

  void weekdayDescriptionsToMap() {

    for (final entry in widget.weekdayDescriptions) {
      final parts = entry.split(":");
      if (parts.length < 2) continue;

      final day = parts[0].trim().toLowerCase();
      final value = entry.substring(entry.indexOf(":") + 1).trim();

      weekdayDescriptionsParsed[day] = value;
    }

  }

  String parseDay(String day) {
    switch (day) {
      case 'monday': return 'segunda-feira';
      case 'tuesday': return 'terça-feira';
      case 'wednesday': return 'quarta-feira';
      case 'thursday': return 'quinta-feira';
      case 'friday': return 'sexta-feira';
      case 'saturday': return 'sábado';
      case 'sunday': return 'domingo';
      default: return day;
    }
  }

  @override
  void initState() {
    super.initState();
    weekdayDescriptionsToMap();

    for (final day in _days) {
      String? value = '';
      value = weekdayDescriptionsParsed[day];
      value ??= weekdayDescriptionsParsed[parseDay(day)];

      if (value == null || value == "Fechado") {
        _isClosed[day] = true;
        _schedules[day] = [];
      }else if(value.contains('24h') || value.contains('24 horas')) {
        _isClosed[day] = false;
        _schedules[day] = [TimeRange("00:00", "23:59", is24h: true)];
      } else {
        _isClosed[day] = false;
        _schedules[day] = _parseRanges(value);
      }
    }
  }

  List<TimeRange> _parseRanges(String text) {
    final parts = text.split(",");
    return parts.map((p) {
      final times = p.trim().split("–");
      return TimeRange(times[0].trim(), times[1].trim());
    }).toList();
  }

  String _formatRanges(List<TimeRange> ranges) {
    return ranges.map((r) => "${r.start}–${r.end}").join(", ");
  }

  Future<void> _pickTime(String timeString, Function(String) onPicked) async {
    final hours = timeString.split(':')[0];
    final minutes = timeString.split(':')[1];
    final date = DateTime.now().copyWith(hour: int.parse(hours), minute: int.parse(minutes));
    final TimeOfDay initialTime = TimeOfDay.fromDateTime(date);
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (time != null) {
      final formatted = time.format(context);
      onPicked(formatted);
    }
  }

  void _updateDay(String day) {
    if (_isClosed[day] == true) {
      weekdayDescriptionsParsed[day] = "Fechado";
    } else {
      if(weekdayDescriptionsParsed[day] == null) {
        weekdayDescriptionsParsed[parseDay(day)] = _formatRanges(_schedules[day]!);
      }else {
        weekdayDescriptionsParsed[day] = _formatRanges(_schedules[day]!);
      }
    }

    for (int i = 0; i < widget.weekdayDescriptions.length; i++) {
      final entry = widget.weekdayDescriptions[i];
      final parts = entry.split(":");
      if (parts.isEmpty) continue;

      final currentDay = parts[0].trim();
      final isPortugueseDay = _daysPortuguese.contains(currentDay);
      final value = weekdayDescriptionsParsed[day] == '00:00–23:59' ? 'Atendimento 24 horas' : weekdayDescriptionsParsed[day];

      if (currentDay.toLowerCase() == day.toLowerCase()) {
        widget.weekdayDescriptions[i] = "$day: $value";
        break;
      }
      if (isPortugueseDay && currentDay.toLowerCase() == parseDay(day).toLowerCase()) {
        widget.weekdayDescriptions[i] = "$day: $value";
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final day in _days)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_dayNames[day]!,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        spacing: 4,
                        children: [
                          Text('Aberto:'),
                          Switch(
                            value: !_isClosed[day]!,
                            onChanged: (v) {
                              setState(() {
                                _isClosed[day] = !v;
                                if(_schedules[day]?.isEmpty ?? true) {
                                  _schedules[day]?.add(TimeRange("08:00", "18:00"));
                                }
                                _updateDay(day);
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!_isClosed[day]!)
                    Column(
                      children: [
                        for (int i = 0; i < _schedules[day]!.length; i++)
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: _schedules[day]?.where((t) => t.is24h == true).isNotEmpty ?? false ? null : () => _pickTime(_schedules[day]![i].start, (val) => setState(() {
                                    _schedules[day]![i].start = val;
                                    _updateDay(day);
                                  }),
                                  ),
                                  child: Text(_schedules[day]![i].start),
                                ),
                              ),
                              const Text(" – "),
                              Expanded(
                                child: TextButton(
                                  onPressed: _schedules[day]?.where((t) => t.is24h == true).isNotEmpty ?? false ? null : () => _pickTime(_schedules[day]![i].end, (val) => setState(() {
                                    _schedules[day]![i].end = val;
                                    _updateDay(day);
                                  }),
                                  ),
                                  child: Text(_schedules[day]![i].end),
                                ),
                              ),
                              if(_schedules[day]?.where((t) => t.is24h == true).isEmpty ?? true)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _schedules[day]!.removeAt(i);
                                      if(_schedules[day]!.isEmpty) {
                                        _isClosed[day] = true;
                                      }
                                      _updateDay(day);
                                    });
                                  },
                                )
                            ],
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: _schedules[day]?.where((t) => t.is24h == true).isNotEmpty ?? false ? null : () {
                                setState(() {
                                  _schedules[day]!.add(TimeRange("08:00", "18:00"));
                                  _updateDay(day);
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text("Adicionar horário"),
                            ),
                            Row(
                              spacing: 4,
                              children: [
                                Text('24h'),
                                Switch(
                                  value: _schedules[day]?.where((t) => t.is24h == true).isNotEmpty ?? false,
                                  onChanged: (v) {
                                    if(_schedules[day]?.where((t) => t.is24h == true).isNotEmpty ?? false) {
                                      _schedules[day] = [TimeRange("08:00", "18:00")];
                                    }else {
                                      _schedules[day] = [TimeRange("00:00", "23:59", is24h: true)];
                                    }
                                    _updateDay(day);
                                    setState(() => _schedules);
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class TimeRange {
  String start;
  String end;
  bool? is24h;
  TimeRange(this.start, this.end, {this.is24h});
}