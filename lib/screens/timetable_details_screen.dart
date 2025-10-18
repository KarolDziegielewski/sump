import 'package:flutter/material.dart';
import '../data/timetables.dart'; // ← źródło typu Timetable/StopSchedule

class TimetableDetailsScreen extends StatefulWidget {
  final Timetable timetable;
  const TimetableDetailsScreen({super.key, required this.timetable});
  // ...reszta pliku bez zmian

  @override
  State<TimetableDetailsScreen> createState() => _TimetableDetailsScreenState();
}

class _TimetableDetailsScreenState extends State<TimetableDetailsScreen> {
  late String _currentDaySet;

  @override
  void initState() {
    super.initState();
    _currentDaySet = widget.timetable.daySets.first;
  }

  @override
  Widget build(BuildContext context) {
    final tt = widget.timetable;
    return Scaffold(
      appBar: AppBar(title: Text(tt.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Przełącznik dni
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: tt.daySets.map((d) {
                final sel = d == _currentDaySet;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(d),
                    selected: sel,
                    onSelected: (_) => setState(() => _currentDaySet = d),
                  ),
                );
              }).toList(),
            ),
          ),

          // Tabela godzin
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(5)
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Przystanek',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Godziny',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    ...tt.stops.map((s) {
                      final times = s.timesByDay[_currentDaySet] ?? const [];
                      final timesText = times.isEmpty ? '—' : times.join('   ');
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(s.stopName),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(timesText),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Notatki/oznaczenia
          if (tt.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                tt.notes.map((n) => '• $n').join('\n'),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
