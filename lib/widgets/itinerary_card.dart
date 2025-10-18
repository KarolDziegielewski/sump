import 'package:flutter/material.dart';
import '../models/plan_models.dart';

class ItineraryCard extends StatelessWidget {
  final List<StepItem> itinerary;
  const ItineraryCard({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    final totalMin = itinerary.fold<int>(0, (sum, s) => sum + s.minutes);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Icon(Icons.eco_outlined),
              const SizedBox(width: 8),
              Text('Najbardziej ekologiczna trasa • ~${totalMin} min',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            ...itinerary.map((s) => ListTile(
                  dense: true,
                  leading: Icon(s.icon),
                  title: Text(
                      '${s.mode} • ${_fmtDist(s.distanceMeters)} • ok. ${s.minutes} min'),
                )),
            const SizedBox(height: 4),
            Text(
              'Prototyp: odcinki autobus/rower łączone „po prostej”.',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDist(double meters) => (meters >= 1000)
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.toStringAsFixed(0)} m';
}
