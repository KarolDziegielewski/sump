import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'map_pick_screen.dart';

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();

  LatLng? _start;
  LatLng? _end;
  int? _etaSec;          // przewidywany czas (MVP: pieszo)
  double? _distanceM;    // odległość po prostej

  final Distance _dist = const Distance();

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, LatLng?>>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickScreen()),
    );
    if (!mounted || result == null) return;

    final s = result['start'];
    final e = result['end'];

    setState(() {
      _start = s;
      _end = e;

      if (s != null) {
        _startCtrl.text = '${s.latitude.toStringAsFixed(6)}, ${s.longitude.toStringAsFixed(6)}';
      }
      if (e != null) {
        _endCtrl.text = '${e.latitude.toStringAsFixed(6)}, ${e.longitude.toStringAsFixed(6)}';
      }

      _recomputeEta();
    });
  }

  void _recomputeEta() {
    if (_start == null || _end == null) {
      _etaSec = null;
      _distanceM = null;
      return;
    }
    _distanceM = _dist(_start!, _end!); // metry (haversine)
    const walkSpeedMs = 1.4;            // ~5 km/h (MVP)
    _etaSec = (_distanceM! / walkSpeedMs).round();

    // 🔁 W NASTĘPNYM KROKU podmienimy to na Wasz routing (bus/rower/pieszo) i realny przebieg.
  }

  String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final mm = m % 60;
      return '${h}h ${mm}m';
    }
    return '${m}m ${s}s';
  }

  Widget _buildPreviewMap() {
    if (_start == null || _end == null) return const SizedBox.shrink();

    final center = LatLng(
      (_start!.latitude + _end!.latitude) / 2,
      (_start!.longitude + _end!.longitude) / 2,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            PolylineLayer(polylines: [
              Polyline(points: [_start!, _end!], strokeWidth: 4),
            ]),
            MarkerLayer(markers: [
              Marker(point: _start!, width: 40, height: 40, child: const Icon(Icons.flag, size: 32)),
              Marker(point: _end!, width: 40, height: 40, child: const Icon(Icons.place, size: 32)),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etaText = (_etaSec != null)
        ? 'Szacowany czas (MVP – pieszo): ${_fmtDuration(_etaSec!)}'
        : null;
    final distText = (_distanceM != null)
        ? 'Dystans: ${(_distanceM!/1000).toStringAsFixed(2)} km'
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Planer Podróży')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _startCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Punkt startowy',
                hintText: 'Np. Stary Rynek 1, Płock',
                prefixIcon: Icon(Icons.my_location),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _endCtrl,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Punkt docelowy',
                hintText: 'Np. Dworzec PKP Płock',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openMapPicker,
              icon: const Icon(Icons.map),
              label: const Text('Wybierz na mapie'),
            ),

            // ——— WYNIK POD PRZYCISKAMI ———
            if (etaText != null || distText != null) ...[
              const SizedBox(height: 12),
              if (etaText != null) Text(etaText, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (distText != null) Text(distText),
              const SizedBox(height: 8),
              _buildPreviewMap(),
            ],
          ],
        ),
      ),
    );
  }
}
