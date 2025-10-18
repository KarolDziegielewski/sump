import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart' as xml;

class KmlData {
  final Map<String, List<LatLng>> busLines; // id linii -> przystanki (kolejno)
  final List<LatLng> bikeStations; // stacje roweru miejskiego
  final List<LatLng> allBusStopsExtra; // dodatkowe przystanki (np. OSM SUMP)

  KmlData({
    required this.busLines,
    required this.bikeStations,
    required this.allBusStopsExtra,
  });
}

class KmlLoader {
  // np. „roweru” dopasuje „stacje roweru miejskiego”
  final String bikeStationsHint;
  KmlLoader({this.bikeStationsHint = 'roweru'});

  Future<KmlData> loadAll() async {
    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest = json.decode(manifestRaw);

    // Lista wszystkich plików KML w assets
    final allKml =
        manifest.keys.where((k) => k.toLowerCase().endsWith('.kml')).toList();

    // --- ROWER MIEJSKI: szukaj w assets/data/sump/ (lub ogólnie assets/data/) pliku zawierającego „roweru”
    final bikeKmlPath = allKml.firstWhere(
      (p) =>
          p.toLowerCase().contains('/data/') &&
          p.toLowerCase().contains(bikeStationsHint.toLowerCase()),
      orElse: () => '',
    );

    final bikeStations = <LatLng>[];
    if (bikeKmlPath.isNotEmpty) {
      final text = await rootBundle.loadString(bikeKmlPath);
      bikeStations.addAll(_parseKmlPoints(text));
    }

    // --- LINIE AUTOBUSOWE: każdy plik w assets/data/sump/kmplock/
    final busLines = <String, List<LatLng>>{};
    final kmplock = allKml.where(
      (p) => p.startsWith('assets/data/sump/kmplock/'),
    );
    for (final path in kmplock) {
      final text = await rootBundle.loadString(path);
      final stops = _parseKmlPoints(text);
      if (stops.isNotEmpty) {
        busLines[_lineIdFromPath(path)] = stops;
      }
    }

    // --- DODATKOWE PRZYSTANKI (OSM/SUMP): assets/data/sump/highway_busstop_sump_osm.kml
    final extraStops = <LatLng>[];

    // 1) konkretny plik OSM z przystankami:
    final osmBusStopsPath = allKml.firstWhere(
      (p) => p == 'assets/data/sump/highway_busstop_sump_osm.kml',
      orElse: () => '',
    );
    if (osmBusStopsPath.isNotEmpty) {
      final text = await rootBundle.loadString(osmBusStopsPath);
      extraStops.addAll(_parseKmlPoints(text));
    }

    // 2) (opcjonalnie) wszystko inne z katalogu sump/ — jeśli chcesz, zostawiamy jak było:
    final sumpOthers = allKml.where((p) =>
        p.startsWith('assets/data/sump/') &&
        p != osmBusStopsPath && // nie dubluj
        !p.startsWith('assets/data/sump/kmplock/')); // nie mieszaj linii
    for (final path in sumpOthers) {
      final text = await rootBundle.loadString(path);
      extraStops.addAll(_parseKmlPoints(text));
    }

    return KmlData(
      busLines: busLines,
      bikeStations: bikeStations,
      allBusStopsExtra: extraStops,
    );
  }

  List<LatLng> _parseKmlPoints(String kml) {
    final doc = xml.XmlDocument.parse(kml);
    final placemarks = doc.findAllElements('Placemark');
    final out = <LatLng>[];
    for (final pm in placemarks) {
      final point = pm.findAllElements('Point').isEmpty
          ? null
          : pm.findAllElements('Point').first;
      if (point == null) continue;
      final coordsText = point.getElement('coordinates')?.innerText.trim();
      if (coordsText == null || coordsText.isEmpty) continue;

      // weź pierwszy zestaw lon,lat[,alt]
      final firstPair = coordsText
          .split(RegExp(r'\s+'))
          .firstWhere((e) => e.contains(','), orElse: () => coordsText);
      final parts = firstPair.split(',');
      if (parts.length < 2) continue;
      final lon = double.tryParse(parts[0]);
      final lat = double.tryParse(parts[1]);
      if (lat == null || lon == null) continue;
      out.add(LatLng(lat, lon));
    }
    return out;
  }

  String _lineIdFromPath(String path) {
    final file = path.split('/').last;
    final m = RegExp(r'^\d+').firstMatch(file);
    return m?.group(0) ?? file.replaceAll('.kml', '');
  }
}
