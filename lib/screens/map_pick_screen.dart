import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart' as xml;

class MapPickScreen extends StatefulWidget {
  const MapPickScreen({super.key});

  @override
  State<MapPickScreen> createState() => _MapPickScreenState();
}

class _MapPickScreenState extends State<MapPickScreen> {
  // Ścieżki KML z Twojej wiadomości:
  static const _kmlBusStops = 'assets/data/sump/highway_busstop_sump_osm.kml';
  static const _kmlBikeStations =
      'assets/data/PRM stacje roweru miejskiego.kml';

  final MapController _map = MapController();
  LatLng? _start;
  LatLng? _end;

  // Dane z KML:
  List<LatLng> _busStops = [];
  List<LatLng> _bikeStations = [];

  // Wynik planowania:
  List<Polyline> _routeLines = [];
  List<Marker> _routeMarkers = [];
  List<_StepItem> _itinerary = [];

  bool _loading = true;
  String? _error;

  static const LatLng _plockCenter = LatLng(52.5468, 19.7064);

  @override
  void initState() {
    super.initState();
    _loadKmls();
  }

  Future<void> _loadKmls() async {
    try {
      final busKml = await rootBundle.loadString(_kmlBusStops);
      final bikeKml = await rootBundle.loadString(_kmlBikeStations);

      _busStops = _parseKmlPoints(busKml);
      _bikeStations = _parseKmlPoints(bikeKml);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = (_busStops.isEmpty && _bikeStations.isEmpty)
            ? 'Nie znaleziono punktów w KML.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Błąd wczytywania KML: $e';
      });
    }
  }

  // Parser KML -> listy punktów (Placemark > Point > coordinates: lon,lat[,alt])
  List<LatLng> _parseKmlPoints(String kml) {
    final doc = xml.XmlDocument.parse(kml);
    final placemarks = doc.findAllElements('Placemark');
    final points = <LatLng>[];

    for (final pm in placemarks) {
      final point = pm.findAllElements('Point').firstOrNull;
      if (point == null) continue;
      final coordsText = point.getElement('coordinates')?.innerText.trim();
      if (coordsText == null || coordsText.isEmpty) continue;

      // weź pierwszą parę "lon,lat"
      final firstPair = coordsText
          .split(RegExp(r'\s+'))
          .firstWhere((e) => e.contains(','), orElse: () => coordsText);
      final parts = firstPair.split(',');
      if (parts.length < 2) continue;

      final lon = double.tryParse(parts[0]);
      final lat = double.tryParse(parts[1]);
      if (lat == null || lon == null) continue;

      points.add(LatLng(lat, lon));
    }
    return points;
  }

  // Tap: ustaw A, potem B, potem najbliższy zamieniaj
  void _onTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      if (_start == null) {
        _start = latlng;
      } else if (_end == null) {
        _end = latlng;
      } else {
        final d = const Distance();
        final ds = d(_start!, latlng);
        final de = d(_end!, latlng);
        if (ds <= de) {
          _start = latlng;
        } else {
          _end = latlng;
        }
      }
    });
    _replan();
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

  // === Planer multimodalny (heurystyczny, prototyp) ===
  void _replan() {
    if (_start == null || _end == null) {
      setState(() {
        _routeLines = [];
        _routeMarkers = _baseMarkers();
        _itinerary = [];
      });
      return;
    }

    final d = const Distance();

    // 1) najbliższy przystanek do A (X) i do B (Y)
    final x = _nearest(_start!, _busStops, d);
    final y = _nearest(_end!, _busStops, d);

    // 2) najbliższa stacja roweru do Y (E) i do B (P)
    final e =
        _bikeStations.isEmpty ? null : _nearest(y ?? _end!, _bikeStations, d);
    final p = _bikeStations.isEmpty ? null : _nearest(_end!, _bikeStations, d);

    // Zapisz kroki + czasy (km/h → m/s)
    const vWalk = 5.0; // km/h
    const vBus = 30.0; // km/h
    const vBike = 15.0; // km/h

    final steps = <_StepItem>[];
    final polylines = <Polyline>[];

    LatLng cursor = _start!;

    // A → pieszo → X
    if (x != null) {
      steps.add(_step('Pieszo', cursor, x, vWalk, d, Icons.directions_walk));
      polylines.add(_poly(cursor, x, Colors.green));
      cursor = x;
    }

    // X → autobus → Y
    if (x != null && y != null && x != y) {
      steps.add(_step('Autobus', x, y, vBus, d, Icons.directions_bus));
      polylines.add(_poly(x, y, Colors.blue));
      cursor = y;
    }

    // Y → pieszo → E (jeśli mamy rower)
    if (y != null && e != null) {
      steps.add(_step('Pieszo', y, e, vWalk, d, Icons.directions_walk));
      polylines.add(_poly(y, e, Colors.green));
      cursor = e;
    }

    // E → rower → P
    if (e != null && p != null && e != p) {
      steps.add(_step('Rower', e, p, vBike, d, Icons.pedal_bike));
      polylines.add(_poly(e, p, Colors.orange));
      cursor = p;
    }

    // (jeśli nie ma roweru, od Y idziemy pieszo do B)
    if (e == null || p == null) {
      steps
          .add(_step('Pieszo', cursor, _end!, vWalk, d, Icons.directions_walk));
      polylines.add(_poly(cursor, _end!, Colors.green));
      cursor = _end!;
    } else {
      // P → pieszo → B
      steps
          .add(_step('Pieszo', cursor, _end!, vWalk, d, Icons.directions_walk));
      polylines.add(_poly(cursor, _end!, Colors.green));
      cursor = _end!;
    }

    // Markery: A, B, X, Y, E, P
    final markers = <Marker>[
      Marker(
          point: _start!,
          width: 40,
          height: 40,
          child: const Icon(Icons.flag, size: 36, color: Colors.black87)),
      Marker(
          point: _end!,
          width: 40,
          height: 40,
          child: const Icon(Icons.place, size: 36, color: Colors.black87)),
      if (x != null)
        Marker(
            point: x,
            width: 32,
            height: 32,
            child:
                const Icon(Icons.directions_bus, size: 28, color: Colors.blue)),
      if (y != null)
        Marker(
            point: y,
            width: 32,
            height: 32,
            child:
                const Icon(Icons.directions_bus, size: 28, color: Colors.blue)),
      if (e != null)
        Marker(
            point: e,
            width: 32,
            height: 32,
            child:
                const Icon(Icons.pedal_bike, size: 28, color: Colors.orange)),
      if (p != null)
        Marker(
            point: p,
            width: 32,
            height: 32,
            child:
                const Icon(Icons.pedal_bike, size: 28, color: Colors.orange)),
    ];

    setState(() {
      _routeLines = polylines;
      _routeMarkers = markers;
      _itinerary = steps;
    });

    // Dopasuj kadr
    _fitToBounds([
      _start!,
      _end!,
      if (x != null) x,
      if (y != null) y,
      if (e != null) e,
      if (p != null) p
    ]);
  }

  List<Marker> _baseMarkers() => [
        if (_start != null)
          Marker(
              point: _start!,
              width: 40,
              height: 40,
              child: const Icon(Icons.flag, size: 36)),
        if (_end != null)
          Marker(
              point: _end!,
              width: 40,
              height: 40,
              child: const Icon(Icons.place, size: 36)),
      ];

  LatLng? _nearest(LatLng from, List<LatLng> pool, Distance d) {
    if (pool.isEmpty) return null;
    LatLng best = pool.first;
    double bestDist = d(from, best);
    for (final p in pool.skip(1)) {
      final dd = d(from, p);
      if (dd < bestDist) {
        best = p;
        bestDist = dd;
      }
    }
    return best;
  }

  _StepItem _step(
      String mode, LatLng a, LatLng b, double kmh, Distance d, IconData icon) {
    final meters = d(a, b);
    final hours = meters / 1000.0 / kmh;
    final minutes = (hours * 60).round();
    return _StepItem(
      mode: mode,
      from: a,
      to: b,
      distanceMeters: meters,
      minutes: minutes,
      icon: icon,
    );
  }

  Polyline _poly(LatLng a, LatLng b, Color color) => Polyline(
        points: [a, b],
        color: color,
        strokeWidth: 4,
      );

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

  @override
  Widget build(BuildContext context) {
    final baseLayers = <Widget>[
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'pl.twoja.aplikacja',
      ),
      // Podgląd punktów źródłowych (blade kolory):
      if (_busStops.isNotEmpty)
        MarkerLayer(
          markers: _busStops
              .map((p) => Marker(
                  point: p,
                  width: 20,
                  height: 20,
                  child: const Icon(Icons.directions_bus,
                      size: 16, color: Colors.blueGrey)))
              .toList(),
        ),
      if (_bikeStations.isNotEmpty)
        MarkerLayer(
          markers: _bikeStations
              .map((p) => Marker(
                  point: p,
                  width: 20,
                  height: 20,
                  child: const Icon(Icons.pedal_bike,
                      size: 16, color: Colors.orangeAccent)))
              .toList(),
        ),
      if (_routeLines.isNotEmpty) PolylineLayer(polylines: _routeLines),
      MarkerLayer(
          markers: _routeMarkers.isNotEmpty ? _routeMarkers : _baseMarkers()),
      const RichAttributionWidget(
        attributions: [
          TextSourceAttribution('© OpenStreetMap contributors'),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planer A → B (prototyp)'),
        actions: [
          IconButton(
              onPressed: _clear,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Wyczyść'),
          IconButton(
            onPressed: (_start != null && _end != null) ? _replan : null,
            icon: const Icon(Icons.route),
            tooltip: 'Przelicz trasę',
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
                child: Center(child: CircularProgressIndicator())),
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
                        color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ),
          if (_itinerary.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _ItineraryCard(itinerary: _itinerary),
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
}

class _ItineraryCard extends StatelessWidget {
  final List<_StepItem> itinerary;
  const _ItineraryCard({required this.itinerary});

  @override
  Widget build(BuildContext context) {
    final totalMin = itinerary.fold<int>(0, (sum, s) => sum + s.minutes);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Icon(Icons.timeline),
              const SizedBox(width: 8),
              Text('Proponowana trasa • ~${totalMin} min',
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
              'Uwaga: prototyp – trasy autobus/rower to proste odcinki między punktami; czasy są orientacyjne.',
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

class _StepItem {
  final String mode;
  final LatLng from;
  final LatLng to;
  final double distanceMeters;
  final int minutes;
  final IconData icon;
  _StepItem({
    required this.mode,
    required this.from,
    required this.to,
    required this.distanceMeters,
    required this.minutes,
    required this.icon,
  });
}

// Mały pomocnik: firstOrNull
extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
