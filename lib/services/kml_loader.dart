import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart' as xml;

class KmlData {
  final Map<String, List<LatLng>> busLines; // id linii -> przystanki
  final List<LatLng> bikeStations; // stacje roweru miejskiego
  final List<LatLng> allBusStopsExtra; // np. z assets/data/sump/...

  KmlData({
    required this.busLines,
    required this.bikeStations,
    required this.allBusStopsExtra,
  });
}

class KmlLoader {
  // Możesz nadpisać wzorce, jeśli chcesz
  final String bikeStationsHint; // np. "PRM stacje roweru miejskiego"
  KmlLoader({this.bikeStationsHint = 'roweru'});

  Future<KmlData> loadAll() async {
    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest = json.decode(manifestRaw);

    final allKml =
        manifest.keys.where((k) => k.toLowerCase().endsWith('.kml')).toList();

    // Rowery – szukaj w assets/data/ pliku zawierającego słowo-klucz (np. "roweru")
    final bikeKmlPath = allKml.firstWhere(
      (p) =>
          p.startsWith('assets/data/') &&
          p.toLowerCase().contains(bikeStationsHint.toLowerCase()),
      orElse: () => '',
    );

    final bikeStations = <LatLng>[];
    if (bikeKmlPath.isNotEmpty) {
      final text = await rootBundle.loadString(bikeKmlPath);
      bikeStations.addAll(_parseKmlPoints(text));
    }

    // Linie autobusowe – każdy plik w assets/data/kmplock/
    final busLines = <String, List<LatLng>>{};
    final kmplock = allKml.where((p) => p.startsWith('assets/data/kmplock/'));
    for (final path in kmplock) {
      final text = await rootBundle.loadString(path);
      final stops = _parseKmlPoints(text);
      if (stops.isNotEmpty) {
        busLines[_lineIdFromPath(path)] = stops;
      }
    }

    // Dodatkowe przystanki zbiorcze (opcjonalnie): assets/data/sump/
    final allBusStopsExtra = <LatLng>[];
    final sump = allKml.where((p) => p.startsWith('assets/data/sump/'));
    for (final path in sump) {
      final text = await rootBundle.loadString(path);
      allBusStopsExtra.addAll(_parseKmlPoints(text));
    }

    return KmlData(
      busLines: busLines,
      bikeStations: bikeStations,
      allBusStopsExtra: allBusStopsExtra,
    );
  }

  List<LatLng> _parseKmlPoints(String kml) {
    final doc = xml.XmlDocument.parse(kml);

    // Bierzemy wszystkie Placemark (z uwzględnieniem namespace, np. <kml:Placemark>)
    final placemarks = doc.findAllElements('Placemark', namespace: '*');

    final out = <LatLng>[];

    for (final pm in placemarks) {
      // 1) POINT
      final point = pm.findElements('Point', namespace: '*').firstOrNull;
      if (point != null) {
        final coordsText =
            point.getElement('coordinates', namespace: '*')?.text.trim();
        final p = _firstLatLngFromCoordinates(coordsText);
        if (p != null) out.add(p);
        continue; // nic więcej nie szukamy w tym placemarku
      }

      // 2) LINESTRING (jeśli kiedyś zechcesz same węzły linii potraktować jak punkty)
      final line = pm.findElements('LineString', namespace: '*').firstOrNull;
      if (line != null) {
        final coordsText =
            line.getElement('coordinates', namespace: '*')?.text.trim();
        final pts = _allLatLngFromCoordinates(coordsText);
        out.addAll(pts);
        continue;
      }

      // 3) MultiGeometry (opcjonalnie: LineString/Point w środku)
      final multi =
          pm.findElements('MultiGeometry', namespace: '*').firstOrNull;
      if (multi != null) {
        // Points
        for (final p in multi.findAllElements('Point', namespace: '*')) {
          final coordsText =
              p.getElement('coordinates', namespace: '*')?.text.trim();
          final ll = _firstLatLngFromCoordinates(coordsText);
          if (ll != null) out.add(ll);
        }
        // LineStrings
        for (final l in multi.findAllElements('LineString', namespace: '*')) {
          final coordsText =
              l.getElement('coordinates', namespace: '*')?.text.trim();
          out.addAll(_allLatLngFromCoordinates(coordsText));
        }
      }
    }

    return out;
  }

// Zwraca pierwszy punkt z ciągu "lon,lat[,alt] lon,lat[,alt] ..."
  LatLng? _firstLatLngFromCoordinates(String? coordsText) {
    if (coordsText == null || coordsText.isEmpty) return null;
    final firstPair = coordsText
        .split(RegExp(r'\s+'))
        .firstWhere((e) => e.contains(','), orElse: () => '');
    if (firstPair.isEmpty) return null;
    final parts = firstPair.split(',');
    if (parts.length < 2) return null;
    final lon = double.tryParse(parts[0]);
    final lat = double.tryParse(parts[1]);
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

// Zwraca wszystkie punkty z "lon,lat[,alt] lon,lat[,alt] ..."
  List<LatLng> _allLatLngFromCoordinates(String? coordsText) {
    if (coordsText == null || coordsText.isEmpty) return const [];
    return coordsText
        .split(RegExp(r'\s+'))
        .where((s) => s.contains(','))
        .map((pair) {
          final parts = pair.split(',');
          if (parts.length < 2) return null;
          final lon = double.tryParse(parts[0]);
          final lat = double.tryParse(parts[1]);
          if (lat == null || lon == null) return null;
          return LatLng(lat, lon);
        })
        .whereType<LatLng>()
        .toList();
  }

  String _lineIdFromPath(String path) {
    final file = path.split('/').last;
    final m = RegExp(r'^\d+').firstMatch(file);
    return m?.group(0) ?? file.replaceAll('.kml', '');
  }
}

// syntactic sugar
extension on Iterable {
  get firstOrNull => isEmpty ? null : first;
}
