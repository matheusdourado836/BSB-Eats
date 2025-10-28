import 'package:flutter/material.dart';

/// Representa um intervalo [start,end) em minutos desde 00:00.
class TimeRange {
  final int start; // min desde 00:00
  final int end;   // min desde 00:00 (end é exclusivo)
  const TimeRange(this.start, this.end);
  bool contains(int minute) => start <= minute && minute < end;
  int difference(int minute) => end - minute;
}

/// Horários semanais normalizados por dia da semana (1=Mon ... 7=Sun como em DateTime.weekday)
class WeeklyOpeningHours {
  final Map<int, List<TimeRange>> byWeekday;
  const WeeklyOpeningHours(this.byWeekday);

  /// Cria a partir de `weekdayDescriptions` do Google Places.
  /// Ex.: "Monday: 11:00 AM – 12:00 AM", "sexta-feira: 11:00–00:00", etc.
  factory WeeklyOpeningHours.fromWeekdayDescriptions(List<String> lines) {
    final map = <int, List<TimeRange>>{
      for (var d = 1; d <= 7; d++) d: <TimeRange>[],
    };

    int? weekdayFromLabel(String s) {
      final t = _normalize(s);
      // mapeia vários rótulos possíveis (pt/en/abreviações)
      const wd = <int, List<String>>{
        1: ['monday','mon','segunda','seg','segunda-feira'],
        2: ['tuesday','tue','terça','ter','terca','terça-feira','terca-feira'],
        3: ['wednesday','wed','quarta','qua','quarta-feira'],
        4: ['thursday','thu','quinta','qui','quinta-feira'],
        5: ['friday','fri','sexta','sex','sexta-feira'],
        6: ['saturday','sat','sabado','sábado','sab','sábado-feira'],
        7: ['sunday','sun','domingo','dom'],
      };
      for (final e in wd.entries) {
        if (e.value.any((k) => t.startsWith(k))) return e.key;
      }
      return null;
    }

    int parseTimeToMinutes(String raw) {
      var s = _normalize(raw).replaceAll('.', ':').trim();
      if (s.contains('midnight')) return 0;
      if (s.contains('noon')) return 12 * 60;

      final ampmMatch = RegExp(r'\b(am|pm)\b', caseSensitive: false).firstMatch(s);
      final hasAmPm = ampmMatch != null;

      final m = RegExp(r'(\d{1,2})(?::(\d{2}))?').firstMatch(s);
      if (m == null) return 0;
      var h = int.parse(m.group(1)!);
      var min = int.tryParse(m.group(2) ?? '0') ?? 0;

      if (hasAmPm) {
        final ampm = ampmMatch.group(1)!.toLowerCase();
        if (ampm == 'am') {
          if (h == 12) h = 0;
        } else {
          if (h != 12) h += 12;
        }
      }
      // Em 24h já está certo (ex.: "00:30", "23:15")
      return h * 60 + min;
    }

    // processa cada linha "Dia: intervalos"
    for (final line in lines) {
      final parts = line.split(':');
      if (parts.length < 2) continue;

      final dayLabel = parts.first;
      final day = weekdayFromLabel(dayLabel);
      if (day == null) continue;

      final right = parts.sublist(1).join(':').trim(); // garante que ":" em horas não quebre
      final lower = _normalize(right);

      if (lower.contains('closed') || lower.contains('fechado')) {
        continue; // sem intervalos nesse dia
      }
      if (lower.contains('24 hours') || lower.contains('aberto 24 horas') || lower == '24h' || lower == '24 horas' || lower == 'Atendimento 24 horas') {
        map[day]!.add(const TimeRange(0, 24 * 60));
        continue;
      }

      // Pode haver múltiplos intervalos separados por vírgula
      final intervals = right.split(',');
      for (var interval in intervals) {
        final dashSplit = interval.split(RegExp(r'–|-')); // aceita "–" (en dash) ou "-"
        if (dashSplit.length < 2) continue;
        final startStr = dashSplit[0].trim();
        final endStr = dashSplit[1].trim();

        final start = parseTimeToMinutes(startStr);
        final end = parseTimeToMinutes(endStr);

        if (start == end) continue; // ignora estranhos

        if (end > start) {
          // intervalo normal no mesmo dia
          map[day]!.add(TimeRange(start, end));
        } else {
          // intervalo atravessa a meia-noite: divide em [start, 24:00) + [00:00, end) no próximo dia
          map[day]!.add(TimeRange(start, 24 * 60));
          final nextDay = day == 7 ? 1 : day + 1;
          map[nextDay]!.add(TimeRange(0, end));
        }
      }
    }

    // opcional: ordenar e mesclar sobreposições
    for (final d in map.keys) {
      map[d]!.sort((a, b) => a.start.compareTo(b.start));
    }

    return WeeklyOpeningHours(map);
  }

  /// Retorna true se está aberto em [moment] (padrão: agora, horário local).
  bool isOpenNow({DateTime? moment}) {
    final now = moment?.toLocal() ?? DateTime.now();
    final day = now.weekday; // 1..7
    final minutes = now.hour * 60 + now.minute;
    final ranges = byWeekday[day] ?? const <TimeRange>[];
    if (ranges.isEmpty) return true;
    return ranges.any((r) => r.contains(minutes));
  }
}

/// Utilitário simples para normalizar strings (minúsculas + remover acentos básicos)
String _normalize(String s) {
  final lower = s.toLowerCase().trim();
  const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const to   = 'aaaaaeeeeiiiiooooouuuuc';
  var out = StringBuffer();
  for (final ch in lower.characters) {
    final idx = from.indexOf(ch);
    out.write(idx >= 0 ? to[idx] : ch);
  }
  return out.toString();
}

class DaySchedule {
  final String day; // ex: "monday"
  bool isClosed;
  bool isOpen24h;
  List<TimeGap> intervals;

  DaySchedule({
    required this.day,
    this.isClosed = false,
    this.isOpen24h = false,
    List<TimeGap>? intervals,
  }) : intervals = intervals ?? [];
}

class TimeGap {
  TimeOfDay start;
  TimeOfDay end;

  TimeGap(this.start, this.end);
}