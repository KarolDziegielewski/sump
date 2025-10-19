import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bus_timetable_screen.dart';
import 'bike_route_screen.dart';

enum TransportType { bike, bus }

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with TickerProviderStateMixin {
  TransportType? selected;
  int _hoveredIndex = -1;

  late final List<_TransportCardData> transports = [
    _TransportCardData(
      type: TransportType.bike,
      name: 'Rower',
      icon: Icons.pedal_bike,
      colorSeed: Colors.green,
      destinationBuilder: (_) => const BikeRouteScreen(),
    ),
    _TransportCardData(
      type: TransportType.bus,
      name: 'Autobus',
      icon: Icons.directions_bus,
      colorSeed: Colors.blue,
      destinationBuilder: (_) => const BusTimetableScreen(),
    ),
  ];

  void _goTo(_TransportCardData item) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, a1, a2) => item.destinationBuilder(ctx),
        transitionsBuilder: (ctx, anim, __, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rozkłady jazdy'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(cs: cs),
              const SizedBox(height: 16),
              const SizedBox(height: 14),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = constraints.maxWidth;
                    // Responsywna liczba kolumn
                    final crossAxisCount = maxW >= 900
                        ? 4
                        : maxW >= 640
                            ? 3
                            : 2;
                    return GridView.builder(
                      itemCount: transports.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final item = transports[index];
                        final isSelected = selected == item.type;
                        final isHovered = _hoveredIndex == index;

                        return _TransportCard(
                          item: item,
                          isSelected: isSelected,
                          isHovered: isHovered,
                          onHover: (h) =>
                              setState(() => _hoveredIndex = h ? index : -1),
                          onTap: () {
                            setState(() => selected = item.type);
                            _goTo(item);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary.withOpacity(.10), cs.secondary.withOpacity(.06)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.schedule, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wybierz środek transportu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Szybki dostęp do rozkładów i tras',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportCard extends StatelessWidget {
  const _TransportCard({
    required this.item,
    required this.isSelected,
    required this.isHovered,
    required this.onHover,
    required this.onTap,
  });

  final _TransportCardData item;
  final bool isSelected;
  final bool isHovered;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final baseColor = Color.alphaBlend(
      (item.colorSeed.withOpacity(.08)),
      cs.surface,
    );

    final borderColor = isSelected ? item.colorSeed : cs.outlineVariant;

    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowFocusHighlight: (_) {},
      child: MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: Semantics(
          button: true,
          label: item.name,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            scale: isHovered || isSelected ? 1.02 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: isSelected ? baseColor : cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(.06),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 56,
                        color:
                            isSelected ? item.colorSeed : cs.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? item.colorSeed : cs.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitleFor(item.type),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _subtitleFor(TransportType type) {
    switch (type) {
      case TransportType.bike:
        return 'Stacje rowerów miejskich';
      case TransportType.bus:
        return 'Linie, przystanki, odjazdy';
    }
  }
}

class _TransportCardData {
  final TransportType type;
  final String name;
  final IconData icon;
  final Color colorSeed;
  final WidgetBuilder destinationBuilder;

  const _TransportCardData({
    required this.type,
    required this.name,
    required this.icon,
    required this.colorSeed,
    required this.destinationBuilder,
  });
}
