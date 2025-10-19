// lib/screens/home_screen.dart — ultra-minimal + foto natury w tle (edge-to-edge)
// Styl: nowoczesny, bez ramek, tonal surfaces + glass, czytelność dzięki overlayom.

import 'dart:ui' show lerpDouble, ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'transport_screen.dart';
import 'timetable_screen.dart';
import 'rideshare_screen.dart';
import 'package:flutter/scheduler.dart' show Ticker;

const _kBgImagePath = 'assets/images/nature.png';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _go(HomeDestination d) {
    HapticFeedback.selectionClick();
    final page = {
      HomeDestination.transport: const TransportScreen(),
      HomeDestination.timetable: const TimetableScreen(),
      HomeDestination.rideshare: const RideShareScreen(),
    }[d]!;
    Navigator.of(context).push(_fade(page));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // — TŁO: zdjęcie natury + scrim + miękki gradient dla czytelności typografii
          const _HeroBackground(),

          // — CONTENT
          SafeArea(
            top: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // HEADER — duża typografia, szkło na przewinięciu
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  expandedHeight: 260,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: LayoutBuilder(
                    builder: (context, c) {
                      final h = c.biggest.height;
                      final t = ((h - kToolbarHeight) / (260 - kToolbarHeight))
                          .clamp(0.0, 1.0);
                      final titleSize = lerpDouble(22, 34, t)!;
                      final vis = Curves.easeOut.transform(t);

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          const _HeaderTopScrim(),
                          Align(
                            alignment: Alignment.topCenter,
                            child: _GlassBar(visible: vis < 0.35),
                          ),
                          Positioned(
                            left: 20,
                            bottom: 28,
                            right: 20,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AnimatedOpacity(
                                  opacity: vis,
                                  duration: const Duration(milliseconds: 180),
                                  child: SvgPicture.asset(
                                    'assets/images/herb_plocka.svg',
                                    width: lerpDouble(36, 96, t)!,
                                    height: lerpDouble(36, 96, t)!,
                                    semanticsLabel: 'Herb Płocka',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _TitleBlock(
                                    title: 'Komunikacja w Płocku',
                                    subtitle: 'DOKĄD DZIŚ JEDZIESZ?',
                                    size: titleSize,
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

                // CONTENT — zero ramek, glass/tonal surfaces
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      // Statystyki
                      const _InlineStats(),
                      const SizedBox(height: 14),
                      RewardTickerBar(
                        items: const [
                          RewardTickerItem(
                            text: 'Odbierz przejazd autobusem za 20 punktów',
                            icon: Icons.directions_bus_rounded,
                          ),
                          RewardTickerItem(
                            text: 'Odbierz przejazd rowerem za 10 punktów',
                            icon: Icons.pedal_bike_rounded,
                          ),
                          RewardTickerItem(
                            text: 'Odbierz przejazd hulajnogą za 15 punktów',
                            icon: Icons.electric_scooter_rounded,
                          ),
                        ],
                        height: 42, // wysokość paska
                        gap: 24, // odstęp między elementami
                        speed: 60, // px/s (zwiększ/zmniejsz wedle gustu)
                        pauseOnTouch: true,
                      ),

                      const SizedBox(height: 12),

                      _ActionsList(onTap: _go),
                      const SizedBox(height: 16),
                      const _EcoStrip(),
                    ]),
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

// ————————————————— TŁO —————————————————

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
                  Colors.black.withOpacity(0.40), // mocniejszy top-scrim
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

// ————————————————— UI atoms —————————————————

class _GlassBar extends StatelessWidget {
  const _GlassBar({required this.visible});
  final bool visible;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.40), // półprzezroczysty glass
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock(
      {required this.title, required this.subtitle, required this.size});
  final String title, subtitle;
  final double size;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tytuł skaluje się w dół, zamiast wychodzić poza ekran
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            maxLines: 1,
            softWrap: false,
            style: t.titleLarge?.copyWith(
              fontSize: size,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              shadows: const [Shadow(blurRadius: 6, offset: Offset(0, 2))],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Opacity(
          opacity: 0.9,
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              subtitle,
              maxLines: 1,
              softWrap: false,
              style: t.labelLarge?.copyWith(
                color: cs.onSurface,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
                shadows: const [Shadow(blurRadius: 5, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineStats extends StatelessWidget {
  const _InlineStats();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: const [
          Expanded(
            child: _StatPill(
              icon: Icons.energy_savings_leaf_rounded,
              value: '14',
              caption: 'punkty',
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _StatPill(
              icon:
                  Icons.co2_rounded, // jeśli brak w SDK, użyj Icons.air_rounded
              value: '17.6 kg',
              caption: 'mniej emisji',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.caption,
    this.badge,
  });

  final IconData icon;
  final String value; // duża, czytelna wartość
  final String caption; // mały opis pod spodem
  final String? badge; // np. "CO₂"

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withOpacity(0.80),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // duża, czytelna wartość — zawsze widoczna
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                        shadows: const [
                          Shadow(blurRadius: 3, offset: Offset(0, 1))
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // mały opis + opcjonalna „badżetka” (np. CO₂)
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.labelLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          _Badge(text: badge!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

// ————————————————— Pasek informacyjny —————————————————

class RewardTickerItem {
  final String text;
  final IconData icon;
  const RewardTickerItem({
    required this.text,
    required this.icon,
  });
}

class RewardTickerBar extends StatefulWidget {
  const RewardTickerBar({
    super.key,
    required this.items,
    this.height = 40,
    this.gap = 16,
    this.speed = 50, // px na sekundę
    this.pauseOnTouch = true,
  });

  final List<RewardTickerItem> items;
  final double height;
  final double gap;
  final double speed;
  final bool pauseOnTouch;

  @override
  State<RewardTickerBar> createState() => _RewardTickerBarState();
}

class _RewardTickerBarState extends State<RewardTickerBar>
    with SingleTickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  final _firstRunKey = GlobalKey(); // mierzymy szerokość 1. sekwencji
  late final Ticker _ticker;

  double _singleWidth = 0; // szerokość pojedynczej sekwencji (items + gap)
  double _offset = 0; // aktualny offset scrolla
  Duration _last = Duration.zero;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);

    // Zmierz po pierwszym renderze i odpal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureAndStart();
    });
  }

  void _measureAndStart() {
    final ctx = _firstRunKey.currentContext;
    final size = ctx?.size;
    if (size == null) {
      // Spróbuj w następnym frame, jeśli jeszcze nie zmierzone
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
      return;
    }

    _singleWidth = size.width;
    _offset = 0;
    _last = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _paused || _singleWidth <= 0) return;

    final dt = (elapsed - _last).inMicroseconds / 1e6; // sekundy
    _last = elapsed;

    _offset += widget.speed * dt;
    if (_offset >= _singleWidth) {
      _offset -= _singleWidth;
    }

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.jumpTo(_offset);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final children = widget.items
        .map((e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(e.icon, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  e.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ))
        .toList();

    // Sekwencja do pomiaru (1x) + sekwencja duplikowana (2x) -> płynna pętla
    final firstRun = Row(
      key: _firstRunKey,
      children: _interleave(children, SizedBox(width: widget.gap)),
    );
    final secondRun = Row(
      children: _interleave(children, SizedBox(width: widget.gap)),
    );

    final content =
        Row(children: [firstRun, SizedBox(width: widget.gap), secondRun]);

    Widget strip = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withOpacity(0.70),
          ),
          child: Listener(
            onPointerDown: widget.pauseOnTouch ? (_) => _paused = true : null,
            onPointerUp: widget.pauseOnTouch ? (_) => _paused = false : null,
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: content,
            ),
          ),
        ),
      ),
    );

    return strip;
  }

  // Wstawia separator między elementy (A sep B sep C)
  List<Widget> _interleave(List<Widget> items, Widget sep) {
    if (items.isEmpty) return const [];
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i != items.length - 1) out.add(sep);
    }
    return out;
  }
}

class _ActionsList extends StatelessWidget {
  const _ActionsList({required this.onTap});
  final ValueChanged<HomeDestination> onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w >= 900 ? 3 : (w >= 600 ? 2 : 1);

    const items = [
      _CardData(
        icon: Icons.alt_route_rounded,
        title: 'Planer podróży',
        subtitle: 'Najszybsza trasa',
        dest: HomeDestination.transport,
      ),
      _CardData(
        icon: Icons.schedule_rounded,
        title: 'Rozkłady jazdy',
        subtitle: 'Linie i przystanki',
        dest: HomeDestination.timetable,
      ),
      _CardData(
        icon: Icons.groups_2_rounded,
        title: 'Wspólne przejazdy',
        subtitle: 'Dodaj lub znajdź',
        dest: HomeDestination.rideshare,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 19 / 9,
      ),
      itemBuilder: (context, i) {
        final it = items[i];
        return _ActionTile(
          icon: it.icon,
          title: it.title,
          subtitle: it.subtitle,
          onTap: () => onTap(it.dest),
        );
      },
    );
  }
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: cs.surfaceContainerHigh.withOpacity(0.78),
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              borderRadius: BorderRadius.circular(20),
              splashColor: cs.primary.withOpacity(0.08),
              highlightColor: cs.primary.withOpacity(0.05),
              child: Container(
                constraints: const BoxConstraints(minHeight: 72),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 22,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        size: 20, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EcoStrip extends StatelessWidget {
  const _EcoStrip();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration:
              BoxDecoration(color: cs.primaryContainer.withOpacity(0.18)),
          child: Row(
            children: [
              const Icon(Icons.eco_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jedź z nami — mniej korków, mniej emisji, więcej punktów. 🌿',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ————————————————— Nawigacja & modele —————————————————
PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
        child: child,
      ),
    );

enum HomeDestination { transport, timetable, rideshare }

class _CardData {
  final IconData icon;
  final String title, subtitle;
  final HomeDestination dest;
  const _CardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.dest,
  });
}
