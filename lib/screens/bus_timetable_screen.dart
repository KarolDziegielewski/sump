import 'package:flutter/material.dart';
import '../data/timetables.dart';
import 'timetable_details_screen.dart';

class BusTimetableScreen extends StatelessWidget {
  const BusTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rozkłady autobusów')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, i) {
          final tt = allTimetables[i];
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
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: allTimetables.length,
      ),
    );
  }
}
