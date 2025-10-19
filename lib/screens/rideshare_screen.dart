import 'package:flutter/material.dart';

class RideShareScreen extends StatefulWidget {
  const RideShareScreen({super.key});

  @override
  State<RideShareScreen> createState() => _RideShareScreenState();
}

class _RideShareScreenState extends State<RideShareScreen> {
  // Formularz
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController(text: '1');
  final _noteCtrl = TextEditingController();

  // Filtr listy
  final _filterCtrl = TextEditingController();

  // MVP: pamięciowa lista ogłoszeń
  final List<RideAd> _ads = [
    RideAd(
        from: 'Wyszogrodzka', to: 'Radzanowo', seats: 2, note: 'Wyjazd 17:30'),
    RideAd(
        from: 'Kobylińskiego', to: 'Stara Biała', seats: 1, note: 'Jutro rano'),
    RideAd(
        from: 'Małachowskiego 1',
        to: 'Politechnika Warszawska',
        seats: 3,
        note: 'Po pracy ~18:00'),
  ];

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _seatsCtrl.dispose();
    _noteCtrl.dispose();
    _filterCtrl.dispose();
    super.dispose();
  }

  void _addAd() {
    final from = _fromCtrl.text.trim();
    final to = _toCtrl.text.trim();
    final seats = int.tryParse(_seatsCtrl.text.trim());
    if (from.isEmpty || to.isEmpty || seats == null || seats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uzupełnij: skąd, dokąd, liczba miejsc.')),
      );
      return;
    }
    setState(() {
      _ads.add(RideAd(
          from: from, to: to, seats: seats, note: _noteCtrl.text.trim()));
      _fromCtrl.clear();
      _toCtrl.clear();
      _seatsCtrl.text = '1';
      _noteCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 900;

    final filtered = _ads.where((ad) {
      final q = _filterCtrl.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return ad.to.toLowerCase().contains(q);
    }).toList();

    final leftForm = _GlassCard(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Dodaj ogłoszenie',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _fromCtrl,
              decoration: const InputDecoration(
                  labelText: 'Skąd jedziesz', border: OutlineInputBorder()),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _toCtrl,
              decoration: const InputDecoration(
                  labelText: 'Dokąd jedziesz (miejsce docelowe)',
                  border: OutlineInputBorder()),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _seatsCtrl,
              decoration: const InputDecoration(
                  labelText: 'Liczba miejsc', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'Informacje (godzina, bagaż...)',
                  border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _addAd,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj ogłoszenie'),
              ),
            ),
          ],
        ),
      ),
    );

    final rightList = _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ogłoszenia innych',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _filterCtrl,
            decoration: const InputDecoration(
              labelText: 'Filtruj po miejscu docelowym',
              hintText: 'np. Podolszyce',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('Brak ogłoszeń dla podanego miejsca',
                        style: TextStyle(color: cs.onSurfaceVariant)))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _AdTile(ad: filtered[i]),
                  ),
          ),
        ],
      ),
    );

    // 2) Układ wąski – usuń sztywną wysokość listy
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/blablacar.png',
              height: 60, // dostosuj w razie potrzeby
            ),
            const SizedBox(width: 12),
            const Text('Wspólne przejazdy'),
          ],
        ),
      ),

      // opcjonalnie: resizeToAvoidBottomInset: true, // domyślnie true
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: leftForm),
                    const SizedBox(width: 20),
                    Expanded(child: rightList),
                  ],
                )
              : Column(
                  children: [
                    leftForm,
                    const SizedBox(height: 20),
                    Expanded(
                        child:
                            rightList), // <-- zamiast SizedBox(height: 420, ...)
                  ],
                ),
        ),
      ),
    );
  }
}

class RideAd {
  final String from;
  final String to;
  final int seats;
  final String note;
  RideAd(
      {required this.from,
      required this.to,
      required this.seats,
      required this.note});
}

class _AdTile extends StatelessWidget {
  final RideAd ad;
  const _AdTile({required this.ad});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${ad.from} → ${ad.to}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(ad.note, style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Chip(label: Text('${ad.seats} miejsc')),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
