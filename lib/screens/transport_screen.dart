import 'package:flutter/material.dart';
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

    final start = result['start'];
    final end = result['end'];
    setState(() {
      if (start != null) {
        _startCtrl.text =
            '${start.latitude.toStringAsFixed(6)}, ${start.longitude.toStringAsFixed(6)}';
      }
      if (end != null) {
        _endCtrl.text =
            '${end.latitude.toStringAsFixed(6)}, ${end.longitude.toStringAsFixed(6)}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planer Podróży')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _startCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Punkt startowy',
                hintText: 'Adres lub współrzędne',
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
                hintText: 'Adres lub współrzędne',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Icons.map),
                label: const Text('Wybierz na mapie'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
