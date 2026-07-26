import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _backgroundAsset =
      'assets/images/background/background_image.png';
  static const String _siapLogoAsset =
      'assets/images/logo/LOGO_SIAP.png';
  static const String _kalselLogoAsset =
      'assets/images/logo/LOGO_KALSEL.png';

  static const double _siapLogoAspectRatio = 596 / 264;
  static const double _brandInitialAlignmentY = -0.08;
  static const double _brandFinalAlignmentY = -0.50;
  static const double _logoSubtitleSpacing = 12;
  static const double _kalselLogoSpacing = 14;

  // Timeline splash:
  // 0 ms    - 650 ms  : logo SIAP masuk
  // 650 ms  - 3000 ms : logo SIAP tetap tampil sendiri
  // 3000 ms - 3550 ms : subjudul muncul
  // 3750 ms - 4650 ms : grup logo bergerak ke atas
  // 4200 ms - 4850 ms : logo Kalsel muncul
  // 4850 ms - 5550 ms : tampilan akhir ditahan sebelum navigasi
  static const Duration _animationDuration = Duration(milliseconds: 5550);

  static const int _logoEntranceStartMs = 0;
  static const int _logoEntranceEndMs = 650;
  static const int _subtitleEntranceStartMs = 3000;
  static const int _subtitleEntranceEndMs = 3550;
  static const int _brandMoveStartMs = 3750;
  static const int _brandMoveEndMs = 4650;
  static const int _kalselEntranceStartMs = 4200;
  static const int _kalselEntranceEndMs = 4850;

  late final AnimationController _controller;
  late final Animation<double> _siapOpacity;
  late final Animation<double> _siapScale;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleOffset;
  late final Animation<double> _brandMove;
  late final Animation<double> _kalselOpacity;
  late final Animation<double> _kalselScale;

  static double _timelinePoint(int milliseconds) {
    return milliseconds / _animationDuration.inMilliseconds;
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _siapOpacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        _timelinePoint(_logoEntranceStartMs),
        _timelinePoint(_logoEntranceEndMs),
        curve: Curves.easeOut,
      ),
    );

    _siapScale = Tween<double>(
      begin: 0.86,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _timelinePoint(_logoEntranceStartMs),
          _timelinePoint(_logoEntranceEndMs),
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _subtitleOpacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        _timelinePoint(_subtitleEntranceStartMs),
        _timelinePoint(_subtitleEntranceEndMs),
        curve: Curves.easeOut,
      ),
    );

    _subtitleOffset = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _timelinePoint(_subtitleEntranceStartMs),
          _timelinePoint(_subtitleEntranceEndMs),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _brandMove = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        _timelinePoint(_brandMoveStartMs),
        _timelinePoint(_brandMoveEndMs),
        curve: Curves.easeInOutCubic,
      ),
    );

    _kalselOpacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        _timelinePoint(_kalselEntranceStartMs),
        _timelinePoint(_kalselEntranceEndMs),
        curve: Curves.easeOut,
      ),
    );

    _kalselScale = Tween<double>(
      begin: 0.72,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _timelinePoint(_kalselEntranceStartMs),
          _timelinePoint(_kalselEntranceEndMs),
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _controller.addStatusListener(_handleAnimationStatus);
    _controller.forward();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8DB),
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: Image.asset(
                _backgroundAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double contentWidth =
                      constraints.maxWidth.clamp(0, 430).toDouble();
                  final double logoWidth =
                      (contentWidth * 0.39).clamp(132, 168).toDouble();
                  final double logoHeight =
                      logoWidth / _siapLogoAspectRatio;
                  final double brandHeight =
                      (contentWidth * 0.62).clamp(206, 224).toDouble();

                  const double kalselLogoWidth = 47;
                  const double kalselLogoHeight = 57;

                  final double siapLogoTop =
                      (brandHeight - logoHeight) / 2;
                  final double kalselLogoTop =
                      (siapLogoTop -
                              kalselLogoHeight -
                              _kalselLogoSpacing)
                          .clamp(0, brandHeight)
                          .toDouble();
                  final double subtitleTop = siapLogoTop +
                      logoHeight +
                      _logoSubtitleSpacing;

                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final double alignmentY = ui.lerpDouble(
                            _brandInitialAlignmentY,
                            _brandFinalAlignmentY,
                            _brandMove.value,
                          ) ??
                          _brandFinalAlignmentY;

                      return Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          Align(
                            alignment: Alignment(0, alignmentY),
                            child: SizedBox(
                              width: contentWidth,
                              height: brandHeight,
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: <Widget>[
                                  Positioned(
                                    top: kalselLogoTop,
                                    child: FadeTransition(
                                      opacity: _kalselOpacity,
                                      child: ScaleTransition(
                                        scale: _kalselScale,
                                        child: Image.asset(
                                          _kalselLogoAsset,
                                          width: kalselLogoWidth,
                                          height: kalselLogoHeight,
                                          fit: BoxFit.contain,
                                          filterQuality:
                                              FilterQuality.high,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: siapLogoTop,
                                    child: FadeTransition(
                                      opacity: _siapOpacity,
                                      child: ScaleTransition(
                                        scale: _siapScale,
                                        child: SizedBox(
                                          width: logoWidth,
                                          height: logoHeight,
                                          child: Image.asset(
                                            _siapLogoAsset,
                                            fit: BoxFit.contain,
                                            filterQuality:
                                                FilterQuality.high,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: subtitleTop,
                                    left: 20,
                                    right: 20,
                                    child: FadeTransition(
                                      opacity: _subtitleOpacity,
                                      child: SlideTransition(
                                        position: _subtitleOffset,
                                        child: const Text(
                                          'Sistem Informasi Administrasi Pegawai',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                          softWrap: false,
                                          style: TextStyle(
                                            color: Color(0xFF20291C),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 24,
                            right: 24,
                            bottom: 18,
                            child: Text(
                              'Versi 1.0.0',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF38352E),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
