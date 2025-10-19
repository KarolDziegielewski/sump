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

  // Punkty A/B
  LatLng? _start;
  LatLng? _end;

  // Dane surowe
  Map<String, List<LatLng>> _busLines = {};
  List<LatLng> _bikeStations = [];
  List<LatLng> _busStopsExtra = [];

  // Cache gotowych markerów — liczone RAZ po wczytaniu KML
  List<Marker> _busLineMarkers = [];
  List<Marker> _bikeMarkers = [];
  List<Marker> _busStopsExtraMarkers = [];

  // Konfiguracja
  double _maxBikeKm = 7.0; // zsynchronizowane z plannerem
  static const int _extraStopsZoomThreshold = 14;

  // Widok/stan
  double _currentZoom = 13;
  bool _loading = true;
  String? _error;

  // Wynik planowania
  List<Polyline> _routeLines = [];
  List<Marker> _routeMarkers = [];
  List<StepItem> _itinerary = [];

  // Loader i planer
  final _loader = KmlLoader();
  final eco.EcoPlanner _planner = eco.EcoPlanner();

  @override
  void initState() {
    super.initState();
    _planner.setMaxBikeLegKm(_maxBikeKm);
    _loadKml();
  }

  Future<void> _loadKml() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _loader.loadAll();

      // Guard na wypadek zamkniętego ekranu
      if (!mounted) return;

      // Zapisz surowe
      _busLines = data.busLines;
      _bikeStations = data.bikeStations;
      _busStopsExtra = data.allBusStopsExtra;

      // Zbuduj markery RAZ (tu, poza buildem)
      _busLineMarkers = _busLines.values
          .expand((stops) => stops)
          .map(
            (p) => Marker(
              point: p,
              width: 16,
              height: 16,
              child: const Icon(Icons.directions_bus,
                  size: 14, color: Colors.blueGrey),
            ),
          )
          .toList();

      _bikeMarkers = _bikeStations
          .map(
            (p) => Marker(
              point: p,
              width: 18,
              height: 18,
              child:
                  const Icon(Icons.pedal_bike, size: 16, color: Colors.orange),
            ),
          )
          .toList();

      _busStopsExtraMarkers = _busStopsExtra
          .map(
            (p) => Marker(
              point: p,
              width: 12,
              height: 12,
              child: const Icon(Icons.directions_bus,
                  size: 10, color: Colors.blueGrey),
            ),
          )
          .toList();

      setState(() {
        _loading = false;
        _error = (_busLines.isEmpty && _bikeStations.isEmpty)
            ? 'Brak danych KML w assets/data/ i podkatalogach.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Błąd wczytywania KML: $e';
      });
    }

    // Diagnostyka
    // ignore: avoid_print
    print(
        'Załadowano: linie=${_busLines.length}, stacje=${_bikeStations.length}, extra=${_busStopsExtra.length}');
  }

  // Asynchroniczne planowanie (np. OSRM)
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

      if (!mounted) return;

      setState(() {
        _routeLines = plan.polylines;
        _routeMarkers = plan.markers;
        _itinerary = plan.steps;
        _loading = false;
      });

      _fitToBounds(plan.allPoints());
    } catch (e) {
      if (!mounted) return;
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

  void _onTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      if (_start == null) {
        _start = latLng;
      } else if (_end == null) {
        _end = latLng;
      } else {
        _start = latLng;
        _end = null;
        _routeLines = [];
        _routeMarkers = [];
        _itinerary = [];
      }
    });

    if (_start != null && _end != null) {
      _replan();
    }
  }

  void _showRoutingSettings() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        double tempValue = _maxBikeKm;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Maks. długość odcinka rowerem',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          min: 1.0,
                          max: 12.0,
                          divisions: 11,
                          value: tempValue,
                          label: '${tempValue.toStringAsFixed(1)} km',
                          onChanged: (v) => setModalState(() => tempValue = v),
                        ),
                      ),
                      SizedBox(
                          width: 56,
                          child: Text('${tempValue.toStringAsFixed(1)} km')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Zastosuj'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _maxBikeKm = tempValue;
                              _planner.setMaxBikeLegKm(_maxBikeKm);
                            });
                            if (_start != null && _end != null) {
                              _replan();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Warstwy mapy: wszystkie listy są już przygotowane wcześniej (cache)
    final layers = <Widget>[
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'pl.twoja.aplikacja',
      ),

      if (_busLineMarkers.isNotEmpty) MarkerLayer(markers: _busLineMarkers),
      if (_bikeMarkers.isNotEmpty) MarkerLayer(markers: _bikeMarkers),

      // Polilinie tras wynikowych
      if (_routeLines.isNotEmpty) PolylineLayer(polylines: _routeLines),

      // Markery trasy (start, przesiadki, itd.)
      MarkerLayer(
          markers: _routeMarkers.isNotEmpty ? _routeMarkers : _baseMarkers()),

      const RichAttributionWidget(
        attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
      ),

      // Dodatkowe przystanki – pokaż dopiero od konkretnego zoomu
      if (_busStopsExtraMarkers.isNotEmpty &&
          _currentZoom >= _extraStopsZoomThreshold)
        MarkerLayer(markers: _busStopsExtraMarkers),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EKO Planer Trasy'),
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
          IconButton(
            onPressed: _showRoutingSettings,
            icon: const Icon(Icons.tune),
            tooltip: 'Ustawienia trasy',
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
              // Aktualizuj zoom tylko po zakończonym ruchu, by ograniczyć rebuildy
              onMapEvent: (ev) {
                if (ev is MapEventMoveEnd) {
                  final newZoom = _map.camera.zoom;
                  if (newZoom != _currentZoom) {
                    setState(() => _currentZoom = newZoom);
                  }
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: layers,
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
