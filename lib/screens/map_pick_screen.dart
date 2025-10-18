import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart' as xml;

/// Planer trasy A→B z priorytetem ekologii:
/// Rower miejski > Autobus (ta sama linia) > Pieszo.
///
/// Założenia plików:
/// - assets/data/PRM stacje roweru miejskiego.kml  (stacje rowerów)
/// - assets/data/<numer>_*.kml  (pojedyncze linie autobusowe, np. 100_..., 101_...)
///
/// Prototyp używa prostych odcinków (geodezyjnie) między punktami.
/// Czas orientacyjny: pieszo 5 km/h, autobus 30 km/h, rower 15 km/h.
///
/// Nie dodajemy żadnych podpisów przy ikonkach rowerów.

class MapPickScreen extends StatefulWidget {
  const MapPickScreen({super.key});

  @override
  State<MapPickScreen> createState() => _MapPickScreenState();
}

class _MapPickScreenState extends State<MapPickScreen> {
  // Nazwa pliku stacji roweru miejskiego (dokładnie jak w assets)
  static const String bikeStationsFile =
      'assets/data/PRM stacje roweru miejskiego.kml';

  final MapController _map = MapController();
  LatLng? _start;
  LatLng? _end;

  // Dane z KML
  final Map<String, List<LatLng>> _busLines = {}; // lineId -> stops
  List<LatLng> _bikeStations = [];

  // Wynik planowania
  List<Polyline> _routeLines = [];
  List<Marker> _routeMarkers = [];
  List<_StepItem> _itinerary = [];

  bool _loading = true;
  String? _error;

  // Parametry heurystyki (możesz dostroić)
  static const double maxWalkToBikeMeters =
      1000; // max dojścia do stacji roweru z A i z/do B
  static const double maxWalkToBusMeters =
      1000; // max dojścia do przystanku z A i z/do B

  // Prędkości [km/h]
  static const double vWalk = 5.0;
  static const double vBus = 30.0;
  static const double vBike = 15.0;

  static const LatLng _plockCenter = LatLng(52.5468, 19.7064);

  @override
  void initState() {
    super.initState();
    _loadAllKml();
  }

  Future<void> _loadAllKml() async {
    try {
      // Auto-odkrywanie wszystkich assetów w assets/data/ z AssetManifest.json
      final manifestRaw = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestRaw);

      final dataAssets = manifest.keys
          .where((k) =>
              k.startsWith('assets/data/') && k.toLowerCase().endsWith('.kml'))
          .toList();

      if (dataAssets.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Brak plików KML w assets/data/.';
        });
        return;
      }

      // Wczytaj stacje roweru
      if (dataAssets.contains(bikeStationsFile)) {
        final kmlBike = await rootBundle.loadString(bikeStationsFile);
        _bikeStations = _parseKmlPoints(kmlBike);
      } else {
        _bikeStations = [];
      }

      // Wczytaj linie autobusowe: każdy plik != bikeStationsFile traktujemy jako osobną linię.
      _busLines.clear();
      for (final path in dataAssets) {
        if (path == bikeStationsFile) continue;
        final kml = await rootBundle.loadString(path);
        final stops = _parseKmlPoints(kml);
        if (stops.isNotEmpty) {
          final lineId = _lineIdFromPath(path);
          _busLines[lineId] = stops;
        }
      }

      setState(() {
        _loading = false;
        _error = (_bikeStations.isEmpty && _busLines.isEmpty)
            ? 'Nie znaleziono stacji roweru ani linii autobusowych w KML.'
            : null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Błąd wczytywania KML: $e';
      });
    }
  }

  // Parser KML -> lista punktów (Placemark > Point > coordinates: lon,lat[,alt])
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

  String _lineIdFromPath(String path) {
    // Przykład: "assets/data/101_proboszczewicei_p.kml" -> "101"
    final file = path.split('/').last;
    final numPrefix = RegExp(r'^\d+').stringMatch(file);
    return numPrefix ?? file.replaceAll('.kml', '');
  }

  // Tap: ustaw A, potem B, potem zamieniaj bliższy
  void _onTap(TapPosition _, LatLng latlng) {
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

  // === PLANER: wybór najbardziej "eko" ===
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

    // Kandydat 1: ROWER
    final bikeCandidate = _planBike(d);

    // Kandydat 2: AUTOBUS (jedna linia)
    final busCandidate = _planBusSingleLine(d);

    // Kandydat 3: PIESZO
    final walkCandidate = _planWalkOnly(d);

    // Porównanie wg "eko" – wagi/score (im mniej, tym lepiej)
    // rower=1, autobus=2, pieszo=3 (per metr)
    double scoreOf(_Plan p) =>
        p.walkMeters * 3 + p.busMeters * 2 + p.bikeMeters * 1;

    _Plan best = walkCandidate;
    if (busCandidate != null && scoreOf(busCandidate) < scoreOf(best))
      best = busCandidate;
    if (bikeCandidate != null && scoreOf(bikeCandidate) < scoreOf(best))
      best = bikeCandidate;

    // Aktualizacja widoku
    setState(() {
      _routeLines = best.polylines;
      _routeMarkers = best.markers;
      _itinerary = best.steps;
    });

    // Dopasuj kamerę
    _fitToBounds(best.allPoints());
  }

  _Plan? _planBike(Distance d) {
    if (_bikeStations.isEmpty) return null;

    final s1 = _nearest(_start!, _bikeStations, d);
    final s2 = _nearest(_end!, _bikeStations, d);
    if (s1 == null || s2 == null) return null;

    final walkA = d(_start!, s1);
    final walkB = d(s2, _end!);

    // Jeżeli dojścia do stacji są za długie – bike wariant odpada
    if (walkA > maxWalkToBikeMeters || walkB > maxWalkToBikeMeters) return null;

    final bikeM = d(s1, s2);

    final steps = <_StepItem>[
      _step('Pieszo', _start!, s1, vWalk, d, Icons.directions_walk),
      _step('Rower', s1, s2, vBike, d, Icons.pedal_bike),
      _step('Pieszo', s2, _end!, vWalk, d, Icons.directions_walk),
    ];

    final lines = <Polyline>[
      _poly(_start!, s1, Colors.green),
      _poly(s1, s2, Colors.orange),
      _poly(s2, _end!, Colors.green),
    ];

    final markers = <Marker>[
      Marker(
          point: _start!,
          width: 40,
          height: 40,
          child: const Icon(Icons.flag, size: 36)),
      Marker(
          point: _end!,
          width: 40,
          height: 40,
          child: const Icon(Icons.place, size: 36)),
      Marker(
          point: s1,
          width: 34,
          height: 34,
          child: const Icon(Icons.pedal_bike, size: 30, color: Colors.orange)),
      Marker(
          point: s2,
          width: 34,
          height: 34,
          child: const Icon(Icons.pedal_bike, size: 30, color: Colors.orange)),
    ];

    return _Plan(
      steps: steps,
      polylines: lines,
      markers: markers,
      walkMeters: walkA + walkB,
      bikeMeters: bikeM,
      busMeters: 0,
    );
  }

  _Plan? _planBusSingleLine(Distance d) {
    if (_busLines.isEmpty) return null;

    _Plan? best;
    double? bestScore; // wg eco: walk*3 + bus*2
    for (final entry in _busLines.entries) {
      final stops = entry.value;
      if (stops.length < 2) continue;

      final x = _nearest(_start!, stops, d);
      final y = _nearest(_end!, stops, d);
      if (x == null || y == null) continue;

      final walkA = d(_start!, x);
      final walkB = d(y, _end!);
      if (walkA > maxWalkToBusMeters || walkB > maxWalkToBusMeters) continue;

      final busM = d(x, y);

      final steps = <_StepItem>[
        _step('Pieszo', _start!, x, vWalk, d, Icons.directions_walk),
        _step('Autobus (linia ${entry.key})', x, y, vBus, d,
            Icons.directions_bus),
        _step('Pieszo', y, _end!, vWalk, d, Icons.directions_walk),
      ];

      final lines = <Polyline>[
        _poly(_start!, x, Colors.green),
        _poly(x, y, Colors.blue),
        _poly(y, _end!, Colors.green),
      ];

      final markers = <Marker>[
        Marker(
            point: _start!,
            width: 40,
            height: 40,
            child: const Icon(Icons.flag, size: 36)),
        Marker(
            point: _end!,
            width: 40,
            height: 40,
            child: const Icon(Icons.place, size: 36)),
        Marker(
            point: x,
            width: 30,
            height: 30,
            child:
                const Icon(Icons.directions_bus, size: 26, color: Colors.blue)),
        Marker(
            point: y,
            width: 30,
            height: 30,
            child:
                const Icon(Icons.directions_bus, size: 26, color: Colors.blue)),
      ];

      final plan = _Plan(
        steps: steps,
        polylines: lines,
        markers: markers,
        walkMeters: walkA + walkB,
        busMeters: busM,
        bikeMeters: 0,
      );

      final score = plan.walkMeters * 3 + plan.busMeters * 2;
      if (best == null || score < bestScore!) {
        best = plan;
        bestScore = score;
      }
    }
    return best;
    // (Rozszerzalne: w przyszłości można dodać przesiadki 2+ linii.)
  }

  _Plan _planWalkOnly(Distance d) {
    final w = d(_start!, _end!);
    final steps = <_StepItem>[
      _step('Pieszo', _start!, _end!, vWalk, d, Icons.directions_walk),
    ];
    final lines = <Polyline>[
      _poly(_start!, _end!, Colors.green),
    ];
    final markers = <Marker>[
      Marker(
          point: _start!,
          width: 40,
          height: 40,
          child: const Icon(Icons.flag, size: 36)),
      Marker(
          point: _end!,
          width: 40,
          height: 40,
          child: const Icon(Icons.place, size: 36)),
    ];
    return _Plan(
      steps: steps,
      polylines: lines,
      markers: markers,
      walkMeters: w,
      busMeters: 0,
      bikeMeters: 0,
    );
  }

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
    final minutes = math.max(1, (hours * 60).round());
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
      // Podgląd źródłowych punktów (delikatne)
      if (_busLines.isNotEmpty)
        MarkerLayer(
          markers: _busLines.values
              .expand((stops) => stops)
              .map((p) => Marker(
                  point: p,
                  width: 16,
                  height: 16,
                  child: const Icon(Icons.directions_bus,
                      size: 14, color: Colors.blueGrey)))
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
                      size: 16, color: Colors.orange)))
              .toList(),
        ),
      if (_routeLines.isNotEmpty) PolylineLayer(polylines: _routeLines),
      MarkerLayer(
          markers: _routeMarkers.isNotEmpty ? _routeMarkers : _baseMarkers()),
      const RichAttributionWidget(
        attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planer A → B (eko priorytet)'),
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
          IconButton(
            onPressed: _loadAllKml,
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
}

class _ItineraryCard extends StatelessWidget {
  final List<_StepItem> itinerary;
  const _ItineraryCard({required this.itinerary});

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
              'Prototyp: odcinki autobus/rower łączone „po prostej”. W przyszłości podmienimy na rzeczywiste przebiegi linii/tras.',
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

// ========= Plan wyniku (zestaw wszystkiego dla wybranego wariantu) =========
class _Plan {
  final List<_StepItem> steps; // kroki z ikonami i czasem
  final List<Polyline> polylines; // odcinki do narysowania
  final List<Marker> markers; // A, B, przystanki/stacje użyte w planie
  final double walkMeters; // suma metrów pieszo
  final double busMeters; // suma metrów autobusem
  final double bikeMeters; // suma metrów rowerem

  _Plan({
    required this.steps,
    required this.polylines,
    required this.markers,
    required this.walkMeters,
    required this.busMeters,
    required this.bikeMeters,
  });

  /// Zbiera wszystkie punkty trasy do dopasowania kamery.
  /// Bierzemy punkty z kroków (początek/koniec).
  List<LatLng> allPoints() {
    final pts = <LatLng>[];
    for (final s in steps) {
      pts.add(s.from);
      pts.add(s.to);
    }
    // usuwanie duplikatów z zachowaniem kolejności
    final seen = <String>{};
    final uniq = <LatLng>[];
    for (final p in pts) {
      final k =
          '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}';
      if (seen.add(k)) uniq.add(p);
    }
    return uniq;
  }
}

// firstOrNull helper
extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
