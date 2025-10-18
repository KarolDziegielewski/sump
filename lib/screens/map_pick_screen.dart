import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/plan_models.dart';
import '../services/kml_loader.dart';
import '../services/eco_planner.dart' as eco; // alias dla pewności importu
import '../widgets/itinerary_card.dart';

class MapPickScreen extends StatefulWidget {
  const MapPickScreen({super.key});

  @override
  State<MapPickScreen> createState() => _MapPickScreenState();
}

class _MapPickScreenState extends State<MapPickScreen> {
  static const LatLng _plockCenter = LatLng(52.5468, 19.7064);

  final MapController _map = MapController();
  LatLng? _start;
  LatLng? _end;

  // Dane
  Map<String, List<LatLng>> _busLines = {};
  List<LatLng> _bikeStations = [];
  List<LatLng> _busStopsExtra = []; // ⬅️ NOWE

  // Wynik
  List<Polyline> _routeLines = [];
  List<Marker> _routeMarkers = [];
  List<StepItem> _itinerary = []; // ✅ właściwy typ

  bool _loading = true;
  String? _error;

  // Loader i planer
  final _loader = KmlLoader();
  final eco.EcoPlanner _planner = eco.EcoPlanner(); // ✅ pewny typ

  @override
  void initState() {
    super.initState();
    _loadKml();
  }

  Future<void> _loadKml() async {
    setState(() => _loading = true);
    try {
      final data = await _loader.loadAll();
      setState(() {
        _busLines = data.busLines;
        _bikeStations = data.bikeStations;
        _busStopsExtra = data.allBusStopsExtra;
        _loading = false;
        _error = (_busLines.isEmpty && _bikeStations.isEmpty)
            ? 'Brak danych KML w assets/data/ i podkatalogach.'
            : null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Błąd wczytywania KML: $e';
      });
    }
    print(
        'Załadowano: linie=${_busLines.length}, stacje=${_bikeStations.length}');
  }

  // 🔹 Planowanie asynchroniczne (OSRM -> ulice)
  Future<void> _replan() async {
    if (_start == null || _end == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final plan = await _planner.plan(
        start: _start!,
        end: _end!,
        bikeStations: _bikeStations,
        busLines: _busLines,
      );

      setState(() {
        _routeLines = plan.polylines;
        _routeMarkers = plan.markers;
        _itinerary = plan.steps; // ✅ List<StepItem>
        _loading = false;
      });

      _fitToBounds(plan.allPoints());
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Błąd routingu: $e';
      });
    }
  }

  void _clear() {
    setState(() {
      _start = null;
      _end = null;
      _routeLines = [];
      _routeMarkers = [];
      _itinerary = [];
    });
  }

  void _fitToBounds(List<LatLng> pts) {
    if (pts.isEmpty) return;
    double? minLat, maxLat, minLng, maxLng;
    for (final p in pts) {
      minLat = (minLat == null) ? p.latitude : math.min(minLat, p.latitude);
      maxLat = (maxLat == null) ? p.latitude : math.max(maxLat, p.latitude);
      minLng = (minLng == null) ? p.longitude : math.min(minLng, p.longitude);
      maxLng = (maxLng == null) ? p.longitude : math.max(maxLng, p.longitude);
    }
    final bounds =
        LatLngBounds(LatLng(minLat!, minLng!), LatLng(maxLat!, maxLng!));
    final fit =
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60));
    final camera = fit.fit(_map.camera);
    _map.move(camera.center, camera.zoom);
  }

  void _confirm() {
    if (_start != null && _end != null) {
      Navigator.pop(context, {'start': _start, 'end': _end});
    }
  }

  // ✅ poprawna sygnatura dla flutter_map v5/6
  void _onTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      if (_start == null) {
        _start = latLng;
      } else if (_end == null) {
        _end = latLng;
      } else {
        _start = latLng;
        _end = null;
        _routeLines.clear();
        _routeMarkers.clear();
        _itinerary.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseLayers = <Widget>[
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'pl.twoja.aplikacja',
      ),
      if (_busLines.isNotEmpty)
        MarkerLayer(
          markers: _busLines.values
              .expand((stops) => stops)
              .map((p) => Marker(
                    point: p,
                    width: 16,
                    height: 16,
                    child: const Icon(Icons.directions_bus,
                        size: 14, color: Colors.blueGrey),
                  ))
              .toList(),
        ),
      if (_bikeStations.isNotEmpty)
        MarkerLayer(
          markers: _bikeStations
              .map((p) => Marker(
                    point: p,
                    width: 18,
                    height: 18,
                    child: const Icon(Icons.pedal_bike,
                        size: 16, color: Colors.orange),
                  ))
              .toList(),
        ),
      if (_routeLines.isNotEmpty) PolylineLayer(polylines: _routeLines),
      MarkerLayer(
        markers: _routeMarkers.isNotEmpty ? _routeMarkers : _baseMarkers(),
      ),
      const RichAttributionWidget(
        attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
      ),
      // …warstwa linii autobusowych z _busLines…

      if (_busStopsExtra.isNotEmpty)
        MarkerLayer(
          markers: _busStopsExtra
              .map((p) => Marker(
                    point: p,
                    width: 12,
                    height: 12,
                    child: const Icon(
                      Icons.directions_bus, // możesz dać inny, np. Icons.circle
                      size: 10,
                      color: Colors.blueGrey, // delikatniej niż główne
                    ),
                  ))
              .toList(),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planer A → B (eko priorytet)'),
        actions: [
          IconButton(
            onPressed: _clear,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Wyczyść',
          ),
          IconButton(
            onPressed: (_start != null && _end != null) ? _replan : null,
            icon: const Icon(Icons.route),
            tooltip: 'Przelicz trasę',
          ),
          IconButton(
            onPressed: _loadKml,
            icon: const Icon(Icons.refresh),
            tooltip: 'Przeładuj KML',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _plockCenter,
              initialZoom: 13,
              onTap: _onTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: baseLayers,
          ),
          if (_loading)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null && !_loading)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ),
          if (_itinerary.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: ItineraryCard(itinerary: _itinerary),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            onPressed: (_start != null && _end != null) ? _confirm : null,
            icon: const Icon(Icons.check),
            label: const Text('Zatwierdź punkty A i B'),
          ),
        ),
      ),
    );
  }

  List<Marker> _baseMarkers() => [
        if (_start != null)
          Marker(
            point: _start!,
            width: 40,
            height: 40,
            child: const Icon(Icons.flag, size: 36),
          ),
        if (_end != null)
          Marker(
            point: _end!,
            width: 40,
            height: 40,
            child: const Icon(Icons.place, size: 36),
          ),
      ];
}
