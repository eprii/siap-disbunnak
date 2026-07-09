import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'config/firebase_options.dart';
import 'pages/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SikapApp());
}

class SikapApp extends StatelessWidget {
  const SikapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIKAP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(
      ),
    );
  }
}
