import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum Profile { foot, bike, car }

class StreetRouter {
  // Dla prototypu używamy publicznego demo OSRM (ma limity).
  // Produkcyjnie: postaw swój OSRM/GraphHopper/Valhalla.
  final String base;
  StreetRouter({this.base = 'https://router.project-osrm.org'});

  /// Zwraca listę punktów polilinii prowadzącej ulicami między punktami (węzły po kolei).
  /// Jeśli podasz więcej niż 2 punkty, potraktuje je jako via-points (A -> p1 -> p2 -> B).
  Future<List<LatLng>> route(List<LatLng> pts,
      {Profile profile = Profile.foot}) async {
    if (pts.length < 2) return [];
    final prof = switch (profile) {
      Profile.foot => 'foot',
      Profile.bike => 'bike',
      Profile.car => 'car',
    };
    final coords = pts.map((p) => '${p.longitude},${p.latitude}').join(';');
    final uri = Uri.parse(
        '$base/route/v1/$prof/$coords?overview=full&geometries=geojson&steps=false');

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('OSRM ${res.statusCode}: ${res.body}');
    }
    final jsonBody = json.decode(res.body) as Map<String, dynamic>;
    if ((jsonBody['routes'] as List).isEmpty) return [];
    final geom = jsonBody['routes'][0]['geometry'] as Map<String, dynamic>;
    final coordsGeo = (geom['coordinates'] as List).cast<List>();
    return coordsGeo
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
  }
}
