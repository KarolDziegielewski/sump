import 'package:flutter/material.dart';
import '../data/timetables.dart';
import 'timetable_details_screen.dart';

class BusTimetableScreen extends StatefulWidget {
  const BusTimetableScreen({super.key});

  @override
  State<BusTimetableScreen> createState() => _BusTimetableScreenState();
}

class _BusTimetableScreenState extends State<BusTimetableScreen> {
  final _qCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 Filtruj istniejące linie po tytule
    final filtered = _query.isEmpty
        ? allTimetables
        : allTimetables
            .where((tt) => tt.title.toLowerCase().contains(_query))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Rozkłady autobusów')),
      body: Column(
        children: [
          // 🔹 Pasek wyszukiwania na górze strony
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _qCtrl,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Szukaj numeru autobusu (np. 19, A, N3)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _qCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _qCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 🔹 Lista rozkładów – filtrowana po tytule
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
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
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: filtered.length,
            ),
          ),
        ],
      ),
    );
  }
}
