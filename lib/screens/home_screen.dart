import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // tylko na Web, ok dzięki kIsWeb
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marquee/marquee.dart';
import 'transport_screen.dart';
import 'timetable_screen.dart';
import 'rideshare_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _bgCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Ustaw tytuł karty w przeglądarce (Web)
    if (kIsWeb) {
      html.document.title = 'Komunikacja Płock – planuj i jedź';
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _GlassAppBar(
        title: 'Komunikacja w Płocku',
        leading: _CoatOfArmsBadge(),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // TŁO
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) {
              final t = _bgCtrl.value;
              return CustomPaint(
                painter: _BlobsPainter(
                  _tone(cs.primary, 0.20),
                  _tone(cs.tertiary, 0.16),
                  _tone(cs.secondary, 0.14),
                  t,
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.surface, cs.surface.withOpacity(0.72)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // TREŚĆ (scrollowalna -> brak overflow na niskich ekranach)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final isMedium = constraints.maxWidth >= 640 && !isWide;

                final content = isWide
                    ? _WideLayout(onNavigate: _onNavigate)
                    : _NarrowLayout(onNavigate: _onNavigate, medium: isMedium);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 88, 16, 110),
                  physics: const BouncingScrollPhysics(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: content,
                  ),
                );
              },
            ),
          ),

          // PASEK MARQUEE (DOKOWANY NA DOLE)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _GlassBar(
                height: 48,
                child: _MarqueePromo(color: cs.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _tone(Color base, double opacity) => HSLColor.fromColor(base)
      .withLightness(0.75)
      .toColor()
      .withOpacity(opacity);

  void _onNavigate(HomeDestination dest) {
    HapticFeedback.selectionClick();
    Widget page;
    switch (dest) {
      case HomeDestination.transport:
        page = const TransportScreen();
        break;
      case HomeDestination.timetable:
        page = const TimetableScreen();
        break;
      case HomeDestination.rideshare:
        page = const RideShareScreen();
        break;
    }
    Navigator.push(context, _fadeRoute(page));
  }
}

// ————————————————————————————————————————————————————————————————
// LAYOUTS
// ————————————————————————————————————————————————————————————————

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.onNavigate, required this.medium});
  final ValueChanged<HomeDestination> onNavigate;
  final bool medium;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey('narrow'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _TitleAndSubtitle(
          title: 'Komunikacja w Płocku',
          subtitle: 'Dokąd dziś jedziesz?',
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(
              child: _StatTile(
                title: 'Punkty',
                value: '14',
                icon: Icons.energy_savings_leaf_rounded,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                title: 'Zaoszczędzone CO₂',
                value: '17.6 kg',
                icon: Icons.co2_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _CardsGrid(
          columns: medium ? 2 : 1,
          onNavigate: onNavigate,
        ),
        const SizedBox(height: 24),
        const _EcoTip(),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.onNavigate});
  final ValueChanged<HomeDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('wide'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        // LEWA KOLUMNA — tytuł + statystyki + tip
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TitleAndSubtitle(
                title: 'Komunikacja w Płocku',
                subtitle: 'Dokąd dziś jedziesz?',
              ),
              SizedBox(height: 16),
              _WideStatsRow(),
              SizedBox(height: 16),
              _EcoTip(),
            ],
          ),
        ),
        SizedBox(width: 20),
        // PRAWA KOLUMNA — karty
        Expanded(
          flex: 7,
          child: _CardsGrid(columns: 2),
        ),
      ],
    );
  }
}

class _TitleAndSubtitle extends StatelessWidget {
  const _TitleAndSubtitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.left,
          softWrap: true,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          softWrap: true,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _WideStatsRow extends StatelessWidget {
  const _WideStatsRow();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatTile(
            title: 'Punkty',
            value: '14',
            icon: Icons.energy_savings_leaf_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            title: 'Zaoszczędzone CO₂',
            value: '17.6 kg',
            icon: Icons.co2_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            title: 'Aktywne bilety',
            value: '1',
            icon: Icons.confirmation_number_rounded,
          ),
        ),
      ],
    );
  }
}

class _CardsGrid extends StatelessWidget {
  const _CardsGrid({required this.columns, this.onNavigate});
  final int columns;
  final ValueChanged<HomeDestination>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // na wąskich ekranach karty wyższe, by uniknąć overflowu
    final aspect = width < 360 ? (14 / 9) : (width < 420 ? (16 / 9) : (21 / 9));

    final items = const [
      _CardData(
        icon: Icons.alt_route_rounded,
        title: 'Planer podróży',
        subtitle: 'Zaplanuj najszybszą trasę',
        dest: HomeDestination.transport,
      ),
      _CardData(
        icon: Icons.schedule_rounded,
        title: 'Rozkłady jazdy',
        subtitle: 'Linie i przystanki w jednym miejscu',
        dest: HomeDestination.timetable,
      ),
      _CardData(
        icon: Icons.groups_2_rounded,
        title: 'Wspólne przejazdy',
        subtitle: 'Dodaj lub znajdź przejazd',
        dest: HomeDestination.rideshare,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: aspect,
      ),
      itemBuilder: (context, i) {
        final it = items[i];
        return _BigChoiceCard(
          icon: it.icon,
          title: it.title,
          subtitle: it.subtitle,
          onTap: () => onNavigate?.call(it.dest),
        );
      },
    );
  }
}

// ————————————————————————————————————————————————————————————————
// WIDGETS
// ————————————————————————————————————————————————————————————————

class _CoatOfArmsBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.55),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/herb_plocka.svg',
                width: 24,
                height: 24,
                semanticsLabel: 'Herb Płocka',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _GlassAppBar({required this.title, this.leading});
  final String title;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 12);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      leading: leading,
      title: Text(title),
      centerTitle: true,
      backgroundColor: cs.surface.withOpacity(0.55),
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _GlassBar extends StatelessWidget {
  const _GlassBar({required this.child, this.height = 44});
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.65),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _EcoTip extends StatelessWidget {
  const _EcoTip();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.primary;
    final gradient = LinearGradient(
      colors: [
        HSLColor.fromColor(base).withLightness(0.8).toColor().withOpacity(0.9),
        base.withOpacity(0.12),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Semantics(
      label: 'Porada ekologiczna',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/images/herb_plocka.svg',
              width: 28,
              height: 28,
              semanticsLabel: 'Herb Płocka',
            ),
            const SizedBox(width: 12),
            const Icon(Icons.eco_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Jedź z nami — mniej korków, mniej emisji, więcej punktów. 🌿',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarqueePromo extends StatelessWidget {
  const _MarqueePromo({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text =
        '🎫 Darmowy bilet za 20 pkt     🚲 Przejazd rowerem za 10 pkt     🌱 #EkoPłock — dołącz i zgarnij bonus     ';
    return Semantics(
      label: 'Promocje i komunikaty',
      child: Marquee(
        text: text,
        blankSpace: 64,
        velocity: 45,
        pauseAfterRound: const Duration(seconds: 1),
        startPadding: 16,
        accelerationDuration: const Duration(seconds: 1),
        decelerationDuration: const Duration(milliseconds: 800),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.1,
            ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  const _StatTile({required this.title, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.65),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        cs.primaryContainer.withOpacity(0.9),
                        cs.primary.withOpacity(0.6)
                      ],
                    ),
                  ),
                  child: Icon(icon, size: 22, color: cs.onPrimaryContainer),
                ),
              if (icon != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            )),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
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

class _BigChoiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BigChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_BigChoiceCard> createState() => _BigChoiceCardState();
}

class _BigChoiceCardState extends State<_BigChoiceCard> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scale = _pressed ? 0.98 : (_hover ? 1.01 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: cs.surface.withOpacity(0.65),
                  border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            HSLColor.fromColor(cs.primaryContainer)
                                .withLightness(0.78)
                                .toColor(),
                            cs.primary.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: Icon(widget.icon,
                          size: 28, color: cs.onPrimaryContainer),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        color: cs.onSurfaceVariant),
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

// Fade route (ładne przejście)
PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      ),
    );

// Painter blobów w tle
class _BlobsPainter extends CustomPainter {
  final Color a, b, c;
  final double t;
  _BlobsPainter(this.a, this.b, this.c, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    void blob(Color color, double r, Offset center) {
      final paint = Paint()..color = color;
      canvas.drawCircle(center, r, paint);
    }

    blob(
        a,
        w * 0.35,
        Offset(
            w * (0.25 + 0.05 * _s(1.0 * t)), h * (0.25 + 0.04 * _s(1.4 * t))));
    blob(
        b,
        w * 0.40,
        Offset(
            w * (0.8 + 0.04 * _s(0.8 * t)), h * (0.28 + 0.05 * _s(1.2 * t))));
    blob(
        c,
        w * 0.32,
        Offset(
            w * (0.55 + 0.05 * _s(1.3 * t)), h * (0.78 + 0.04 * _s(0.9 * t))));
  }

  double _s(double x) =>
      (Tween(begin: -1.0, end: 1.0).transform((x % 1))).abs() * 2 - 1;

  @override
  bool shouldRepaint(covariant _BlobsPainter old) =>
      old.t != t || old.a != a || old.b != b || old.c != c;
}

// ————————————————————————————————————————————————————————————————
// MODELS
// ————————————————————————————————————————————————————————————————

enum HomeDestination { transport, timetable, rideshare }

class _CardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final HomeDestination dest;
  const _CardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.dest,
  });
}
