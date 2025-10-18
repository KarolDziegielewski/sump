import 'timetables.dart'; // ten sam Timetable / StopSchedule

final List<Timetable> kmTimetables = [
  Timetable(
    id: 'km-plock-1',
    title: 'Linia 1',
    operatorName: 'KM Płock',
    daySets: const ['Robocze', 'Sobota', 'Niedziela'],
    notes: const [],
    stops: const [
      StopSchedule(stopName: 'Dworzec Kolejowy', timesByDay: {
        'Robocze': ['05:00', '05:30', '06:00'],
        'Sobota': ['06:00', '06:30'],
        'Niedziela': ['06:30', '07:00'],
      }),
      StopSchedule(stopName: 'Podolszyce', timesByDay: {
        'Robocze': ['05:25', '05:55', '06:25'],
        'Sobota': ['06:25', '06:55'],
        'Niedziela': ['06:55', '07:25'],
      }),
    ],
  ),
  Timetable(
    id: 'km-plock-3',
    title: 'Linia 3',
    operatorName: 'KM Płock',
    daySets: const ['Robocze', 'Sobota', 'Niedziela'],
    notes: const [],
    stops: const [
      StopSchedule(stopName: 'Imielnica', timesByDay: {
        'Robocze': ['05:10', '05:40', '06:10'],
        'Sobota': ['06:10', '06:40'],
        'Niedziela': ['06:40', '07:10'],
      }),
      StopSchedule(stopName: 'Dworzec Kolejowy', timesByDay: {
        'Robocze': ['05:35', '06:05', '06:35'],
        'Sobota': ['06:35', '07:05'],
        'Niedziela': ['07:05', '07:35'],
      }),
    ],
  ),
  Timetable(
    id: 'km-plock-19',
    title: 'Linia 19',
    operatorName: 'KM Płock',
    daySets: const ['Robocze', 'Sobota', 'Niedziela'],
    notes: const [],
    stops: const [
      StopSchedule(stopName: 'Borowiczki', timesByDay: {
        'Robocze': ['05:20', '05:50', '06:20'],
        'Sobota': ['06:20', '06:50'],
        'Niedziela': ['06:50', '07:20'],
      }),
      StopSchedule(stopName: 'Podolszyce', timesByDay: {
        'Robocze': ['05:35', '06:05', '06:35'],
        'Sobota': ['06:35', '07:05'],
        'Niedziela': ['07:05', '07:35'],
      }),
    ],
  ),
  Timetable(
    id: 'km-plock-n3',
    title: 'Linia N3 (nocna)',
    operatorName: 'KM Płock',
    daySets: const ['Noc'],
    notes: const ['Kursy nocne – przykładowe godziny'],
    stops: const [
      StopSchedule(stopName: 'Dworzec Kolejowy', timesByDay: {
        'Noc': ['23:15', '00:15', '01:15', '02:15'],
      }),
      StopSchedule(stopName: 'Podolszyce', timesByDay: {
        'Noc': ['23:35', '00:35', '01:35', '02:35'],
      }),
    ],
  ),
];
