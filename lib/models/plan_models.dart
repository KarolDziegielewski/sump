import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class StepItem {
  final String mode; // 'Pieszo' | 'Autobus (...)' | 'Rower'
  final LatLng from;
  final LatLng to;
  final double distanceMeters;
  final int minutes;
  final IconData icon;

  StepItem({
    required this.mode,
    required this.from,
    required this.to,
    required this.distanceMeters,
    required this.minutes,
    required this.icon,
  });
}

class Plan {
  final List<StepItem> steps; // kroki dla panelu
  final List<Polyline> polylines; // odcinki do narysowania
  final List<Marker> markers; // A, B, użyte przystanki/stacje
  final double walkMeters;
  final double busMeters;
  final double bikeMeters;

  Plan({
    required this.steps,
    required this.polylines,
    required this.markers,
    required this.walkMeters,
    required this.busMeters,
    required this.bikeMeters,
  });

  /// Wszystkie punkty (bez duplikatów) do dopasowania kamery
  List<LatLng> allPoints() {
    final pts = <LatLng>[];
    for (final s in steps) {
      pts.add(s.from);
      pts.add(s.to);
    }
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
