// lib/screens/ranking_screen.dart
import 'dart:ui' show lerpDouble, ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// używamy tego samego tła co na Home
const _kBgImagePath = 'assets/images/nature.png';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // przykładowe dane (TOP 20) — kg „niewyemitowanego” CO2
    final entries = _sampleRanking().toList()
      ..sort((a, b) => b.co2SavedKg.compareTo(a.co2SavedKg));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          const _HeroBackground(),
          SafeArea(
            top: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  expandedHeight: 220,
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  flexibleSpace: LayoutBuilder(
                    builder: (context, c) {
                      final h = c.biggest.height;
                      final t = ((h - kToolbarHeight) / (220 - kToolbarHeight))
                          .clamp(0.0, 1.0);
                      final titleSize = lerpDouble(20, 30, t)!;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          const _HeaderTopScrim(),
                          Positioned(
                            left: 20,
                            bottom: 22,
                            right: 20,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/herb_plocka.svg',
                                  width: lerpDouble(28, 44, t)!,
                                  height: lerpDouble(28, 44, t)!,
                                  semanticsLabel: 'Herb Płocka',
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Ranking',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                      shadows: const [
                                        Shadow(
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Lista w szkle
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  sliver: SliverList.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final rank = i + 1;
                      final e = entries[i];
                      return _GlassTile(
                        rank: rank,
                        name: e.name,
                        co2SavedKg: e.co2SavedKg,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ————————————————— UI & model —————————————————

class _HeroBackground extends StatelessWidget {
  const _HeroBackground();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_kBgImagePath, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.40),
                  cs.surface.withOpacity(0.12),
                  cs.surface.withOpacity(0.36),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTopScrim extends StatelessWidget {
  const _HeaderTopScrim();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.35), Colors.transparent],
        ),
      ),
    );
  }
}

class _GlassTile extends StatelessWidget {
  const _GlassTile({
    required this.rank,
    required this.name,
    required this.co2SavedKg,
  });

  final int rank;
  final String name;
  final double co2SavedKg;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withOpacity(0.78),
          ),
          child: Row(
            children: [
              // Miejsce w rankingu (badge)
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: t.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: rank <= 3 ? cs.onPrimaryContainer : cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar z inicjałami + imię
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(name),
                  style: t.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Nazwisko
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),

              // Wartość CO2
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.co2_rounded, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${co2SavedKg.toStringAsFixed(1)} kg',
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ————————————————— Dane —————————————————

class _RankingEntry {
  final String name;
  final double co2SavedKg;
  const _RankingEntry(this.name, this.co2SavedKg);
}

List<_RankingEntry> _sampleRanking() => const [
      _RankingEntry('AnkatorZPiekarni', 42.3),
      _RankingEntry('JanekBezKaptura', 39.8),
      _RankingEntry('KasiaZKosmosu', 37.2),
      _RankingEntry('PanZielonyMakaron', 35.5),
      _RankingEntry('MichałNaKacu', 33.1),
      _RankingEntry('AgaWKapciach', 31.9),
      _RankingEntry('TomekZKartonu', 29.4),
      _RankingEntry('EwkaXD9000', 28.7),
      _RankingEntry('PawełZiemniak', 27.9),
      _RankingEntry('JoannaWłóczykij', 26.4),
      _RankingEntry('MatełuszWafel', 25.8),
      _RankingEntry('MagdaNaBuncie', 24.6),
      _RankingEntry('KamilZPlacka', 23.9),
      _RankingEntry('NatixZPiekłaRodem', 22.7),
      _RankingEntry('RafiBekon', 21.3),
      _RankingEntry('MoniaCzosnek', 20.8),
      _RankingEntry('DamianZKanapy', 19.6),
      _RankingEntry('JulkaWChmurach', 18.2),
      _RankingEntry('WikuśZBrokułem', 17.5),
      _RankingEntry('OliwiaZInternetu', 16.9),
    ];

// ————————————————— Utils —————————————————

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '';
  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final second = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  return (first + second).toUpperCase();
}
