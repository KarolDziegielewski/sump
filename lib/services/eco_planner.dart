// lib/services/eco_planner.dart
// Planowanie tras pieszo/rower/autobus po SIECI ULIC (OSRM demo)
// Uwaga: dodaj w pubspec.yaml zależność:  http: ^1.2.2
// oraz utwórz plik lib/services/street_router.dart z implementacją StreetRouter (OSRM)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'street_router.dart';

class PlanResult {
  final List<Polyline> polylines;
  final List<Marker> markers;
  final List<dynamic>
      steps; // ➜ Podmień na List<StepItem> jeśli chcesz użyć swojej klasy.

  PlanResult({
    required this.polylines,
    required this.markers,
    required this.steps,
  });

  List<LatLng> allPoints() =>
      polylines.expand((p) => p.points).toList(growable: false);
}

class EcoPlanner {
  final StreetRouter router;

  // Parametry "prędkości" i kar
  final double walkKmh;
  final double bikeKmh;
  final double busKmh;
  final double busWaitPenaltyMin; // stała kara za czekanie na autobus

  EcoPlanner({
    StreetRouter? router,
    this.walkKmh = 5.0,
    this.bikeKmh = 15.0,
    this.busKmh = 26.0,
    this.busWaitPenaltyMin = 6.0,
  }) : router = router ?? StreetRouter();

  /// Główne planowanie: wybiera najszybszego kandydata z wariantów
  Future<PlanResult> plan({
    required LatLng start,
    required LatLng end,
    required List<LatLng> bikeStations,
    required Map<String, List<LatLng>> busLines,
  }) async {
    final candidates = <_Candidate>[];

    // A) Pieszo (po ulicach)
    candidates.add(await _walkOnly(start, end));

    // B) Rower + pieszo (stacja przy starcie i przy celu)
    if (bikeStations.isNotEmpty) {
      final c = await _bikePlusWalk(start, end, bikeStations);
      if (c != null) candidates.add(c);
    }

    // C) Autobus + pieszo (jedna linia, najbliższe przystanki, krótszy kierunek)
    if (busLines.isNotEmpty) {
      final c = await _busPlusWalk(start, end, busLines);
      if (c != null) candidates.add(c);
    }

    candidates.sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));
    final best = candidates.first;

    final markers = <Marker>[
      Marker(
          point: start,
          width: 40,
          height: 40,
          child: const Icon(Icons.flag, size: 36)),
      Marker(
          point: end,
          width: 40,
          height: 40,
          child: const Icon(Icons.place, size: 36)),
      ...best.extraMarkers,
    ];

    return PlanResult(
      polylines: best.polylines,
      markers: markers,
      steps: best.steps,
    );
  }

  // ======== WARIANTY ========

  Future<_Candidate> _walkOnly(LatLng a, LatLng b) async {
    final pts = await router.route([a, b], profile: Profile.foot);
    final distKm = _polylineLengthKm(pts);
    final minutes = distKm / walkKmh * 60.0;

    final poly = Polyline(points: pts, strokeWidth: 4, color: Colors.green);
    return _Candidate(
      label: 'Pieszo',
      totalMinutes: minutes,
      polylines: [poly],
      steps: [
        _step('Pieszo', '${_fmtKm(distKm)} · ${_fmtMin(minutes)}',
            Icons.directions_walk),
      ],
    );
  }

  Future<_Candidate?> _bikePlusWalk(
      LatLng start, LatLng end, List<LatLng> stations) async {
    final s1 = _nearest(stations, start);
    final s2 = _nearest(stations, end);
    if (s1 == null || s2 == null) return null;

    final walk1 = await router.route([start, s1], profile: Profile.foot);
    final ride = await router.route([s1, s2], profile: Profile.bike);
    final walk2 = await router.route([s2, end], profile: Profile.foot);

    final walk1Km = _polylineLengthKm(walk1);
    final rideKm = _polylineLengthKm(ride);
    final walk2Km = _polylineLengthKm(walk2);

    final minutes =
        (walk1Km / walkKmh + rideKm / bikeKmh + walk2Km / walkKmh) * 60.0;

    final polys = <Polyline>[
      Polyline(points: walk1, strokeWidth: 4, color: Colors.orange),
      Polyline(points: ride, strokeWidth: 5, color: Colors.deepOrange),
      Polyline(points: walk2, strokeWidth: 4, color: Colors.orange),
    ];
    final markers = <Marker>[
      Marker(
          point: s1,
          width: 30,
          height: 30,
          child: const Icon(Icons.pedal_bike)),
      Marker(
          point: s2,
          width: 30,
          height: 30,
          child: const Icon(Icons.pedal_bike)),
    ];

    return _Candidate(
      label: 'Rowery + pieszo',
      totalMinutes: minutes,
      polylines: polys,
      extraMarkers: markers,
      steps: [
        _step(
            'Dojdź do stacji',
            '${_fmtKm(walk1Km)} · ${_fmtMin(walk1Km / walkKmh * 60)}',
            Icons.directions_walk),
        _step(
            'Jedź rowerem',
            '${_fmtKm(rideKm)}  · ${_fmtMin(rideKm / bikeKmh * 60)}',
            Icons.pedal_bike),
        _step(
            'Dojdź do celu',
            '${_fmtKm(walk2Km)} · ${_fmtMin(walk2Km / walkKmh * 60)}',
            Icons.directions_walk),
      ],
    );
  }

  Future<_Candidate?> _busPlusWalk(
      LatLng start, LatLng end, Map<String, List<LatLng>> busLines) async {
    _Candidate? best;

    for (final entry in busLines.entries) {
      final lineId = entry.key;
      final stops = entry.value;
      if (stops.length < 2) continue;

      final iStart = _nearestIndex(stops, start);
      final iEnd = _nearestIndex(stops, end);
      if (iStart == null || iEnd == null) continue;

      // Wybierz kierunek krótszy po bazowej geometrii linii
      final segA = _subsegment(stops, iStart, iEnd);
      final segB = _subsegment(stops, iEnd, iStart);
      final lenA = _chainLengthKm(segA);
      final lenB = _chainLengthKm(segB);
      final busNodes = (lenA <= lenB) ? segA : segB.reversed.toList();

      // Chodzenie do/od przystanku po ulicach
      final walk1 =
          await router.route([start, busNodes.first], profile: Profile.foot);
      final walk2 =
          await router.route([busNodes.last, end], profile: Profile.foot);

      // Autobus – poskładany routing uliczny między kolejnymi węzłami
      final busStreetPts = <LatLng>[];
      for (var i = 1; i < busNodes.length; i++) {
        final segPts = await router
            .route([busNodes[i - 1], busNodes[i]], profile: Profile.car);
        if (busStreetPts.isEmpty) {
          busStreetPts.addAll(segPts);
        } else {
          busStreetPts.addAll(segPts.skip(1)); // unikaj dublowania węzłów
        }
      }

      final walk1Km = _polylineLengthKm(walk1);
      final busKm = _polylineLengthKm(busStreetPts);
      final walk2Km = _polylineLengthKm(walk2);

      final minutes = busWaitPenaltyMin +
          (walk1Km / walkKmh + busKm / busKmh + walk2Km / walkKmh) * 60.0;

      final polys = <Polyline>[
        Polyline(points: walk1, strokeWidth: 4, color: Colors.blueGrey),
        Polyline(points: busStreetPts, strokeWidth: 5, color: Colors.blue),
        Polyline(points: walk2, strokeWidth: 4, color: Colors.blueGrey),
      ];
      final markers = <Marker>[
        Marker(
            point: busNodes.first,
            width: 28,
            height: 28,
            child: const Icon(Icons.directions_bus)),
        Marker(
            point: busNodes.last,
            width: 28,
            height: 28,
            child: const Icon(Icons.directions_bus)),
      ];

      final cand = _Candidate(
        label: 'Autobus l.$lineId + pieszo',
        totalMinutes: minutes,
        polylines: polys,
        extraMarkers: markers,
        steps: [
          _step(
              'Dojdź na przystanek',
              '${_fmtKm(walk1Km)} · ${_fmtMin(walk1Km / walkKmh * 60)}',
              Icons.directions_walk),
          _step(
              'Autobus (l.$lineId)',
              '${_fmtKm(busKm)} · ${_fmtMin(busKm / busKmh * 60)} + ${busWaitPenaltyMin.toStringAsFixed(0)} min oczekiwania',
              Icons.directions_bus),
          _step(
              'Dojdź do celu',
              '${_fmtKm(walk2Km)} · ${_fmtMin(walk2Km / walkKmh * 60)}',
              Icons.directions_walk),
        ],
      );

      if (best == null || cand.totalMinutes < best!.totalMinutes) best = cand;
    }
    return best;
  }

  // ======== POMOCNIKI GEO ========

  double _km(LatLng a, LatLng b) {
    const R = 6371.0; // km
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final sa = math.sin(dLat / 2), sb = math.sin(dLon / 2);
    final c = 2 *
        math.asin(math.sqrt(sa * sa +
            math.cos(_deg2rad(a.latitude)) *
                math.cos(_deg2rad(b.latitude)) *
                sb *
                sb));
    return R * c;
  }

  double _deg2rad(double d) => d * math.pi / 180.0;

  int? _nearestIndex(List<LatLng> pts, LatLng p) {
    if (pts.isEmpty) return null;
    var best = 0;
    var bestD = _km(pts[0], p);
    for (var i = 1; i < pts.length; i++) {
      final d = _km(pts[i], p);
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  LatLng? _nearest(List<LatLng> pts, LatLng p) {
    final i = _nearestIndex(pts, p);
    return i == null ? null : pts[i];
  }

  List<LatLng> _subsegment(List<LatLng> pts, int from, int to) {
    if (from <= to) {
      return pts.sublist(from, to + 1);
    } else {
      return pts.sublist(to, from + 1).reversed.toList();
    }
  }

  double _polylineLengthKm(List<LatLng> pts) {
    if (pts.length < 2) return 0.0;
    double s = 0.0;
    for (var i = 1; i < pts.length; i++) {
      s += _km(pts[i - 1], pts[i]);
    }
    return s;
  }

  double _chainLengthKm(List<LatLng> pts) => _polylineLengthKm(pts);

  // ======== FORMATERY ========

  String _fmtKm(double km) {
    if (km.isNaN || km.isInfinite) return '-';
    if (km < 1.0) return '${(km * 1000).round()} m';
    final dec = (km < 10) ? 1 : 0;
    return '${km.toStringAsFixed(dec)} km';
  }

  String _fmtMin(double minutes) {
    if (minutes.isNaN || minutes.isInfinite) return '-';
    if (minutes < 60) return '${minutes.round()} min';
    final h = (minutes ~/ 60);
    final m = (minutes % 60).round();
    return m == 0 ? '${h} h' : '${h} h ${m} min';
  }

  // ======== KROKI ITYNERARIUSZA ========
  // Jeśli masz własny StepItem, podmień implementację tak, by tworzyła Twój obiekt.
  dynamic _step(String title, String subtitle, IconData icon) {
    return {
      'title': title,
      'subtitle': subtitle,
      'icon': icon.codePoint,
    };
  }
}

class _Candidate {
  final String label;
  final double totalMinutes;
  final List<Polyline> polylines;
  final List<Marker> extraMarkers;
  final List<dynamic> steps;

  _Candidate({
    required this.label,
    required this.totalMinutes,
    required this.polylines,
    this.extraMarkers = const [],
    required this.steps,
  });
}
