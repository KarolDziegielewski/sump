import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickScreen extends StatefulWidget {
  const MapPickScreen({super.key});

  @override
  State<MapPickScreen> createState() => _MapPickScreenState();
}

class _MapPickScreenState extends State<MapPickScreen> {
  LatLng? _start;
  LatLng? _end;

  void _onTap(TapPosition _, LatLng latlng) {
    setState(() {
      if (_start == null) {
        _start = latlng;
      } else if (_end == null) {
        _end = latlng;
      } else {
        // trzecie i kolejne stuknięcia podmieniają bliższy punkt
        final d = const Distance();
        final ds = d(_start!, latlng);
        final de = d(_end!, latlng);
        if (ds <= de) {
          _start = latlng;
        } else {
          _end = latlng;
        }
      }
    });
  }

  void _clear() => setState(() { _start = null; _end = null; });

  void _confirm() {
    if (_start != null && _end != null) {
      Navigator.pop(context, {'start': _start, 'end': _end});
    }
  }

  @override
  Widget build(BuildContext context) {
    const plock = LatLng(52.5468, 19.7064);

    final markers = <Marker>[
      if (_start != null)
        Marker(point: _start!, width: 40, height: 40, child: const Icon(Icons.flag, size: 36)),
      if (_end != null)
        Marker(point: _end!, width: 40, height: 40, child: const Icon(Icons.place, size: 36)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wybierz start i cel'),
        actions: [IconButton(onPressed: _clear, icon: const Icon(Icons.clear_all), tooltip: 'Wyczyść')],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: plock,
          initialZoom: 13,
          onTap: _onTap,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(markers: markers),
          if (_start != null && _end != null)
            PolylineLayer(polylines: [
              Polyline(points: [_start!, _end!], strokeWidth: 4),
            ]),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            onPressed: (_start != null && _end != null) ? _confirm : null,
            icon: const Icon(Icons.check),
            label: const Text('Zatwierdź'),
          ),
        ),
      ),
    );
  }
}

