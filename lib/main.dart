import 'package:firebase_core/firebase_core.dart';
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
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.0,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
