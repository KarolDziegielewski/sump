import 'package:flutter/material.dart';
import '../models/plan_models.dart';

class ItineraryCard extends StatelessWidget {
  final List<StepItem> itinerary;
  const ItineraryCard({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalMin = itinerary.fold<int>(0, (sum, s) => sum + s.minutes);

    // Czy trasa zawiera odcinek autobusowy?
    final hasBus =
        itinerary.any((s) => s.mode.toLowerCase().startsWith('autobus'));

    // Koszt: bez autobusu — 0 zł; z autobusem — 7,60/3,80
    final double normalFare = hasBus ? 7.60 : 0.0;
    final double reducedFare = hasBus ? 3.80 : 0.0;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nagłówek
            Row(
              children: [
                Icon(Icons.eco_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Najbardziej ekologiczna trasa • ~$totalMin min',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Pasek kosztu – ładne "chip-y"
            _FareRow(
              hasBus: hasBus,
              normalFare: normalFare,
              reducedFare: reducedFare,
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // Kroki
            ...itinerary.map((s) => ListTile(
                  dense: true,
                  leading: Icon(s.icon, color: theme.colorScheme.primary),
                  title: Text(
                    '${s.mode} • ${_fmtDist(s.distanceMeters)} • ok. ${s.minutes} min',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  String _fmtDist(double meters) => (meters >= 1000)
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.toStringAsFixed(0)} m';

  String _pln(double value) {
    // format PL: przecinek jako separator dziesiętny, 2 miejsca
    final s = value.toStringAsFixed(2).replaceAll('.', ',');
    return '$s zł';
  }
}

/// Pasek kosztów z ładnymi chipami
class _FareRow extends StatelessWidget {
  final bool hasBus;
  final double normalFare;
  final double reducedFare;

  const _FareRow({
    required this.hasBus,
    required this.normalFare,
    required this.reducedFare,
  });

  String _pln(double v) => '${v.toStringAsFixed(2).replaceAll('.', ',')} zł';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!hasBus) {
      // Tylko pieszo/rower → koszt 0,00 zł (jeden chip)
      return Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: -6,
          children: [
            Chip(
              avatar: const Icon(Icons.currency_exchange, size: 18),
              label: Text(
                'Koszt: ${_pln(0)}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    // Z autobusem → pokazujemy normalny i ulgowy
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: -6,
        children: [
          Chip(
            avatar: const Icon(Icons.attach_money, size: 18),
            label: Text(
              'Normalny: ${_pln(normalFare)}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Chip(
            avatar: const Icon(Icons.percent, size: 18),
            label: Text(
              'Ulgowy: ${_pln(reducedFare)}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
