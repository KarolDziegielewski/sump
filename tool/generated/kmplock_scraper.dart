// dart run tool/kmplock_scraper.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';

/// Mapowanie podpisów dni z serwisu na Twoje daySets
const _dayMap = {
  'Powszedni': 'D',
  'Powszednie': 'D',
  'Sobota i niedziela handlowa': 'Sob',
  'Niedziela niehandlowa i święto': 'Nd',
};

/// Prosty model zgodny z Twoim
class TimetableOut {
  final String id;
  final String title;
  final String operatorName;
  final List<String> daySets;
  final List<String> notes;
  final List<StopScheduleOut> stops;
  TimetableOut(this.id, this.title, this.operatorName, this.daySets, this.notes,
      this.stops);
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'operatorName': operatorName,
        'daySets': daySets,
        'notes': notes,
        'stops': stops.map((s) => s.toJson()).toList(),
      };
}

class StopScheduleOut {
  final String stopName;
  final Map<String, List<String>> timesByDay;
  StopScheduleOut(this.stopName, this.timesByDay);
  Map<String, dynamic> toJson() => {
        'stopName': stopName,
        'timesByDay': timesByDay,
      };
}

Future<void> main() async {
  final base = Uri.parse('https://rozklady.kmplock.eu/');
  final indexRes = await http.get(base);
  if (indexRes.statusCode != 200) throw 'Nie mogę pobrać strony głównej';

  final doc = html.parse(indexRes.body);

  // 1) Znajdź linki do wszystkich linii (2,3,4,..., B, N1)
  final lineLinks = <Element>[];
  for (final a in doc.querySelectorAll('a')) {
    final text = a.text.trim();
    final href = a.attributes['href'] ?? '';
    // szukamy wejść w stylu start-XXX.html
    if (href.startsWith('start-') && href.endsWith('.html')) {
      lineLinks.add(a);
    }
  }

  // fallback: jeżeli strona indeksowa już jest "start-...", weź linki z niej
  if (lineLinks.isEmpty) {
    lineLinks.addAll(doc.querySelectorAll('a').where((a) {
      final t = a.text.trim();
      return RegExp(r'^\d+$|^[A-Z]\d*$').hasMatch(t); // np. 2, 33, B, N1
    }));
  }

  print('Znaleziono kandydatów linii: ${lineLinks.length}');

  final out = <Map<String, dynamic>>[];

  for (final a in lineLinks) {
    final lineLabel = a.text.trim(); // np. "2"
    final href = a.attributes['href'];
    if (href == null) continue;
    final lineUrl = Uri.parse(base.resolve(href).toString());

    // 2) Wejdź na stronę linii
    final lineRes = await http.get(lineUrl);
    if (lineRes.statusCode != 200) {
      stderr.writeln('⚠️ Nie mogę pobrać linii $lineLabel: $lineUrl');
      continue;
    }
    final lineDoc = html.parse(lineRes.body);

    // Wydobądź opis trasy i listę przystanków (obie strony kierunków są na tej samej stronie)
    final title = 'Linia $lineLabel – KM Płock';
    final operatorName = 'KM Płock';
    final notes = <String>[];

    // 3) Zbierz wszystkie przystanki klikalne (mają href do rozkładu)
    final stopAnchors = lineDoc.querySelectorAll('a').where((el) {
      final h = el.attributes['href'] ?? '';
      return h.contains('rozklad-') && h.endsWith('.html');
    }).toList();

    // Usuń duplikaty po nazwie
    final seen = <String>{};
    final uniqueStopAnchors = <Element>[];
    for (final el in stopAnchors) {
      final name = el.text.trim();
      if (name.isEmpty) continue;
      if (seen.add(name)) uniqueStopAnchors.add(el);
    }

    final stopsOut = <StopScheduleOut>[];

    // 4) Dla każdego przystanku pobierz widok „tabelaryczny” i czasy
    for (final stopEl in uniqueStopAnchors) {
      final stopName = stopEl.text.trim();
      final stopHref = stopEl.attributes['href']!;
      final stopUrl = base.resolve(stopHref);

      final stopRes = await http.get(stopUrl);
      if (stopRes.statusCode != 200) continue;
      final stopDoc = html.parse(stopRes.body);

      // Przełączniki widoku – znajdź link "tabelaryczny"
      final tabLink = stopDoc.querySelectorAll('a').firstWhere(
            (a) => a.text.toLowerCase().contains('tabelaryczny'),
            orElse: () => Element.tag('a'),
          );
      Uri useUrl = stopUrl;
      if (tabLink.attributes['href'] != null) {
        useUrl = base.resolve(tabLink.attributes['href']!);
      }

      final tabRes = (useUrl.toString() == stopUrl.toString())
          ? stopRes
          : await http.get(useUrl);
      if (tabRes.statusCode != 200) continue;
      final tabDoc = html.parse(tabRes.body);

      // Wydobądź sekcje dni i godziny odjazdów (kolumny pod nagłówkami)
      final timesByDay = <String, List<String>>{};
      // Prosta heurystyka: nagłówki z nazwami dni są tuż nad kolumnami minut/godzin
      // Szukamy bloków, w których występują nagłówki odpowiadające Powszedni/Sobota... itd.
      final dayHeaders = tabDoc.body!.text.contains('Powszedni') ||
          tabDoc.body!.text.contains('Sobota') ||
          tabDoc.body!.text.contains('Niedziela');

      // Minimalny, ale praktyczny parser: znajdujemy wszystkie liczby w formacie HH lub MM i łączymy
      // W wielu miastach SilesiaTransport daje tabelę z godzinami w wierszach i minutami w kolumnach.
      // Tutaj przyjmujemy, że na potrzeby prototypu zbierzemy "HH:MM" bez wyróżniania wariantów literowych.
      final raw = tabDoc.body!.text;

      // Wyizoluj segmenty między nagłówkami dni – na szybko, ale skutecznie.
      final daySections = <String, String>{};
      final names = [
        'Powszedni',
        'Sobota i niedziela handlowa',
        'Niedziela niehandlowa i święto',
      ];
      for (var i = 0; i < names.length; i++) {
        final name = names[i];
        final start = raw.indexOf(name);
        if (start < 0) continue;
        final end = names
            .skip(i + 1)
            .map(raw.indexOf)
            .where((x) => x > start)
            .fold<int>(raw.length, (p, x) => x < p && x >= 0 ? x : p);
        daySections[name] = raw.substring(start, end);
      }

      final reTime = RegExp(r'\b([01]?\d|2[0-3]):[0-5]\d\b');
      daySections.forEach((label, text) {
        final set = _dayMap[label] ?? label;
        final list = reTime.allMatches(text).map((m) => m.group(0)!).toList();
        if (list.isNotEmpty) timesByDay[set] = list;
      });

      // Jeżeli nic nie znaleziono (edge-case), pomiń przystanek
      if (timesByDay.isEmpty) continue;

      stopsOut.add(StopScheduleOut(stopName, timesByDay));
      stdout.writeln(
          '  • ${lineLabel.padLeft(3)} | $stopName: ${timesByDay.values.map((l) => l.length).reduce((a, b) => a + b)} kursów');
    }

    // Wyznacz daySets z kluczy timesByDay wszystkich przystanków
    final daySetsAll = <String>{};
    for (final s in stopsOut) {
      daySetsAll.addAll(s.timesByDay.keys);
    }

    // Złóż w TimetableOut (id zgodne z Twoją konwencją)
    final id = 'kmp-${lineLabel.toLowerCase()}';
    out.add(TimetableOut(
      id,
      'Linia $lineLabel',
      operatorName,
      daySetsAll.toList()..sort(),
      notes,
      stopsOut,
    ).toJson());

    print('✅ Linia $lineLabel gotowa (${stopsOut.length} przystanków).');
  }

  // 5) Zapisz JSON + wygeneruj plik Dart (dla Twojego formatu)
  final outDir = Directory('tool/generated');
  outDir.createSync(recursive: true);
  final jsonPath = '${outDir.path}/kmplock_timetables.json';
  await File(jsonPath)
      .writeAsString(const JsonEncoder.withIndent('  ').convert(out));
  print('💾 Zapisano: $jsonPath');

  // Dodatkowo stwórz lib/data/timetables.dart z listą allTimetables
  final dartBuf = StringBuffer()
    ..writeln("// GENERATED – nie edytuj ręcznie")
    ..writeln("import 'package:flutter/foundation.dart';")
    ..writeln("")
    ..writeln("class Timetable {")
    ..writeln("  final String id;")
    ..writeln("  final String title;")
    ..writeln("  final String operatorName;")
    ..writeln("  final List<String> daySets;")
    ..writeln("  final List<String> notes;")
    ..writeln("  final List<StopSchedule> stops;")
    ..writeln(
        "  const Timetable({required this.id, required this.title, required this.operatorName, required this.daySets, required this.notes, required this.stops,});")
    ..writeln("}")
    ..writeln("class StopSchedule {")
    ..writeln("  final String stopName;")
    ..writeln("  final Map<String, List<String>> timesByDay;")
    ..writeln(
        "  const StopSchedule({required this.stopName, required this.timesByDay});")
    ..writeln("}")
    ..writeln("")
    ..writeln("final List<Timetable> allTimetables = [");

  for (final t in out) {
    final id = t['id'] as String;
    final title = t['title'] as String;
    final op = t['operatorName'] as String;
    final daySets = (t['daySets'] as List).cast<String>();
    final notes = (t['notes'] as List).cast<String>();
    final stops = (t['stops'] as List).cast<Map<String, dynamic>>();

    dartBuf
      ..writeln("  Timetable(")
      ..writeln("    id: ${jsonEncode(id)},")
      ..writeln("    title: ${jsonEncode(title)},")
      ..writeln("    operatorName: ${jsonEncode(op)},")
      ..writeln("    daySets: ${jsonEncode(daySets)},")
      ..writeln("    notes: ${jsonEncode(notes)},")
      ..writeln("    stops: [");
    for (final s in stops) {
      dartBuf
        ..writeln("      StopSchedule(")
        ..writeln("        stopName: ${jsonEncode(s['stopName'])},")
        ..writeln("        timesByDay: ${jsonEncode(s['timesByDay'])},")
        ..writeln("      ),");
    }
    dartBuf
      ..writeln("    ],")
      ..writeln("  ),");
  }
  dartBuf.writeln("];");

  final dartPath = 'lib/data/timetables.dart';
  await File(dartPath).writeAsString(dartBuf.toString());
  print('💾 Zapisano: $dartPath');
}
