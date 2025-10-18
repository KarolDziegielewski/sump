// lib/services/eco_planner.dart
// Planowanie pieszo/rower/autobus po SIECI ULIC (OSRM).
// W pubspec.yaml:  http: ^1.2.2
// street_router.dart musi mieć Profile.walking / cycling / driving.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/plan_models.dart';
import 'street_router.dart';

class EcoPlanner {
  final StreetRouter router;

  // Parametry prędkości/kar:
  final double walkKmh;
  final double bikeKmh;
  final double busKmh;
  final double busWaitPenaltyMin;

  // Polityka wyboru (strojenie z UI przez settery):
  double maxWalkToBikeM; // max dojście pieszo do/od stacji roweru
  double maxBikeLegKm; // maks. długość przejazdu rowerem (regulowane suwakiem)
  double
      preferBikeUpToKm; // (informacyjne) do tej odległości całej trasy preferuj rower
  double maxWalkToBusM; // max dojście pieszo do/od przystanku
  double minBusLegKm; // minimalny sensowny odcinek autobusem

  EcoPlanner({
    StreetRouter? router,
    this.walkKmh = 5.0,
    this.bikeKmh = 15.0,
    this.busKmh = 26.0,
    this.busWaitPenaltyMin = 6.0,
    this.maxWalkToBikeM = 600,
    this.maxBikeLegKm = 7.0,
    this.preferBikeUpToKm = 5.0,
    this.maxWalkToBusM = 800,
    this.minBusLegKm = 2.0,
  }) : router = router ?? StreetRouter();

  // Settery do sterowania z UI
  void setMaxBikeLegKm(double km) => maxBikeLegKm = km;
  void setMaxWalkToBikeM(double m) => maxWalkToBikeM = m;

  double _chainLengthKm(List<LatLng> pts) => _polylineLengthKm(pts);

  /// Główne planowanie: wybieramy wariant zgodnie z polityką:
  /// 1) jeśli rower dostępny -> porównaj rower vs autobus (wybierz szybszy),
  /// 2) jeśli rower niedostępny, a autobus dostępny -> wybierz autobus (NIE pieszo),
  /// 3) inaczej -> pieszo.
  Future<Plan> plan({
    required LatLng start,
    required LatLng end,
    required List<LatLng> bikeStations,
    required Map<String, List<LatLng>> busLines,
  }) async {
    // policz referencyjny dystans pieszo (po ulicach) – przydatne do diagnostyki/telemetrii
    final walkAB = await _routeOrThrow([start, end], Profile.walking);
    final walkABkm = _polylineLengthKm(walkAB);

    // Przygotuj kandydatów
    final walkCandidate = await _walkOnly(start, end);

    _Candidate? bikeCandidate;
    if (bikeStations.isNotEmpty) {
      bikeCandidate = await _bikePlusWalk(start, end, bikeStations);
    }

    _Candidate? busCandidate;
    if (busLines.isNotEmpty) {
      busCandidate = await _busPlusWalk(start, end, busLines);
    }

    // Decyzja:
    _Candidate chosen;
    if (bikeCandidate != null && busCandidate != null) {
      // Rower dostępny – porównaj z autobusem i wybierz szybszy
      chosen = (bikeCandidate.totalMinutes <= busCandidate.totalMinutes)
          ? bikeCandidate
          : busCandidate;
    } else if (bikeCandidate != null) {
      chosen = bikeCandidate;
    } else if (busCandidate != null) {
      // WAŻNE: jeśli rower odpadł, a autobus jest możliwy -> wybieramy autobus, nie pieszo
      chosen = busCandidate;
    } else {
      // brak roweru i autobusu – zostaje pieszo
      chosen = walkCandidate;
    }

    // Markery A/B + ewentualne dodatkowe
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
      ...chosen.extraMarkers,
    ];

    // Sumy metrów wg trybu
    double walkM = 0, bikeM = 0, busM = 0;
    for (final s in chosen.steps) {
      switch (s.mode) {
        case 'Pieszo':
          walkM += s.distanceMeters;
          break;
        case 'Rower':
          bikeM += s.distanceMeters;
          break;
        default:
          if (s.mode.startsWith('Autobus')) busM += s.distanceMeters;
      }
    }

    return Plan(
      steps: chosen.steps,
      polylines: chosen.polylines,
      markers: markers,
      walkMeters: walkM,
      busMeters: busM,
      bikeMeters: bikeM,
    );
  }

  // —— Routing z kontrolą błędów (nie dopuszczamy „2 punktów” = prosta) ——
  Future<List<LatLng>> _routeOrThrow(List<LatLng> pts, Profile profile) async {
    final out = await router.route(pts, profile: profile);
    if (out.length <= 2) {
      throw Exception('OSRM zwrócił zbyt krótką geometrię (profile=$profile)');
    }
    return out;
  }

  // ================== WARIANTY ==================

  Future<_Candidate> _walkOnly(LatLng a, LatLng b) async {
    final pts = await _routeOrThrow([a, b], Profile.walking);
    final distKm = _polylineLengthKm(pts);
    final minutes = distKm / walkKmh * 60.0;

    final step = StepItem(
      mode: 'Pieszo',
      from: a,
      to: b,
      distanceMeters: distKm * 1000.0,
      minutes: minutes.round(),
      icon: Icons.directions_walk,
    );

    final poly = Polyline(points: pts, strokeWidth: 4, color: Colors.green);
    return _Candidate(
      label: 'Pieszo',
      totalMinutes: minutes,
      polylines: [poly],
      steps: [step],
    );
  }

  /// Rowery + pieszo — limit długości odcinka rowerowego liczony po REALNYM śladzie OSRM.
  Future<_Candidate?> _bikePlusWalk(
    LatLng start,
    LatLng end,
    List<LatLng> stations,
  ) async {
    final s1 = _nearest(stations, start);
    final s2 = _nearest(stations, end);
    if (s1 == null || s2 == null) return null;

    // Twardy limit dojść pieszych do stacji (po prostej – preselekcja)
    final walkToS1m = _km(start, s1) * 1000.0;
    final walkFromS2m = _km(s2, end) * 1000.0;
    if (walkToS1m > maxWalkToBikeM || walkFromS2m > maxWalkToBikeM) return null;

    // REALNE trasy po ulicach
    final walk1Pts = await _routeOrThrow([start, s1], Profile.walking);
    final ridePts = await _routeOrThrow([s1, s2], Profile.cycling);
    final walk2Pts = await _routeOrThrow([s2, end], Profile.walking);

    final walk1Km = _polylineLengthKm(walk1Pts);
    final rideKm = _polylineLengthKm(ridePts); // realny odcinek rowerem
    final walk2Km = _polylineLengthKm(walk2Pts);

    // Odrzuć rower dopiero, gdy realny odcinek przekracza limit
    if (rideKm > maxBikeLegKm) return null;

    final minutes =
        (walk1Km / walkKmh + rideKm / bikeKmh + walk2Km / walkKmh) * 60.0;

    final steps = <StepItem>[
      StepItem(
        mode: 'Pieszo',
        from: start,
        to: s1,
        distanceMeters: walk1Km * 1000.0,
        minutes: (walk1Km / walkKmh * 60).round(),
        icon: Icons.directions_walk,
      ),
      StepItem(
        mode: 'Rower',
        from: s1,
        to: s2,
        distanceMeters: rideKm * 1000.0,
        minutes: (rideKm / bikeKmh * 60).round(),
        icon: Icons.pedal_bike,
      ),
      StepItem(
        mode: 'Pieszo',
        from: s2,
        to: end,
        distanceMeters: walk2Km * 1000.0,
        minutes: (walk2Km / walkKmh * 60).round(),
        icon: Icons.directions_walk,
      ),
    ];

    final polys = <Polyline>[
      Polyline(points: walk1Pts, strokeWidth: 4, color: Colors.orange),
      Polyline(points: ridePts, strokeWidth: 5, color: Colors.deepOrange),
      Polyline(points: walk2Pts, strokeWidth: 4, color: Colors.orange),
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
      steps: steps,
    );
  }

  /// Autobus + pieszo (po jednej linii), z ograniczeniem dojścia i min. długości przejazdu.
  Future<_Candidate?> _busPlusWalk(
    LatLng start,
    LatLng end,
    Map<String, List<LatLng>> busLines,
  ) async {
    _Candidate? best;

    for (final entry in busLines.entries) {
      final lineId = entry.key;
      final stops = entry.value;
      if (stops.length < 2) continue;

      final iStart = _nearestIndex(stops, start);
      final iEnd = _nearestIndex(stops, end);
      if (iStart == null || iEnd == null) continue;

      // Limity dojścia do/z przystanków (po prostej – preselekcja)
      final walkToStopM = _km(start, stops[iStart]) * 1000.0;
      final walkFromStopM = _km(stops[iEnd], end) * 1000.0;
      if (walkToStopM > maxWalkToBusM || walkFromStopM > maxWalkToBusM)
        continue;

      // Kierunek krótszy po bazowej geometrii przystanków
      final segA = _subsegment(stops, iStart, iEnd);
      final segB = _subsegment(stops, iEnd, iStart);
      final busNodes = (_chainLengthKm(segA) <= _chainLengthKm(segB))
          ? segA
          : segB.reversed.toList();

      if (_chainLengthKm(busNodes) < minBusLegKm) continue;

      // REALNE dojścia i przejazd
      final walk1Pts =
          await _routeOrThrow([start, busNodes.first], Profile.walking);
      final walk2Pts =
          await _routeOrThrow([busNodes.last, end], Profile.walking);

      final busStreetPts = <LatLng>[];
      for (var i = 1; i < busNodes.length; i++) {
        final segPts = await _routeOrThrow(
            [busNodes[i - 1], busNodes[i]], Profile.driving);
        if (busStreetPts.isEmpty) {
          busStreetPts.addAll(segPts);
        } else {
          busStreetPts.addAll(segPts.skip(1));
        }
      }

      final walk1Km = _polylineLengthKm(walk1Pts);
      final busKm = _polylineLengthKm(busStreetPts);
      final walk2Km = _polylineLengthKm(walk2Pts);

      final totalMinutes = busWaitPenaltyMin +
          (walk1Km / walkKmh + busKm / busKmh + walk2Km / walkKmh) * 60.0;

      final steps = <StepItem>[
        StepItem(
          mode: 'Pieszo',
          from: start,
          to: busNodes.first,
          distanceMeters: walk1Km * 1000.0,
          minutes: (walk1Km / walkKmh * 60).round(),
          icon: Icons.directions_walk,
        ),
        StepItem(
          mode: 'Autobus (l.$lineId)',
          from: busNodes.first,
          to: busNodes.last,
          distanceMeters: busKm * 1000.0,
          minutes: (busKm / busKmh * 60).round() + busWaitPenaltyMin.round(),
          icon: Icons.directions_bus,
        ),
        StepItem(
          mode: 'Pieszo',
          from: busNodes.last,
          to: end,
          distanceMeters: walk2Km * 1000.0,
          minutes: (walk2Km / walkKmh * 60).round(),
          icon: Icons.directions_walk,
        ),
      ];

      final polys = <Polyline>[
        Polyline(points: walk1Pts, strokeWidth: 4, color: Colors.blueGrey),
        Polyline(points: busStreetPts, strokeWidth: 5, color: Colors.blue),
        Polyline(points: walk2Pts, strokeWidth: 4, color: Colors.blueGrey),
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
        totalMinutes: totalMinutes,
        polylines: polys,
        extraMarkers: markers,
        steps: steps,
      );

      if (best == null || cand.totalMinutes < best!.totalMinutes) best = cand;
    }
    return best;
  }

  // ================== POMOCNIKI GEO ==================

  double _polylineLengthKm(List<LatLng> pts) {
    if (pts.length < 2) return 0.0;
    double s = 0.0;
    for (var i = 1; i < pts.length; i++) {
      s += _km(pts[i - 1], pts[i]);
    }
    return s;
  }

  double _km(LatLng a, LatLng b) {
    const R = 6371.0;
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
}

// Nośnik kandydata (wewnętrzny)
class _Candidate {
  final String label;
  final double totalMinutes;
  final List<Polyline> polylines;
  final List<Marker> extraMarkers;
  final List<StepItem> steps;

  _Candidate({
    required this.label,
    required this.totalMinutes,
    required this.polylines,
    this.extraMarkers = const [],
    required this.steps,
  });
}
