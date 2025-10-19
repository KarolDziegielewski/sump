import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart' as xml;
import 'package:url_launcher/url_launcher.dart';

class BikeRouteScreen extends StatefulWidget {
  const BikeRouteScreen({super.key});

  @override
  State<BikeRouteScreen> createState() => _BikeRouteScreenState();
}

class _BikeRouteScreenState extends State<BikeRouteScreen> {
  static const String _kmlAssetPath =
      'assets/data/PRM stacje roweru miejskiego.kml';

  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  bool _loading = true;
  String? _error;

  // Fallback – centrum Płocka zanim dopasujemy do markerów
  static const LatLng _plockCenter = LatLng(52.546, 19.706);

  @override
  void initState() {
    super.initState();
    _loadKmlAndRender();
  }

  Future<void> _loadKmlAndRender() async {
    try {
      final kmlText = await rootBundle.loadString(_kmlAssetPath);
      final markers = _parseKmlToMarkers(kmlText);

      if (!mounted) return;
      setState(() {
        _markers
          ..clear()
          ..addAll(markers);
        _loading = false;
        _error = markers.isEmpty ? 'Brak stacji w pliku KML' : null;
      });

      if (markers.isNotEmpty) {
        await _fitToAllMarkers();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Nie udało się wczytać KML: $e';
      });
    }
  }

  List<Marker> _parseKmlToMarkers(String kml) {
    final doc = xml.XmlDocument.parse(kml);
    final placemarks = doc.findAllElements('Placemark');
    final List<Marker> result = [];

    for (final pm in placemarks) {
      final name = pm.getElement('name')?.innerText.trim();

      final point = pm.findAllElements('Point').firstOrNull;
      if (point == null) continue;

      final coordsText = point.getElement('coordinates')?.innerText.trim();
      if (coordsText == null || coordsText.isEmpty) continue;

      // KML: "lon,lat[,alt] [spacja] lon,lat ..."
      final firstPair = coordsText
          .split(RegExp(r'\s+'))
          .firstWhere((e) => e.contains(','), orElse: () => coordsText);

      final parts = firstPair.split(',');
      if (parts.length < 2) continue;

      final lon = double.tryParse(parts[0]);
      final lat = double.tryParse(parts[1]);
      if (lat == null || lon == null) continue;

      final pos = LatLng(lat, lon);
      result.add(
        Marker(
          point: pos,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.pedal_bike,
            size: 34,
            color: Colors.blueAccent,
          ),
        ),
      );
    }
    return result;
  }

  Future<void> _fitToAllMarkers() async {
    if (_markers.length == 1) {
      final only = _markers.first.point;
      _mapController.move(only, 16);
      return;
    }

    double? minLat, maxLat, minLng, maxLng;
    for (final m in _markers) {
      final lat = m.point.latitude;
      final lng = m.point.longitude;
      minLat = (minLat == null) ? lat : math.min(minLat, lat);
      maxLat = (maxLat == null) ? lat : math.max(maxLat, lat);
      minLng = (minLng == null) ? lng : math.min(minLng, lng);
      maxLng = (maxLng == null) ? lng : math.max(maxLng, lng);
    }

    final bounds = LatLngBounds(
      LatLng(minLat!, minLng!),
      LatLng(maxLat!, maxLng!),
    );

    // padding ~60 px
    final fit =
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60));
    final camera = fit.fit(_mapController.camera);
    _mapController.move(camera.center, camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stacje roweru miejskiego (OSM)'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Przeładuj KML',
            icon: const Icon(Icons.refresh),
            onPressed: _loadKmlAndRender,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _plockCenter,
              initialZoom: 12,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                // Płytki OpenStreetMap — pamiętaj o atrybucji:
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'pl.twoja.aplikacja', // dobry zwyczaj
                retinaMode: MediaQuery.of(context).devicePixelRatio > 1.6,
              ),
              MarkerLayer(markers: _markers),
              RichAttributionWidget(
                attributions: const [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: null,
                  ),
                ],
              ),
            ],
          ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.transparent,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          Positioned(
            left: 12,
            bottom: 12,
            child: Material(
              // daje ripple dla InkWell
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  const url = 'https://roovee.eu';
                  final uri = Uri.parse(url);

                  // Dla web: otwieraj w nowej karcie, dla mobile: domyślnie
                  final ok = await launchUrl(
                    uri,
                    mode: LaunchMode.platformDefault,
                    webOnlyWindowName: '_blank', // <— kluczowe na Flutter Web
                  );

                  if (!ok && (await canLaunchUrl(uri))) {
                    // fallback (np. dziwne środowisko)
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }

                  if (!ok && !await canLaunchUrl(uri) && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Nie mogę otworzyć roovee.eu')),
                    );
                  }
                },
                child: Opacity(
                  opacity: 0.9,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/roovie.png',
                      width: 150,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
          ),

// BANER BŁĘDU — TYLKO GDY JEST BŁĄD I NIE ŁADUJEMY
          if (_error != null && !_loading)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!, // teraz bezpieczne
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (_markers.isNotEmpty && !_loading)
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.zoom_out_map),
              label: const Text('Pokaż wszystkie'),
              onPressed: _fitToAllMarkers,
            )
          : null,
    );
  }
}

class _StationMarker extends StatelessWidget {
  final String label;
  const _StationMarker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // dopasuj do treści
      children: [
        const Icon(Icons.pedal_bike, size: 28, color: Colors.blueAccent),
        const SizedBox(height: 2),
        Container(
          constraints: const BoxConstraints(
            maxWidth: 100, // niech długie nazwy się zawijają
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, height: 1.2),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
