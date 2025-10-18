import 'package:flutter/material.dart';

class BikeRouteScreen extends StatefulWidget {
  const BikeRouteScreen({super.key});

  @override
  State<BikeRouteScreen> createState() => _BikeRouteScreenState();
}

class _BikeRouteScreenState extends State<BikeRouteScreen> {
  double _maxDistanceKm = 10;

  // Przykładowe trasy — podłączysz do warstw KML.
  final List<Map<String, dynamic>> _routes = [
    {'name': 'Bulwary Wiślane', 'distance': 5.2, 'surface': 'asfalt'},
    {'name': 'Soczewka — Zalew', 'distance': 12.4, 'surface': 'mieszana'},
    {'name': 'Tumskie — Park', 'distance': 8.1, 'surface': 'asfalt'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered =
        _routes.where((r) => r['distance'] <= _maxDistanceKm).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rower — trasy'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune),
                        const SizedBox(width: 8),
                        Text(
                          'Filtr: maks. dystans ${_maxDistanceKm.toStringAsFixed(0)} km',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Slider(
                      value: _maxDistanceKm,
                      min: 3,
                      max: 30,
                      divisions: 27,
                      label: '${_maxDistanceKm.toStringAsFixed(0)} km',
                      onChanged: (v) => setState(() => _maxDistanceKm = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final r = filtered[i];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.pedal_bike),
                    title: Text(r['name']),
                    subtitle: Text(
                      'Dystans: ${r['distance']} km • Nawierzchnia: ${r['surface']}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: podgląd trasy na mapie + profil wysokości
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.map_outlined),
        label: const Text('Pokaż na mapie'),
        onPressed: () {
          // TODO: otwarcie mapy z warstwami KML tras rowerowych
        },
      ),
    );
  }
}
