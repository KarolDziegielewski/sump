// lib/screens/home_screen.dart — ultra-minimal + foto natury w tle (edge-to-edge)
// Styl: nowoczesny, bez ramek, tonal surfaces + glass, czytelność dzięki overlayom.

import 'dart:ui' show lerpDouble, ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'transport_screen.dart';
import 'timetable_screen.dart';
import 'rideshare_screen.dart';

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
                      // lekki kontener pod statystyki, żeby nie ginęły nad jasnym zdjęciem
                      const _InlineStats(),
                      const SizedBox(height: 14),

                      // === PASEK PRZESUWNY NAD PRZYCISKAMI ===
                      RewardTickerBar(
                        items: const [
                          RewardTickerItem(
                            text: 'Odbierz przejazd autobusem za 20 punktów',
                            asset: 'assets/icons/bus.png', // lub .svg
                          ),
                          RewardTickerItem(
                            text: 'Odbierz przejazd rowerem za 10 punktów',
                            asset: 'assets/icons/bike.svg', // lub .png
                          ),
                        ],
                        height: 42, // dopasowane do „pilli”
                        speed: 70,  // prędkość przewijania w px/s
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
    final style = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.25), // delikatne tło pod pille
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _Pill(
              leading: const Icon(Icons.energy_savings_leaf_rounded, size: 18),
              label: 'Punkty',
              value: '14',
              style: style,
              cs: cs,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Pill(
              leading: const Icon(Icons.air_rounded, size: 18),
              label: ' CO₂',
              value: '17.6 kg',
              style: style,
              cs: cs,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.leading,
    required this.label,
    required this.value,
    required this.style,
    required this.cs,
  });
  final Widget leading;
  final String label, value;
  final TextTheme style;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            // wyższa opacity → nie ginie na tle zdjęcia
            color: cs.surfaceContainerHigh.withOpacity(0.80),
          ),
          child: w < 360
              // NA BARDZO WĄSKICH: układ dwuwierszowy (label nad value) – zawsze czytelnie
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconTheme.merge(
                          data: const IconThemeData(size: 20),
                          child: leading,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              style: style.labelLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                                shadows: const [
                                  Shadow(blurRadius: 3, offset: Offset(0, 1))
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: style.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                        shadows: const [
                          Shadow(blurRadius: 3, offset: Offset(0, 1))
                        ],
                      ),
                    ),
                  ],
                )
              // STANDARD: w jednym wierszu; label skaluje się, więc ZAWSZE się mieści
              : Row(
                  children: [
                    IconTheme.merge(
                      data: const IconThemeData(size: 20),
                      child: leading,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          style: style.labelLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            shadows: const [
                              Shadow(blurRadius: 3, offset: Offset(0, 1))
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      value,
                      style: style.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                        shadows: const [
                          Shadow(blurRadius: 3, offset: Offset(0, 1))
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

// === PASEK — definicje widgetów ===

class RewardTickerItem {
  final String text;
  final String? asset;   // np. 'assets/icons/bus.png' lub 'assets/icons/bike.svg'
  final double gap;      // odstęp między wpisami
  const RewardTickerItem({required this.text, this.asset, this.gap = 48});
}

class RewardTickerBar extends StatefulWidget {
  final List<RewardTickerItem> items;
  final double height;
  final double speed; // px/s

  const RewardTickerBar({
    super.key,
    required this.items,
    this.height = 40,
    this.speed = 60,
  });

  @override
  State<RewardTickerBar> createState() => _RewardTickerBarState();
}

class _RewardTickerBarState extends State<RewardTickerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _contentKey = GlobalKey();
  double _contentWidth = 0;

@override
void initState() {
  super.initState();
  _ctrl = AnimationController.unbounded(vsync: this)
    ..addListener(() => setState(() {}))
    // <= kluczowa zmiana: żadnych nieskończoności
    ..repeat(min: 0.0, max: 1.0, period: const Duration(days: 1));
}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache obrazków rastrowych (SVG nie wspiera precacheImage)
    for (final it in widget.items) {
      final a = it.asset;
      if (a == null) continue;
      if (!a.toLowerCase().endsWith('.svg')) {
        precacheImage(AssetImage(a), context);
      }
    }
    // Poznaj szerokość zawartości po pierwszym kadrze
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && mounted) {
        setState(() => _contentWidth = box.size.width);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surfaceContainerHigh.withOpacity(0.80);
    final border = cs.outlineVariant.withOpacity(0.35);

    final tMs = _ctrl.lastElapsedDuration?.inMilliseconds ?? 0;
    final offset =
        _contentWidth == 0 ? 0.0 : ((tMs / 1000.0) * widget.speed) % _contentWidth;

    Widget buildItemsRow() {
      final ts = Theme.of(context).textTheme.labelLarge;
      return Row(
        key: _contentKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final it in widget.items) ...[
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (it.asset != null) ...[
                _TickerIcon(asset: it.asset!),
                const SizedBox(width: 8),
              ],
              Text(it.text, style: ts),
            ]),
            SizedBox(width: it.gap),
          ],
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // delikatne wygaszenie brzegów
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
                  stops: [0.0, 0.08, 0.92, 1.0],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: const SizedBox.expand(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: LayoutBuilder(
                  builder: (_, __) {
                    if (_contentWidth == 0) {
                      // pierwszy kadr, zanim poznamy szerokość treści
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: buildItemsRow(),
                      );
                    }
                    // dwie kopie — ciągła pętla, brak przerw i nakładania
                    return Stack(children: [
                      Transform.translate(
                        offset: Offset(-offset, 0),
                        child: buildItemsRow(),
                      ),
                      Transform.translate(
                        offset: Offset(_contentWidth - offset, 0),
                        child: buildItemsRow(),
                      ),
                    ]);
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

class _TickerIcon extends StatelessWidget {
  final String asset;
  const _TickerIcon({required this.asset});

  @override
  Widget build(BuildContext context) {
    const size = 18.0;
    if (asset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(asset, width: size, height: size);
    }
    return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
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
