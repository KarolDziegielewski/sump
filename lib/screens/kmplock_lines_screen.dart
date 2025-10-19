import 'package:flutter/material.dart';
import '../data/km_timetables.dart'; // ← tu jest kmTimetables
import 'timetable_details_screen.dart';

class KmplockLinesScreen extends StatelessWidget {
  const KmplockLinesScreen({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

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

    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(filtered.length, (i) {
              final tt = filtered[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
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
                ),
              );
            }),
          ),
        ),
        const _TicketStrip(), // ← nowy pasek „Tu kupisz bilet →”
      ],
    );
  }
}
// ————————————————— Bilety —————————————————

class _TicketStrip extends StatelessWidget {
  const _TicketStrip();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            'Tu kupisz bilet →',
            style: t.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                _TicketLogo(
                  asset: '../assets/images/skycash.png',
                  name: 'SkyCash',
                ),
                _TicketLogo(
                  asset: '../assets/images/mobilet.svg',
                  name: 'moBILET',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketLogo extends StatelessWidget {
  const _TicketLogo({required this.asset, required this.name});
  final String asset;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(asset, height: 18, fit: BoxFit.contain),
        const SizedBox(width: 6),
        Text(
          name,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
