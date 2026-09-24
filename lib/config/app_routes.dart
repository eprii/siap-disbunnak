import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/users_model.dart';
import '../pages/login/login_page.dart';
import '../pages/register/register_page.dart';
import '../pages/splash/splash_screen.dart';
import '../services/auth_service.dart';
import '../widgets/navigation/bottom_navigation_bar.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = SplashScreen.routeName;
  static const String root = '/';
  static const String login = '/login';
  static const String register = '/register';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(
          const SplashScreen(),
          settings,
          duration: Duration.zero,
          reverseDuration: Duration.zero,
        );

      case root:
        return _fadeRoute(
          const AuthGate(),
          settings,
        );

      case login:
        return _fadeRoute(
          const LoginPage(),
          settings,
        );

      case register:
        return _slideRoute(
          const RegisterPage(),
          settings,
        );

      default:
        return _fadeRoute(
          const AuthGate(),
          settings,
        );
    }
  }

  static PageRouteBuilder<dynamic> _fadeRoute(
    Widget page,
    RouteSettings settings, {
    Duration duration = const Duration(milliseconds: 250),
    Duration reverseDuration = const Duration(milliseconds: 200),
  }) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (_, _, _) => page,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      transitionsBuilder: (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<dynamic> _slideRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        final Animation<Offset> position = Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: position,
            child: child,
          ),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingPage();
        }

        final User? firebaseUser = authSnapshot.data;

        if (firebaseUser == null) {
          SiapNavigationController.clearSession();
          return const LoginPage();
        }

        return StreamBuilder<UsersModel?>(
          stream: AuthService.instance.watchUser(
            firebaseUser.uid,
          ),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoadingPage();
            }

            if (userSnapshot.hasError) {
              return const _AccountProblemPage(
                message: 'Gagal membaca data akun dari database.',
              );
            }

            final UsersModel? user = userSnapshot.data;

            if (user == null) {
              return const _AccountProblemPage(
                message: 'Data akun tidak ditemukan di Firestore.',
              );
            }

            final String status = user.status_akun.trim().toLowerCase();

            if (status != 'aktif') {
              return const _AccountProblemPage(
                message:
                    'Akun Anda sedang dinonaktifkan. Hubungi administrator.',
              );
            }

            final String role = user.role.trim().toLowerCase();

            if (role == 'admin') {
              return SiapBottomNavigationBar(
                isAdmin: true,
                sessionUid: firebaseUser.uid,
              );
            }

            if (role == 'user') {
              return SiapBottomNavigationBar(
                isAdmin: false,
                sessionUid: firebaseUser.uid,
              );
            }

            return const _AccountProblemPage(
              message: 'Role akun tidak valid. Hubungi administrator.',
            );
          },
        );
      },
    );
  }
}

class _AuthLoadingPage extends StatelessWidget {
  const _AuthLoadingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DB),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/background_image.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF9D6A18),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountProblemPage extends StatelessWidget {
  final String message;

  const _AccountProblemPage({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EDDE),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.lock_person_outlined,
                  size: 70,
                  color: Color(0xFF43532B),
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () {
                    AuthService.instance.logout();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF412D00),
                  ),
                  child: const Text('Kembali ke Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
