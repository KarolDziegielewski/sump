import 'package:flutter/material.dart';
import '../data/timetables.dart';
import 'timetable_details_screen.dart';

class MunicipalLinesScreen extends StatelessWidget {
  const MunicipalLinesScreen({super.key, required this.query});
  final String query;

  bool _isKmplock(String op) {
    final o = op.toLowerCase();
    return o.contains('kmpłock') ||
        o.contains('km płock') ||
        o.contains('km plock');
  }

  @override
  Widget build(BuildContext context) {
    final others = allTimetables.where((tt) => !_isKmplock(tt.operatorName));
    final q = query.trim().toLowerCase();

    final filtered = q.isEmpty
        ? others.toList()
        : others
            .where((tt) =>
                tt.title.toLowerCase().contains(q) ||
                tt.operatorName.toLowerCase().contains(q))
            .toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Brak wyników w pozostałych liniach.'));
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
                  color: Theme.of(context).colorScheme.outlineVariant),
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
