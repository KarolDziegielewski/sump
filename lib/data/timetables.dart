import 'package:flutter/material.dart';

class Timetable {
  final String id;
  final String title;
  final String operatorName;
  final List<String> daySets; // np. ['D','S','Sob','Nd']
  final List<String> notes;
  final List<StopSchedule> stops;

  const Timetable({
    required this.id,
    required this.title,
    required this.operatorName,
    required this.daySets,
    required this.notes,
    required this.stops,
  });
}

class StopSchedule {
  final String stopName;
  final Map<String, List<String>> timesByDay;
  const StopSchedule({required this.stopName, required this.timesByDay});
}

// ========== 1) Linia 282: Kosino – Radzanowo – Płock ==========
final _ttLinia282 = Timetable(
  id: 'linia-282-kosino-radzanowo-plock',
  title: 'Linia 282: Kosino – Radzanowo – Płock',
  operatorName: 'Powiat / Gmina (prototyp)',
  daySets: const ['D', 'S', 'Sob'],
  notes: const [
    'D – dni robocze',
    'S – dni szkolne',
    'Sob – soboty',
    'Uwaga: czasy przybliżone dla prototypu',
  ],
  stops: const [
    StopSchedule(stopName: 'Kosino II', timesByDay: {
      'D': ['04:46', '06:56', '12:20', '15:28', '17:28', '20:28'],
      'S': ['05:02', '06:36', '07:18', '13:08', '15:18'],
      'Sob': ['06:10', '08:10', '12:40', '16:10', '18:10'],
    }),
    StopSchedule(stopName: 'Radzanowo Szkoła', timesByDay: {
      'D': ['05:06', '07:04', '10:08', '13:00', '15:36', '17:36', '20:36'],
      'S': ['05:20', '06:52', '07:34', '13:24', '15:34'],
      'Sob': ['06:24', '08:24', '12:54', '16:24', '18:24'],
    }),
    StopSchedule(stopName: 'Rogozino Mazowiecka', timesByDay: {
      'D': ['05:32', '07:30', '10:34', '13:26', '16:02', '18:02', '21:02'],
      'S': ['05:44', '07:12', '10:18', '13:46', '16:12'],
      'Sob': ['06:40', '08:40', '13:10', '16:40', '18:40'],
    }),
    StopSchedule(stopName: 'Boryszewo III', timesByDay: {
      'D': ['05:47', '07:45', '10:49', '13:41', '16:17', '18:17', '21:17'],
      'S': ['05:58', '07:26', '10:32', '13:58', '16:26'],
      'Sob': ['06:52', '08:52', '13:22', '16:52', '18:52'],
    }),
    StopSchedule(stopName: 'Otolińska WORD', timesByDay: {
      'D': ['05:52', '07:50', '10:54', '13:46', '16:22', '18:22', '21:22'],
      'S': ['06:04', '07:32', '10:38', '14:04', '16:32'],
      'Sob': ['06:58', '08:58', '13:28', '16:58', '18:58'],
    }),
    StopSchedule(stopName: 'Płock, Spacerowa', timesByDay: {
      'D': ['06:05', '08:03', '11:07', '13:59', '16:35', '18:35', '21:35'],
      'S': ['06:16', '07:44', '10:50', '14:16', '16:44'],
      'Sob': ['07:10', '09:10', '13:40', '17:10', '19:10'],
    }),
  ],
);

// ========== 2) Drobin – Płock (zestaw A) ==========
final _ttDrobinPlockA = Timetable(
  id: 'drobin-plock-a',
  title: 'Drobin – Płock (wariant A przez Rogotwórsk)',
  operatorName: 'Przewoźnik lokalny',
  daySets: const ['D', 'Sob'],
  notes: const ['Przybliżone godziny – prototyp UX'],
  stops: const [
    StopSchedule(stopName: 'Drobin, Dworzec', timesByDay: {
      'D': ['05:45', '06:55', '11:45', '14:55', '17:15'],
      'Sob': ['06:20', '09:20', '12:50', '16:20'],
    }),
    StopSchedule(stopName: 'Kuczbork / Rogotwórsk', timesByDay: {
      'D': ['06:05', '07:15', '12:05', '15:15', '17:35'],
      'Sob': ['06:40', '09:40', '13:10', '16:40'],
    }),
    StopSchedule(stopName: 'Bielsk', timesByDay: {
      'D': ['06:30', '07:40', '12:30', '15:40', '18:00'],
      'Sob': ['07:05', '10:05', '13:35', '17:05'],
    }),
    StopSchedule(stopName: 'Płock, Dworzec', timesByDay: {
      'D': ['06:55', '08:05', '12:55', '16:05', '18:25'],
      'Sob': ['07:28', '10:28', '13:58', '17:28'],
    }),
  ],
);

// ========== 3) Drobin – Płock (zestaw B) ==========
final _ttDrobinPlockB = Timetable(
  id: 'drobin-plock-b',
  title: 'Drobin – Płock (wariant B przez Radzanowo)',
  operatorName: 'Przewoźnik lokalny',
  daySets: const ['D', 'S'],
  notes: const ['S – dni szkolne; czasy przybliżone'],
  stops: const [
    StopSchedule(stopName: 'Drobin, Rynek', timesByDay: {
      'D': ['05:20', '06:40', '10:20', '14:10', '16:40'],
      'S': ['06:05', '07:10', '13:30', '15:10'],
    }),
    StopSchedule(stopName: 'Radzanowo', timesByDay: {
      'D': ['05:55', '07:15', '10:55', '14:45', '17:15'],
      'S': ['06:35', '07:40', '14:00', '15:40'],
    }),
    StopSchedule(stopName: 'Rogozino', timesByDay: {
      'D': ['06:10', '07:30', '11:10', '15:00', '17:30'],
      'S': ['06:50', '07:55', '14:15', '15:55'],
    }),
    StopSchedule(stopName: 'Płock, KM Płaska', timesByDay: {
      'D': ['06:30', '07:50', '11:30', '15:20', '17:50'],
      'S': ['07:08', '08:13', '14:33', '16:13'],
    }),
  ],
);

// ========== 4) Płock → Warszawa PKiN ==========
final _ttPlockWarszawa = Timetable(
  id: 'plock-warszawa-pkin',
  title: 'Płock → Warszawa PKiN',
  operatorName: 'Tumbus Sp. z o.o.',
  daySets: const ['D', 'a'],
  notes: const [
    'D – kursy w dni robocze',
    'a – kursy wybrane (wg oryginału); czasy przybliżone',
  ],
  stops: const [
    StopSchedule(stopName: 'Płock, KM Płaska / Dworzec', timesByDay: {
      'D': ['05:20', '11:20', '18:08'],
      'a': ['06:30', '14:00'],
    }),
    StopSchedule(stopName: 'Czerwińsk nad Wisłą', timesByDay: {
      'D': ['06:52', '12:52', '19:40'],
      'a': ['07:55', '15:25'],
    }),
    StopSchedule(stopName: 'Warszawa PKiN', timesByDay: {
      'D': ['07:50', '13:50', '20:38'],
      'a': ['08:50', '16:20'],
    }),
  ],
);

// ========== 5) Warszawa PKiN → Płock ==========
final _ttWarszawaPlock = Timetable(
  id: 'warszawa-pkin-plock',
  title: 'Warszawa PKiN → Płock',
  operatorName: 'Tumbus Sp. z o.o.',
  daySets: const ['D', 'a'],
  notes: const ['Czasy przybliżone – prototyp'],
  stops: const [
    StopSchedule(stopName: 'Warszawa PKiN', timesByDay: {
      'D': ['08:15', '14:40', '21:00'],
      'a': ['09:30', '16:55'],
    }),
    StopSchedule(stopName: 'Czerwińsk nad Wisłą', timesByDay: {
      'D': ['09:13', '15:38', '21:58'],
      'a': ['10:28', '17:53'],
    }),
    StopSchedule(stopName: 'Płock, KM Płaska / Dworzec', timesByDay: {
      'D': ['10:05', '16:30', '22:50'],
      'a': ['11:20', '18:45'],
    }),
  ],
);

// ========== 6) RZŁ 274: Sierpc – Zawidz – Słupia – Płock ==========
final _ttRzl274 = Timetable(
  id: 'rzl-274-sierpc-zawidz-slupia-plock',
  title: 'RZŁ 274: Sierpc – Zawidz – Słupia – Płock',
  operatorName: 'F.U. „Jantar”',
  daySets: const ['D'],
  notes: const ['D – dni robocze; czasy przybliżone wg tabeli'],
  stops: const [
    StopSchedule(stopName: 'Sierpc, Dworzec', timesByDay: {
      'D': ['08:10', '12:10', '14:40'],
    }),
    StopSchedule(stopName: 'Zawidz', timesByDay: {
      'D': ['08:31', '12:31', '15:01'],
    }),
    StopSchedule(stopName: 'Słupia', timesByDay: {
      'D': ['08:44', '12:44', '15:14'],
    }),
    StopSchedule(stopName: 'Bielsk', timesByDay: {
      'D': ['09:02', '13:02', '15:32'],
    }),
    StopSchedule(stopName: 'Żerniki / Borowno / Brwilno*', timesByDay: {
      'D': ['09:10', '13:10', '15:40'],
    }),
    StopSchedule(stopName: 'Płock, Dworzec', timesByDay: {
      'D': ['09:20', '13:20', '15:50'],
    }),
  ],
);

// ========== 7) Drobin – Płock (zestaw C, „szkolny”) ==========
final _ttDrobinPlockC = Timetable(
  id: 'drobin-plock-c',
  title: 'Drobin – Płock (kursy szkolne)',
  operatorName: 'Przewoźnik lokalny',
  daySets: const ['S'],
  notes: const ['S – tylko dni nauki szkolnej; czasy orientacyjne'],
  stops: const [
    StopSchedule(stopName: 'Drobin, ZS', timesByDay: {
      'S': ['06:55', '13:25', '15:25'],
    }),
    StopSchedule(stopName: 'Bielsk', timesByDay: {
      'S': ['07:18', '13:48', '15:48'],
    }),
    StopSchedule(stopName: 'Płock, Jachowicza 40', timesByDay: {
      'S': ['07:45', '14:15', '16:15'],
    }),
  ],
);

// ========== 8) Zestaw „techniczny” (zestawienie/strona zbiorcza) ==========
final _ttZestawienieTechniczne = Timetable(
  id: 'zestawienie-techniczne',
  title: 'Zestawienie linii (strona zbiorcza)',
  operatorName: 'UM Płock / prototyp',
  daySets: const ['D'],
  notes: const ['Makieta oparta o skan tabelaryczny; orientacyjne czasy'],
  stops: const [
    StopSchedule(stopName: 'Linia 1 – odc. przykładowy', timesByDay: {
      'D': ['06:00', '07:00', '12:00', '15:00', '18:00'],
    }),
    StopSchedule(stopName: 'Linia 2 – odc. przykładowy', timesByDay: {
      'D': ['06:15', '07:15', '12:15', '15:15', '18:15'],
    }),
  ],
);

// Zbiorcza lista do aplikacji
final List<Timetable> allTimetables = [
  _ttLinia282,
  _ttDrobinPlockA,
  _ttDrobinPlockB,
  _ttPlockWarszawa,
  _ttWarszawaPlock,
  _ttRzl274,
  _ttDrobinPlockC,
  _ttZestawienieTechniczne,
];
