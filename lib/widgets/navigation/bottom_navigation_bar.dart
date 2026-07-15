import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';

import '../../pages/home/home_page.dart';
import '../../pages/profile/profile_page.dart';
import '../../pages/saved_sk/admin/saved_sk_page.dart';
import '../../pages/upload_sk/upload_sk_page.dart';

const String _iconamoonProfileFill = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
  <path fill="currentColor" fill-rule="evenodd" d="M12 2.25a4.75 4.75 0 1 0 0 9.5a4.75 4.75 0 0 0 0-9.5M8.75 7a3.25 3.25 0 1 1 6.5 0a3.25 3.25 0 0 1-6.5 0M12 13.25c-4.418 0-8 2.015-8 4.5v1A2.25 2.25 0 0 0 6.25 21h11.5A2.25 2.25 0 0 0 20 18.75v-1c0-2.485-3.582-4.5-8-4.5" clip-rule="evenodd"/>
</svg>
''';

class SikapBottomNavigationBar extends StatefulWidget {
  final bool isAdmin;

  const SikapBottomNavigationBar({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<SikapBottomNavigationBar> createState() =>
      _SikapBottomNavigationBarState();
}

class _SikapBottomNavigationBarState extends State<SikapBottomNavigationBar> {
  int _selectedIndex = 0;

  List<Widget> get _pages {
    if (widget.isAdmin) {
      return const <Widget>[
        HomePage(),
        SavedSKPage(),
        ProfilePage(),
      ];
    }

  return <Widget>[
    const HomePage(),
      UploadSKPage(
        onBack: () => _onItemSelected(0),
      ),
      const ProfilePage(),
    ];
  }

  List<_SikapNavItem> get _navItems {
    if (widget.isAdmin) {
      return const <_SikapNavItem>[
        _SikapNavItem(
          icon: MaterialSymbols.home_rounded,
          label: 'Home',
        ),
        _SikapNavItem(
          icon: MaterialSymbols.bookmark_rounded,
          label: 'SK Tersimpan',
        ),
        _SikapNavItem(
          icon: _iconamoonProfileFill,
          label: 'Profil',
        ),
      ];
    }

    return const <_SikapNavItem>[
      _SikapNavItem(
        icon: MaterialSymbols.home_rounded,
        label: 'Home',
      ),
      _SikapNavItem(
        icon: MaterialSymbols.add_rounded,
        label: 'Upload SK',
      ),
      _SikapNavItem(
        icon: _iconamoonProfileFill,
        label: 'Profil',
      ),
    ];
  }

  void _onItemSelected(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: _SikapBottomNavBar(
        selectedIndex: _selectedIndex,
        items: _navItems,
        onItemSelected: _onItemSelected,
      ),
    );
  }
}

class _SikapBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_SikapNavItem> items;
  final ValueChanged<int> onItemSelected;

  const _SikapBottomNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onItemSelected,
  });

  static const double _baseHeight = 72;
  static const double _baseCircleSize = 54;
  static const double _baseIconSize = 35;

  static const Duration _animationDuration = Duration(milliseconds: 500);

  static const Color _backgroundColor = Color(0xFFF5EEDC);
  static const Color _selectedCircleColor = Color(0xFFB4C19A);
  static const Color _borderColor = Color(0xFF1F2417);

  static const double _referenceDevicePixelRatio = 2.75;

  double _lockedSize(BuildContext context, double value) {
    final double currentDevicePixelRatio =
        MediaQuery.devicePixelRatioOf(context);

    final double scale =
        (_referenceDevicePixelRatio / currentDevicePixelRatio)
            .clamp(0.85, 1.15);

    return value * scale;
  }

  @override
  Widget build(BuildContext context) {

    debugPrint(
      'DPR: ${MediaQuery.devicePixelRatioOf(context)}',
    );
    
    final double height = _lockedSize(context, _baseHeight);
    final double circleSize = _lockedSize(context, _baseCircleSize);
    final double iconSize = _lockedSize(context, _baseIconSize);

    return Container(
      decoration: const BoxDecoration(
        color: _backgroundColor,
        border: Border(
          top: BorderSide(
            color: _borderColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth = constraints.maxWidth / items.length;
              final double circleLeft =
                  (itemWidth * selectedIndex) +
                  ((itemWidth - circleSize) / 2);

              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: _animationDuration,
                    curve: Curves.easeOutCubic,
                    left: circleLeft,
                    top: (height - circleSize) / 2,
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedCircleColor,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(items.length, (index) {
                      final _SikapNavItem item = items[index];

                      return Expanded(
                        child: _SikapBottomNavItem(
                          icon: item.icon,
                          label: item.label,
                          active: selectedIndex == index,
                          iconSize: iconSize,
                          onTap: () => onItemSelected(index),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  
}

class _SikapBottomNavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final double iconSize;
  final VoidCallback onTap;

  const _SikapBottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.iconSize,
    required this.onTap,
  });

  static const Color _iconColor = Color(0xFF4A5333);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: active,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Center(
          child: Iconify(
            icon,
            size: iconSize,
            color: _iconColor,
          ),
        ),
      ),
    );
  }
}

class _SikapNavItem {
  final String icon;
  final String label;

  const _SikapNavItem({
    required this.icon,
    required this.label,
  });
}