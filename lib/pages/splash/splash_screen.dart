import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/navigation/bottom_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const Duration _animationDuration = Duration(milliseconds: 9000);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _controller
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          _goToNextPage();
        }
      });
  }

void _goToNextPage() {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SikapBottomNavigationBar(
          isAdmin: false,
        ),
      ),
    );
    return;
  }

  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 900),
      reverseTransitionDuration: const Duration(milliseconds: 900),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SikapBottomNavigationBar(
          isAdmin: false,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    ),
  );
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _interval(double start, double end) {
    return _normalizeInterval(_controller.value, start, end);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFE9E5D6),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final double value = _controller.value;

            final double holeOpacity =
                _interval(0.42, 0.50) * (1 - _interval(0.68, 0.76));

            final double welcomeOpacity =
                _interval(0.48, 0.58) * (1 - _interval(0.66, 0.76));

            final double welcomeRise = 26 * (1 - Curves.easeOutCubic.transform(
                  _interval(0.48, 0.58),
                ));

            final double floatingOffset =
                math.sin(value * math.pi * 8) * 3.5 * welcomeOpacity;

            final double logoOpacity = _interval(0.83, 0.96);

            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _SplashBackgroundPainter(progress: value),
                ),

                Align(
                  alignment: const Alignment(0, 0.08),
                  child: Opacity(
                    opacity: holeOpacity,
                    child: const _BlackHole(),
                  ),
                ),

                Align(
                  alignment: const Alignment(0, -0.03),
                  child: Opacity(
                    opacity: welcomeOpacity,
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        welcomeRise + floatingOffset,
                      ),
                      child: const Text(
                        'Welcome',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),

                Center(
                  child: Opacity(
                    opacity: logoOpacity,
                    child: Hero(
                      tag: 'dinas_identity',
                      createRectTween: (begin, end) {
                        return MaterialRectArcTween(
                          begin: begin,
                          end: end,
                        );
                      },
                      child: const _DinasIdentity(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  final double progress;

  const _SplashBackgroundPainter({
    required this.progress,
  });

  static const Color _cream = Color(0xFFE9E5D6);
  static const Color _green = Color(0xFF464E2E);
  static const Color _white = Color(0xFFFAFAFA);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..isAntiAlias = true;

    if (progress < 0.72) {
      _paintOpeningBackground(canvas, size, paint);
      return;
    }

    _paintClosingBackground(canvas, size, paint);
  }

  void _paintOpeningBackground(Canvas canvas, Size size, Paint paint) {
  final double width = size.width;
  final double height = size.height;

  paint.color = _cream;
  canvas.drawRect(
    Offset.zero & size,
    paint,
  );

  final Path greenPath = Path();

  if (progress < 0.18) {
    greenPath
      ..moveTo(width * 0.50, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height)
      ..lineTo(width * 0.50, height)
      ..close();

    paint.color = _green;
    canvas.drawPath(greenPath, paint);
    return;
  }

  if (progress < 0.38) {
    final double phase = Curves.easeInOutCubic.transform(
      _normalizeInterval(progress, 0.18, 0.38),
    );

    final double topX = _lerp(width * 0.50, width, phase);
    final double bottomX = _lerp(width * 0.50, 0, phase);

    greenPath
      ..moveTo(topX, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height)
      ..lineTo(bottomX, height)
      ..close();

    paint.color = _green;
    canvas.drawPath(greenPath, paint);
    return;
  }

  if (progress < 0.50) {
    greenPath
      ..moveTo(width, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    paint.color = _green;
    canvas.drawPath(greenPath, paint);

    final double fadePhase = Curves.easeInOut.transform(
      _normalizeInterval(progress, 0.38, 0.50),
    );

    paint.color = _green.withValues(alpha: fadePhase);
    canvas.drawRect(
      Offset.zero & size,
      paint,
    );
    return;
  }

  paint.color = _green;
  canvas.drawRect(
    Offset.zero & size,
    paint,
  );
}

  void _paintClosingBackground(Canvas canvas, Size size, Paint paint) {
    final double width = size.width;
    final double height = size.height;

    paint.color = _white;
    canvas.drawRect(
      Offset.zero & size,
      paint,
    );

    final double phase = Curves.easeInOutCubic.transform(
      _normalizeInterval(progress, 0.72, 0.90),
    );

    final double waveTop = _lerp(-height * 0.10, height * 0.78, phase);
    final double waveDepth = height * 0.115;

    final Path bottomGreenPath = Path()
      ..moveTo(0, waveTop)
      ..cubicTo(
        width * 0.18,
        waveTop + 4,
        width * 0.28,
        waveTop + waveDepth,
        width * 0.43,
        waveTop + waveDepth,
      )
      ..cubicTo(
        width * 0.56,
        waveTop + waveDepth,
        width * 0.68,
        waveTop + 8,
        width,
        waveTop,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    paint.color = _green;
    canvas.drawPath(bottomGreenPath, paint);
  }

  @override
  bool shouldRepaint(covariant _SplashBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BlackHole extends StatelessWidget {
  const _BlackHole();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 230,
      height: 22,
      child: CustomPaint(
        painter: _BlackHolePainter(),
      ),
    );
  }
}

class _BlackHolePainter extends CustomPainter {
  const _BlackHolePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    final List<_OvalLayer> layers = [
      _OvalLayer(width: 1.00, height: 1.00, opacity: 0.06),
      _OvalLayer(width: 0.94, height: 0.86, opacity: 0.10),
      _OvalLayer(width: 0.86, height: 0.72, opacity: 0.18),
      _OvalLayer(width: 0.76, height: 0.56, opacity: 0.34),
      _OvalLayer(width: 0.66, height: 0.42, opacity: 0.58),
      _OvalLayer(width: 0.56, height: 0.30, opacity: 0.88),
    ];

    for (final _OvalLayer layer in layers) {
      final Rect rect = Rect.fromCenter(
        center: center,
        width: size.width * layer.width,
        height: size.height * layer.height,
      );

      final Paint paint = Paint()
        ..isAntiAlias = true
        ..color = Color.fromRGBO(17, 23, 10, layer.opacity);

      canvas.drawOval(rect, paint);
    }

    final Rect coreRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.50,
      height: size.height * 0.24,
    );

    final Paint corePaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF11170A);

    canvas.drawOval(coreRect, corePaint);
  }

  @override
  bool shouldRepaint(covariant _BlackHolePainter oldDelegate) {
    return false;
  }
}

class _OvalLayer {
  final double width;
  final double height;
  final double opacity;

  const _OvalLayer({
    required this.width,
    required this.height,
    required this.opacity,
  });
}

class _DinasIdentity extends StatelessWidget {
  const _DinasIdentity();

  static const String _logoPath = 'assets/images/logo/LOGO_KALSEL.png';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _logoPath,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),
            const Text(
              'Dinas Perkebunan dan Peternakan\nProvinsi Kalimantan Selatan',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: Color(0xFF1F2417),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _normalizeInterval(double value, double start, double end) {
  if (value <= start) return 0;
  if (value >= end) return 1;

  return (value - start) / (end - start);
}

double _lerp(double start, double end, double progress) {
  return start + ((end - start) * progress);
}

