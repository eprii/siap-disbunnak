import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const String _backgroundAsset =
      'assets/images/background/background_image.png';
  static const String _siapLogoAsset =
      'assets/images/logo/LOGO_SIAP.png';
  static const String _kalselLogoAsset =
      'assets/images/logo/LOGO_KALSEL.png';

  static const Color _darkGreen = Color(0xFF213B2A);
  static const Color _gold = Color(0xFFB37B1D);
  static const Color _darkGold = Color(0xFF8B641B);
  static const Color _lightGold = Color(0xFFE7AA2B);
  static const Color _cardColor = Color(0xFFFFFEFC);
  static const Color _fieldColor = Color(0xFFFFFEFC);
  static const Color _textColor = Color(0xFF22241F);
  static const Color _hintColor = Color(0xFFA8A8A3);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AnimationController _entranceController;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerOffset;
  late final Animation<double> _welcomeOpacity;
  late final Animation<Offset> _welcomeOffset;
  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardOffset;
  late final Animation<double> _buttonReveal;
  late final Animation<double> _registerOpacity;

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );

    _headerOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0,
        0.28,
        curve: Curves.easeOut,
      ),
    );

    _headerOffset = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(
          0,
          0.35,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _welcomeOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.22,
        0.48,
        curve: Curves.easeOut,
      ),
    );

    _welcomeOffset = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(
          0.22,
          0.52,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _cardOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.28,
        0.62,
        curve: Curves.easeOut,
      ),
    );

    _cardOffset = Tween<Offset>(
      begin: const Offset(0, 0.34),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(
          0.28,
          0.72,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _buttonReveal = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.66,
        0.92,
        curve: Curves.easeOutCubic,
      ),
    );

    _registerOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.80,
        1,
        curve: Curves.easeOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.instance.login(
        identifier: _identifierController.text,
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Login gagal. Silakan coba kembali.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openRegisterPage() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool keyboardVisible = mediaQuery.viewInsets.bottom > 0;

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
        resizeToAvoidBottomInset: true,
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
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool compactHeight = constraints.maxHeight < 720;
                  final double horizontalPadding =
                      constraints.maxWidth < 380 ? 22 : 28;

                  final double topPadding = compactHeight ? 18 : 32;
                  final double bottomPadding = keyboardVisible ? 32 : 44;
                  final double minimumContentHeight =
                      (constraints.maxHeight - topPadding - bottomPadding)
                          .clamp(0.0, double.infinity)
                          .toDouble();

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      topPadding,
                      horizontalPadding,
                      bottomPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 390,
                          minHeight: minimumContentHeight,
                        ),
                        child: IntrinsicHeight(
                          child: AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  FadeTransition(
                                    opacity: _headerOpacity,
                                    child: SlideTransition(
                                      position: _headerOffset,
                                      child: _LoginBrandHeader(
                                        compact: compactHeight,
                                        kalselLogoAsset: _kalselLogoAsset,
                                        siapLogoAsset: _siapLogoAsset,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 12 : 18),
                                  FadeTransition(
                                    opacity: _welcomeOpacity,
                                    child: SlideTransition(
                                      position: _welcomeOffset,
                                      child: const Text(
                                        'Selamat Datang',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _darkGreen,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 14 : 22),
                                  FadeTransition(
                                    opacity: _cardOpacity,
                                    child: SlideTransition(
                                      position: _cardOffset,
                                      child: _buildLoginCard(
                                        compactHeight: compactHeight,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 28 : 42),
                                  const Spacer(),
                                  const Text(
                                    'Versi 1.0.0',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF38352E),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard({required bool compactHeight}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 13,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compactHeight ? 20 : 24,
          compactHeight ? 20 : 24,
          compactHeight ? 20 : 24,
          compactHeight ? 20 : 24,
        ),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Username atau email',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _identifierController,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  autofillHints: const <String>[
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _inputDecoration(
                    hintText: 'Username atau email',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email atau username wajib diisi';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Masukkan kata sandi',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[
                    AutofillHints.password,
                  ],
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  onFieldSubmitted: (_) {
                    if (!_isLoading) {
                      _submitLogin();
                    }
                  },
                  decoration: _inputDecoration(
                    hintText: 'Kata sandi',
                    prefixIcon: Icons.lock_outline_rounded,
                    suffix: IconButton(
                      tooltip: _obscurePassword
                          ? 'Tampilkan kata sandi'
                          : 'Sembunyikan kata sandi',
                      visualDensity: VisualDensity.compact,
                      splashRadius: 18,
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: const Color(0xFF555650),
                        size: 20,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kata sandi wajib diisi';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 7),
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                        activeColor: _gold,
                        checkColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFF444640),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Remember me',
                      style: TextStyle(
                        color: Color(0xFF4E504B),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _buttonReveal.value,
                    child: Opacity(
                      opacity: _buttonReveal.value,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - _buttonReveal.value)),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: _GradientLoginButton(
                            isLoading: _isLoading,
                            onPressed: _submitLogin,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compactHeight ? 16 : 20),
                FadeTransition(
                  opacity: _registerOpacity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(
                          color: Color(0xFF5D5D59),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      InkWell(
                        onTap: _isLoading ? null : _openRegisterPage,
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 3,
                          ),
                          child: Text(
                            'Register',
                            style: TextStyle(
                              color: Color(0xFF3397E8),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(
          color: color,
          width: width,
        ),
      );
    }

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: _hintColor,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        prefixIcon,
        size: 18,
        color: _gold,
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 38,
        minHeight: 38,
      ),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 38,
      ),
      filled: true,
      fillColor: _fieldColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      enabledBorder: border(_gold),
      disabledBorder: border(_gold.withValues(alpha: 0.55)),
      focusedBorder: border(_darkGold, width: 1.5),
      errorBorder: border(Colors.red.shade600),
      focusedErrorBorder: border(Colors.red.shade700, width: 1.5),
      errorStyle: const TextStyle(
        fontSize: 10,
        height: 1.15,
      ),
    );
  }
}

class _LoginBrandHeader extends StatelessWidget {
  final bool compact;
  final String kalselLogoAsset;
  final String siapLogoAsset;

  const _LoginBrandHeader({
    required this.compact,
    required this.kalselLogoAsset,
    required this.siapLogoAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          kalselLogoAsset,
          width: compact ? 42 : 47,
          height: compact ? 50 : 57,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        SizedBox(height: compact ? 7 : 9),
        Image.asset(
          siapLogoAsset,
          width: compact ? 135 : 150,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        SizedBox(height: compact ? 6 : 8),
        const Text(
          'Sistem Informasi Administrasi Pegawai',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: TextStyle(
            color: _LoginPageState._darkGreen,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

class _GradientLoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GradientLoginButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? <Color>[
                    _LoginPageState._darkGold.withValues(alpha: 0.58),
                    _LoginPageState._lightGold.withValues(alpha: 0.58),
                  ]
                : const <Color>[
                    _LoginPageState._darkGold,
                    _LoginPageState._lightGold,
                  ],
          ),
          borderRadius: BorderRadius.circular(9),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.1,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
