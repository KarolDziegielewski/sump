import 'package:flutter/material.dart';
import '../data/km_timetables.dart'; // ⬅️ nowy import
import 'timetable_details_screen.dart';

class KmplockLinesScreen extends StatelessWidget {
  const KmplockLinesScreen({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    // Filtruj po numerze linii lub nazwie operatora
    final filtered = q.isEmpty
        ? kmTimetables
        : kmTimetables
            .where((tt) =>
                tt.title.toLowerCase().contains(q) ||
                tt.operatorName.toLowerCase().contains(q))
            .toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Brak wyników dla KM Płock.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final tt = filtered[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TimetableDetailsScreen(timetable: tt),
            ));
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.directions_bus),
              title: Text(tt.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(tt.operatorName),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        );
      },
    );
  }
}
