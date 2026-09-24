import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const LinearGradient glassSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xB8FFFDF7),
      Color(0xA3FFF1D3),
    ],
  );

  static const LinearGradient glassHintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0x70F6DFA6),
      Color(0x52E8C56F),
    ],
  );

  static const LinearGradient bottomNavigationFadeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Colors.transparent,
      Color(0x24B9A36E),
      Color(0x58D4C294),
      Color(0x8FE6D6AE),
      Color(0xC4FFF4D8),
    ],
    stops: <double>[
      0.0,
      0.24,
      0.50,
      0.76,
      1.0,
    ],
  );

  static const Color glassBorderColor = Color(0x8AFFFFFF);

  static const List<BoxShadow> glassSurfaceShadows = <BoxShadow>[
    BoxShadow(
      color: Color(0x2A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> glassHintShadows = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F6F531A),
      blurRadius: 7,
      offset: Offset(0, 3),
    ),
  ];

  static BoxDecoration glassSurfaceDecoration({
    double radius = 14,
    bool includeShadow = true,
  }) {
    return BoxDecoration(
      gradient: glassSurfaceGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glassBorderColor,
        width: 1,
      ),
      boxShadow: includeShadow ? glassSurfaceShadows : null,
    );
  }

  static BoxDecoration glassHintDecoration({
    double radius = 13,
  }) {
    return BoxDecoration(
      gradient: glassHintGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glassBorderColor,
        width: 1,
      ),
      boxShadow: glassHintShadows,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
    );
  }
}
