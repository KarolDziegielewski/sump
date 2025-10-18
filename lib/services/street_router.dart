import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum Profile { walking, cycling, driving }

class StreetRouter {
  final String base;
  StreetRouter({this.base = 'https://router.project-osrm.org'});

  Future<List<LatLng>> route(
    List<LatLng> pts, {
    Profile profile = Profile.walking,
  }) async {
    if (pts.length < 2) return pts;

    final prof = switch (profile) {
      Profile.walking => 'walking',
      Profile.cycling => 'cycling',
      Profile.driving => 'driving',
    };

    final coords = pts.map((p) => '${p.longitude},${p.latitude}').join(';');
    final uri = Uri.parse(
      '$base/route/v1/$prof/$coords?overview=full&geometries=geojson&steps=false',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('OSRM ${res.statusCode}: ${res.body}');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final routes = (body['routes'] as List? ?? const []);
    if (routes.isEmpty) throw Exception('OSRM: no routes');

    final geom = routes[0]['geometry'] as Map<String, dynamic>;
    final coordsGeo = (geom['coordinates'] as List).cast<List>();
    final out = coordsGeo
        .map((c) => LatLng(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ))
        .toList();

    if (out.length < 2) throw Exception('OSRM: too few coords');
    return out;
  }
}
