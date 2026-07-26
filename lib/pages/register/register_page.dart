import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late final AnimationController _entranceController;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerOffset;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleOffset;
  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardOffset;
  late final Animation<double> _buttonReveal;
  late final Animation<double> _loginOpacity;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _headerOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0,
        0.26,
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
          0.34,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _titleOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.20,
        0.46,
        curve: Curves.easeOut,
      ),
    );

    _titleOffset = Tween<Offset>(
      begin: const Offset(0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(
          0.20,
          0.50,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _cardOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.28,
        0.64,
        curve: Curves.easeOut,
      ),
    );

    _cardOffset = Tween<Offset>(
      begin: const Offset(0, 0.28),
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

    _loginOpacity = CurvedAnimation(
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_agreeTerms) {
      _showMessage('Anda harus menyetujui Persyaratan & Ketentuan.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.instance.register(
        namaLengkap: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Registrasi Berhasil',
              style: TextStyle(
                color: _textColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Text(
              'Akun berhasil dibuat. Silakan login menggunakan email '
              'atau username Anda.',
              style: TextStyle(
                color: Color(0xFF5D5D59),
                fontSize: 13,
              ),
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _darkGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text('Ke Login'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Registrasi gagal. Silakan coba kembali.');
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

  void _returnToLogin() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
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
                  final bool compactHeight = constraints.maxHeight < 790;
                  final double horizontalPadding =
                      constraints.maxWidth < 380 ? 22 : 28;

                  final double topPadding = compactHeight ? 16 : 28;
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
                                      child: _RegisterBrandHeader(
                                        compact: compactHeight,
                                        kalselLogoAsset: _kalselLogoAsset,
                                        siapLogoAsset: _siapLogoAsset,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 10 : 16),
                                  FadeTransition(
                                    opacity: _titleOpacity,
                                    child: SlideTransition(
                                      position: _titleOffset,
                                      child: const Column(
                                        children: <Widget>[
                                          Text(
                                            'Buat Akun',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _darkGreen,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Lengkapi data diri Anda untuk '
                                            'membuat akun baru.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Color(0xFF5D5D59),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              height: 1.25,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 12 : 18),
                                  FadeTransition(
                                    opacity: _cardOpacity,
                                    child: SlideTransition(
                                      position: _cardOffset,
                                      child: _buildRegisterCard(
                                        compactHeight: compactHeight,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 24 : 36),
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

  Widget _buildRegisterCard({required bool compactHeight}) {
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
        padding: EdgeInsets.all(compactHeight ? 20 : 24),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildField(
                  label: 'Nama lengkap',
                  controller: _nameController,
                  hintText: 'Nama lengkap',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.name],
                  validator: (value) {
                    final String text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Nama lengkap wajib diisi';
                    }

                    if (text.length < 3) {
                      return 'Nama lengkap terlalu pendek';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 13),
                _buildField(
                  label: 'Email',
                  controller: _emailController,
                  hintText: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                  validator: (value) {
                    final String text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Email wajib diisi';
                    }

                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(text)) {
                      return 'Format email tidak valid';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 13),
                _buildPasswordField(
                  label: 'Kata sandi',
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  onToggle: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  validator: (value) {
                    final String text = value ?? '';

                    if (text.isEmpty) {
                      return 'Kata sandi wajib diisi';
                    }

                    if (text.length < 8) {
                      return 'Kata sandi minimal 8 karakter';
                    }

                    if (!RegExp(r'[A-Za-z]').hasMatch(text) ||
                        !RegExp(r'\d').hasMatch(text)) {
                      return 'Gunakan kombinasi huruf dan angka';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 13),
                _buildPasswordField(
                  label: 'Konfirmasi kata sandi',
                  controller: _confirmPasswordController,
                  obscure: _obscureConfirmPassword,
                  onToggle: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  onFieldSubmitted: (_) {
                    if (!_isLoading) {
                      _submitRegister();
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi kata sandi wajib diisi';
                    }

                    if (value != _passwordController.text) {
                      return 'Konfirmasi kata sandi tidak sama';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: Checkbox(
                        value: _agreeTerms,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _agreeTerms = value ?? false;
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
                    const Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            TextSpan(
                              text: 'Saya menyetujui ',
                              style: TextStyle(
                                color: Color(0xFF4E504B),
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextSpan(
                              text: 'Persyaratan & Ketentuan',
                              style: TextStyle(
                                color: Color(0xFF3397E8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
                          child: _GradientRegisterButton(
                            isLoading: _isLoading,
                            onPressed: _submitRegister,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compactHeight ? 16 : 20),
                FadeTransition(
                  opacity: _loginOpacity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(
                          color: Color(0xFF5D5D59),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      InkWell(
                        onTap: _isLoading ? null : _returnToLogin,
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 3,
                          ),
                          child: Text(
                            'Login',
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required TextInputAction textInputAction,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: _textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          enabled: !_isLoading,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          scrollPadding: const EdgeInsets.only(bottom: 140),
          style: const TextStyle(
            color: _textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required TextInputAction textInputAction,
    required String? Function(String?) validator,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: _textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          enabled: !_isLoading,
          obscureText: obscure,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          scrollPadding: const EdgeInsets.only(bottom: 140),
          style: const TextStyle(
            color: _textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onFieldSubmitted: onFieldSubmitted,
          decoration: _inputDecoration(
            hintText: label,
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              tooltip: obscure
                  ? 'Tampilkan kata sandi'
                  : 'Sembunyikan kata sandi',
              visualDensity: VisualDensity.compact,
              splashRadius: 18,
              onPressed: _isLoading ? null : onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: const Color(0xFF555650),
                size: 20,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
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

class _RegisterBrandHeader extends StatelessWidget {
  final bool compact;
  final String kalselLogoAsset;
  final String siapLogoAsset;

  const _RegisterBrandHeader({
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
            color: _RegisterPageState._darkGreen,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

class _GradientRegisterButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GradientRegisterButton({
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
                    _RegisterPageState._darkGold.withValues(alpha: 0.58),
                    _RegisterPageState._lightGold.withValues(alpha: 0.58),
                  ]
                : const <Color>[
                    _RegisterPageState._darkGold,
                    _RegisterPageState._lightGold,
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
                      'Register',
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
