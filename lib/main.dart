import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'config/firebase_options.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          Brightness.dark,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    accessToken: () async {
      final firebaseUser =
          firebase_auth.FirebaseAuth.instance.currentUser;

      return firebaseUser?.getIdToken(false);
    },
  );

  runApp(const SiapApp());
}

class SiapApp extends StatelessWidget {
  const SiapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIAP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateInitialRoutes: (initialRoute) {
        return <Route<dynamic>>[
          AppRoutes.onGenerateRoute(
            RouteSettings(name: initialRoute),
          ),
        ];
      },
      onGenerateRoute: AppRoutes.onGenerateRoute,

      builder: (context, child) {
        final appChild = child ?? const SizedBox.shrink();

        if (!kIsWeb) {
          return MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.0,
            child: appChild,
          );
        }

        final mediaQuery = MediaQuery.of(context);
        final viewportSize = mediaQuery.size;

        const mobileDesignSize = Size(430, 932);
        const double mobileViewportBreakpoint = 600;

        // Browser ponsel memakai lebar viewport penuh. Breakpoint dibuat
        // lebih longgar dari ukuran desain agar perangkat dengan viewport
        // 431-600 logical pixel tidak masuk ke mode mockup desktop.
        if (viewportSize.width <= mobileViewportBreakpoint) {
          return MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.0,
            child: appChild,
          );
        }

        // Desktop: skala seluruh tampilan, termasuk font dan widget,
        // bukan hanya memperkecil constraint layout.
        final scale = math.min(
          1.0,
          math.min(
            viewportSize.width / mobileDesignSize.width,
            viewportSize.height / mobileDesignSize.height,
          ),
        );

        final scaledWidth = mobileDesignSize.width * scale;
        final scaledHeight = mobileDesignSize.height * scale;

        return ColoredBox(
          color: Colors.white,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: scaledWidth,
              height: scaledHeight,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: mobileDesignSize.width,
                  height: mobileDesignSize.height,
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      size: mobileDesignSize,
                    ),
                    child: MediaQuery.withClampedTextScaling(
                      minScaleFactor: 0.85,
                      maxScaleFactor: 1.0,
                      child: appChild,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
