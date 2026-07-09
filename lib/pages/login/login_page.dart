import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const String routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  static const String _logoPath = 'assets/images/logo/LOGO_KALSEL.png';



  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fungsi login belum diimplementasikan.'),
      ),
    );
  }

  double _interval(double value, double start, double end) {
    if (value <= start) return 0;
    if (value >= end) return 1;

    return (value - start) / (end - start);
  }


  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final double value = _controller.value;

            Curves.easeOut.transform(
              _interval(value, 0.25, 0.75),
            );

            final double formOpacity = Curves.easeOut.transform(
              _interval(value, 0.45, 1.00),
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                final double screenWidth = constraints.maxWidth;
                final double screenHeight = constraints.maxHeight;

                final double panelWidth = math.min(screenWidth - 48, 330);
                final double panelTop = screenHeight * 0.10;
                final double panelHeight = math.min(screenHeight * 0.76, 620);

                final double logoEndTop = panelTop + 55;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    const CustomPaint(
                      painter: _LoginBackgroundPainter(),
                    ),

                    Positioned(
                      top: logoEndTop,
                      left: 24,
                      right: 24,
                      child: Hero(
                        tag: 'dinas_identity',
                        child: _LoginIdentity(
                          logoPath: _logoPath,
                          logoSize: 120,
                        ),
                      ),
                    ),

                    Positioned(
                      top: logoEndTop,
                      left: 24,
                      right: 24,
                      child: Hero(
                        tag: 'dinas_identity',
                        createRectTween: (begin, end) {
                          return MaterialRectArcTween(
                            begin: begin,
                            end: end,
                          );
                        },
                        child: const _LoginIdentity(
                          logoPath: 'assets/images/logo/LOGO_KALSEL.png',
                          logoSize: 120,
                        ),
                      ),
                    ),

                    Positioned(
                      top: panelTop + 275,
                      left: (screenWidth - panelWidth) / 2,
                      child: Opacity(
                        opacity: formOpacity,
                        child: SizedBox(
                          width: panelWidth,
                          height: panelHeight - 285,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 4,
                            ),
                            child: _LoginForm(
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              obscurePassword: _obscurePassword,
                              rememberMe: _rememberMe,
                              onTogglePasswordVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              onRememberChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              onLoginPressed: _onLoginPressed,
                            ),
                          ),
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
    );
  }
}

class _LoginIdentity extends StatelessWidget {
  final String logoPath;
  final double logoSize;

  const _LoginIdentity({
    required this.logoPath,
    required this.logoSize,
  });

  static const Color _textColor = Color(0xFF141414);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Image.asset(
            logoPath,
            width: logoSize,
            height: logoSize,
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
              color: _textColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final VoidCallback onTogglePasswordVisibility;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onLoginPressed;

  const _LoginForm({
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.onTogglePasswordVisibility,
    required this.onRememberChanged,
    required this.onLoginPressed,
  });

  static const Color _darkBrown = Color(0xFF3B2800);
  static const Color _textColor = Color(0xFF141414);

  @override
  Widget build(BuildContext context) {
    final InputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: const BorderSide(
        color: _textColor,
        width: 1,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Username',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: TextField(
            controller: usernameController,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              fontSize: 14,
              color: _textColor,
            ),
            decoration: InputDecoration(
              hintText: 'Username',
              hintStyle: TextStyle(
                fontSize: 14,
                color: _textColor.withOpacity(0.35),
              ),
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: _textColor,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border,
              filled: false,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Masukan kata sandi',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              fontSize: 14,
              color: _textColor,
            ),
            decoration: InputDecoration(
              hintText: 'kata sandi',
              hintStyle: TextStyle(
                fontSize: 14,
                color: _textColor.withOpacity(0.35),
              ),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: _textColor,
              ),
              suffixIcon: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 38,
                  minHeight: 38,
                ),
                onPressed: onTogglePasswordVisibility,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 21,
                  color: Colors.black,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border,
              filled: false,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Checkbox(
                value: rememberMe,
                activeColor: _darkBrown,
                side: const BorderSide(
                  color: _textColor,
                  width: 1,
                ),
                onChanged: onRememberChanged,
              ),
            ),
            const SizedBox(width: 2),
            const Flexible(
              child: Text(
                'remember me',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton(
            onPressed: onLoginPressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _darkBrown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'login',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'belum punya akun? ',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 11,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'register',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  const _LoginBackgroundPainter();

  static const Color _green = Color(0xFF464E2E);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..isAntiAlias = true
      ..color = _green;

    final double width = size.width;
    final double height = size.height;

    final double waveTop = height * 0.82;
    final double waveDepth = height * 0.11;

    final Path path = Path()
      ..moveTo(0, waveTop)
      ..cubicTo(
        width * 0.18,
        waveTop + 3,
        width * 0.28,
        waveTop + waveDepth,
        width * 0.43,
        waveTop + waveDepth,
      )
      ..cubicTo(
        width * 0.56,
        waveTop + waveDepth,
        width * 0.68,
        waveTop + 6,
        width,
        waveTop,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LoginBackgroundPainter oldDelegate) {
    return false;
  }
}