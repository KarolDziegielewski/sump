import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'transport_screen.dart';
import 'timetable_screen.dart';

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

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // GRADIENT TŁA + animowane „blobsy” (nowoczesny vibe)
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) {
              final t = _bgCtrl.value;
              return CustomPaint(
                painter: _BlobsPainter(
                  cs.primary.withOpacity(0.22),
                  cs.secondary.withOpacity(0.18),
                  cs.tertiary.withOpacity(0.16),
                  t,
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.surface, cs.surface.withOpacity(0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // TREŚĆ
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Nagłówek
                  Text(
                    'Płock – komunikacja',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wybierz jak chcesz zacząć',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),

                  // DWA PRZYCISKI – „glass cards” z animacją skali
                  _BigChoiceCard(
                    icon: Icons.alt_route_rounded,
                    title: 'Plnaer Podróży',
                    subtitle: 'Szybkie planowanie trasy',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        _fadeRoute(const TransportScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _BigChoiceCard(
                    icon: Icons.schedule_rounded,
                    title: 'Rozkłady jazdy',
                    subtitle: 'Linie i przystanki w jednym miejscu',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        _fadeRoute(const TimetableScreen()),
                      );
                    },
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// „Glass” karta z animacją Scale + Hover (desktop/web) + efekt blur
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
                  color: cs.surface.withOpacity(0.6),
                  border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.08),
                      blurRadius: 30,
                      spreadRadius: 0,
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
                            cs.primaryContainer,
                            cs.primary.withOpacity(0.6)
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
                          Text(widget.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  )),
                          const SizedBox(height: 4),
                          Text(widget.subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  )),
                        ],
                      ),
                    ),
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

// Fade route (nowocześniejsze przejście niż domyślne)
PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      ),
    );

// Prosty painter animowanych blosów (bez zależności zewnętrznych)
class _BlobsPainter extends CustomPainter {
  final Color a, b, c;
  final double t;
  _BlobsPainter(this.a, this.b, this.c, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // krążki poruszające się po sinusach
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
