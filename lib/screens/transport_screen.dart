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
  int? _etaSec; // przewidywany czas (MVP: pieszo)
  double? _distanceM; // odległość po prostej

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
        _startCtrl.text =
            '${s.latitude.toStringAsFixed(6)}, ${s.longitude.toStringAsFixed(6)}';
      }
      if (e != null) {
        _endCtrl.text =
            '${e.latitude.toStringAsFixed(6)}, ${e.longitude.toStringAsFixed(6)}';
      }

      _recomputeEta();
    });
  }

  void _swapPoints() {
    setState(() {
      final tmp = _start;
      _start = _end;
      _end = tmp;

      final t = _startCtrl.text;
      _startCtrl.text = _endCtrl.text;
      _endCtrl.text = t;

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
    const walkSpeedMs = 1.4; // ~5 km/h (MVP)
    _etaSec = (_distanceM! / walkSpeedMs).round();
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

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary.withOpacity(.12), cs.secondary.withOpacity(.06)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.directions, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Planer podróży',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, String hint, IconData icon,
      {VoidCallback? onClear}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      suffixIcon: onClear == null
          ? null
          : IconButton(
              tooltip: 'Wyczyść',
              onPressed: onClear,
              icon: const Icon(Icons.clear),
            ),
    );
  }

  Widget _buildInputsCard(BuildContext context) {
    final card = Card(
      elevation: 1.5,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          children: [
            TextField(
              controller: _startCtrl,
              textInputAction: TextInputAction.next,
              decoration: _inputDeco(
                'Punkt startowy',
                'Np. Stary Rynek 1, Płock',
                Icons.my_location,
                onClear: _startCtrl.text.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _startCtrl.clear();
                          _start = null;
                          _recomputeEta();
                        });
                      },
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _endCtrl,
              textInputAction: TextInputAction.done,
              decoration: _inputDeco(
                'Punkt docelowy',
                'Np. Dworzec PKP Płock',
                Icons.location_on,
                onClear: _endCtrl.text.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _endCtrl.clear();
                          _end = null;
                          _recomputeEta();
                        });
                      },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map),
                    label: const Text('Wybierz na mapie'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed:
                      (_start != null || _end != null) ? _swapPoints : null,
                  icon: const Icon(Icons.swap_vert),
                  label: const Text('Zamień'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return card;
  }

  Widget _statChip(IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPreviewMap() {
    if (_start == null || _end == null) return const SizedBox.shrink();

    final center = LatLng(
      (_start!.latitude + _end!.latitude) / 2,
      (_start!.longitude + _end!.longitude) / 2,
    );

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 240,
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
                Polyline(points: [_start!, _end!], strokeWidth: 5),
              ]),
              MarkerLayer(markers: [
                Marker(
                  point: _start!,
                  width: 44,
                  height: 44,
                  child: const Icon(Icons.flag, size: 32),
                ),
                Marker(
                  point: _end!,
                  width: 44,
                  height: 44,
                  child: const Icon(Icons.place, size: 32),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etaText = (_etaSec != null) ? _fmtDuration(_etaSec!) : null;
    final distText = (_distanceM != null)
        ? '${(_distanceM! / 1000).toStringAsFixed(2)} km'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planer podróży'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 14),
              _buildInputsCard(context),

              // ——— WYNIK POD PRZYCISKAMI ———
              if (etaText != null || distText != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (etaText != null)
                      _statChip(Icons.schedule, 'Czas: $etaText'),
                    if (distText != null)
                      _statChip(Icons.straighten, 'Dystans: $distText'),
                    _statChip(Icons.directions_walk, 'MVP: pieszo'),
                  ],
                ),
                const SizedBox(height: 10),
                _buildPreviewMap(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
