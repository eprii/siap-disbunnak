// SIAP_NAV_WHITE_PLAIN_V4
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';

import '../../config/app_theme.dart';
import '../../pages/home/home_page.dart';
import '../../pages/kelola_data/kelola_data_page.dart';
import '../../pages/profile/admin_profile_page.dart';
import '../../pages/profile/profile_page.dart';
import '../../pages/saved_sk/admin/saved_sk_page.dart';
import '../../services/profile_completion_service.dart';

const String _iconamoonProfileFill = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
  <path fill="currentColor" fill-rule="evenodd" d="M12 2.25a4.75 4.75 0 1 0 0 9.5a4.75 4.75 0 0 0 0-9.5M8.75 7a3.25 3.25 0 1 1 6.5 0a3.25 3.25 0 0 1-6.5 0M12 13.25c-4.418 0-8 2.015-8 4.5v1A2.25 2.25 0 0 0 6.25 21h11.5A2.25 2.25 0 0 0 20 18.75v-1c0-2.485-3.582-4.5-8-4.5" clip-rule="evenodd"/>
</svg>
''';

const double _siapBarHeight = 80;
const double _siapBarBottomMargin = 12;
const double _siapBottomGlassExtraHeight = 1;
const String _siapBottomNavigationHeroTag = 'siap-bottom-navigation';

Widget _buildBottomNavigationFlight(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final Hero destinationHero = toHeroContext.widget as Hero;

  return Material(
    type: MaterialType.transparency,
    child: destinationHero.child,
  );
}

class SiapNavigationController {
  SiapNavigationController._();

  static final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);
  static String? _activeSessionUid;

  static int prepareSession(String uid) {
    final String cleanUid = uid.trim();
    if (cleanUid.isNotEmpty && _activeSessionUid != cleanUid) {
      _activeSessionUid = cleanUid;
      selectedIndex.value = 0;
    }
    return selectedIndex.value;
  }

  static void clearSession() {
    _activeSessionUid = null;
  }

  static void selectTab(int index) {
    if (index < 0 || index > 2) return;
    if (selectedIndex.value == index) return;
    selectedIndex.value = index;
  }
}

class SiapBottomNavigationBar extends StatefulWidget {
  final bool isAdmin;
  final String sessionUid;

  const SiapBottomNavigationBar({
    super.key,
    this.isAdmin = false,
    required this.sessionUid,
  });

  @override
  State<SiapBottomNavigationBar> createState() =>
      _SiapBottomNavigationBarState();
}

class _SiapBottomNavigationBarState
    extends State<SiapBottomNavigationBar> {
  static const String _backgroundAsset =
      'assets/images/background/background_image.png';

  late final List<Widget> _pages;
  late final List<_SiapNavItem> _navItems;

  late int _selectedIndex;
  bool _profileCompletionPromptShown = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = SiapNavigationController.prepareSession(
      widget.sessionUid,
    );
    SiapNavigationController.selectedIndex.addListener(
      _syncSelectedIndex,
    );

    if (widget.isAdmin) {
      _pages = const <Widget>[
        HomePage(isAdmin: true),
        SavedSKPage(),
        AdminProfilePage(),
      ];

      _navItems = const <_SiapNavItem>[
        _SiapNavItem(
          icon: MaterialSymbols.home_rounded,
          label: 'Home',
          iconSize: 28,
        ),
        _SiapNavItem(
          icon: MaterialSymbols.bookmark_rounded,
          label: 'Data Tersimpan',
          iconSize: 28,
        ),
        _SiapNavItem(
          icon: _iconamoonProfileFill,
          label: 'Profil',
          iconSize: 29,
        ),
      ];
      return;
    }

    _pages = const <Widget>[
      HomePage(isAdmin: false),
      KelolaDataPage(),
      ProfilePage(),
    ];

    _navItems = const <_SiapNavItem>[
      _SiapNavItem(
        icon: MaterialSymbols.home_rounded,
        label: 'Home',
        iconSize: 28,
      ),
      _SiapNavItem(
        icon: MaterialSymbols.add_rounded,
        label: 'Kelola Data',
        iconSize: 36,
      ),
      _SiapNavItem(
        icon: _iconamoonProfileFill,
        label: 'Profil',
        iconSize: 29,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showProfileCompletionPromptIfNeeded();
    });
  }

  Future<void> _showProfileCompletionPromptIfNeeded() async {
    if (_profileCompletionPromptShown || !mounted || widget.isAdmin) {
      return;
    }

    _profileCompletionPromptShown = true;

    try {
      final ProfileCompletionStatus status =
          await ProfileCompletionService.instance.checkCurrentUser();
      if (!mounted || status.isComplete || status.isAdmin) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFFFCF5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            icon: const Icon(
              Icons.assignment_ind_outlined,
              size: 44,
              color: Color(0xFF9D6A18),
            ),
            title: const Text(
              'Lengkapi Profil Terlebih Dahulu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Text(
                'Profil belum lengkap. Lengkapi ${status.missingFieldsText}. '
                'Sebelum lengkap, akun tidak dapat mengunggah dokumen SK '
                'atau mengirim komentar dan balasan.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: <Widget>[
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  SiapNavigationController.selectTab(2);
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('LENGKAPI PROFIL'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9D6A18),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      );
    } catch (_) {
      // Pemeriksaan akan tetap dilakukan lagi saat aksi terbatas dipakai.
    }
  }

  @override
  void dispose() {
    SiapNavigationController.selectedIndex.removeListener(
      _syncSelectedIndex,
    );
    super.dispose();
  }

  void _syncSelectedIndex() {
    final int nextIndex =
        SiapNavigationController.selectedIndex.value;
    if (!mounted || nextIndex == _selectedIndex) return;

    setState(() {
      _selectedIndex = nextIndex;
    });
  }

  void _onItemSelected(int index) {
    SiapNavigationController.selectTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final double systemBottom =
        MediaQuery.viewPaddingOf(context).bottom;

    final double bottomGlassHeight =
        _siapBarHeight +
        _siapBarBottomMargin +
        systemBottom +
        _siapBottomGlassExtraHeight;

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
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: Image.asset(
                _backgroundAsset,
                fit: BoxFit.fill,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned.fill(
              child: IndexedStack(
                index: _selectedIndex,
                sizing: StackFit.expand,
                children: _pages,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: bottomGlassHeight,
              child: const IgnorePointer(
                child: _BottomGlassGradient(),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: systemBottom + _siapBarBottomMargin,
              height: _siapBarHeight,
              child: Hero(
                tag: _siapBottomNavigationHeroTag,
                transitionOnUserGestures: true,
                flightShuttleBuilder: _buildBottomNavigationFlight,
                child: _SiapFloatingBottomNavBar(
                  selectedIndex: _selectedIndex,
                  items: _navItems,
                  onItemSelected: _onItemSelected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SiapPageBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final bool isAdmin;
  final bool showBackgroundLayer;

  const SiapPageBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    this.isAdmin = false,
    this.showBackgroundLayer = false,
  });

  List<_SiapNavItem> get _items {
    if (isAdmin) {
      return const <_SiapNavItem>[
        _SiapNavItem(
          icon: MaterialSymbols.home_rounded,
          label: 'Home',
          iconSize: 28,
        ),
        _SiapNavItem(
          icon: MaterialSymbols.bookmark_rounded,
          label: 'Data Tersimpan',
          iconSize: 28,
        ),
        _SiapNavItem(
          icon: _iconamoonProfileFill,
          label: 'Profil',
          iconSize: 29,
        ),
      ];
    }

    return const <_SiapNavItem>[
      _SiapNavItem(
        icon: MaterialSymbols.home_rounded,
        label: 'Home',
        iconSize: 28,
      ),
      _SiapNavItem(
        icon: MaterialSymbols.add_rounded,
        label: 'Kelola Data',
        iconSize: 36,
      ),
      _SiapNavItem(
        icon: _iconamoonProfileFill,
        label: 'Profil',
        iconSize: 29,
      ),
    ];
  }

  void _onItemSelected(BuildContext context, int index) {
    SiapNavigationController.selectTab(index);
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final double systemBottom =
        MediaQuery.viewPaddingOf(context).bottom;
    final double totalHeight =
        _siapBarHeight +
        _siapBarBottomMargin +
        systemBottom +
        _siapBottomGlassExtraHeight;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (showBackgroundLayer)
            const Positioned.fill(
              child: IgnorePointer(
                child: _BottomGlassGradient(),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: systemBottom + _siapBarBottomMargin,
            height: _siapBarHeight,
            child: Hero(
              tag: _siapBottomNavigationHeroTag,
              transitionOnUserGestures: true,
              flightShuttleBuilder: _buildBottomNavigationFlight,
              child: _SiapFloatingBottomNavBar(
                selectedIndex: selectedIndex,
                items: _items,
                onItemSelected: (int index) {
                  _onItemSelected(context, index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomGlassGradient extends StatelessWidget {
  const _BottomGlassGradient();

  static const double _topRadius = 32;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(_topRadius),
        topRight: Radius.circular(_topRadius),
      ),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.bottomNavigationFadeGradient,
        ),
      ),
    );
  }
}

class _SiapFloatingBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_SiapNavItem> items;
  final ValueChanged<int> onItemSelected;

  const _SiapFloatingBottomNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onItemSelected,
  });

  static const double _activeCircleSize = 46;

  static const Color _activeColor = Color(0xFF269527);
  static const Color _inactiveColor = Color(0xFF2F512C);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF4),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0x78FFFFFF),
              width: 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (
              BuildContext context,
              BoxConstraints constraints,
            ) {
              final double itemWidth =
                  constraints.maxWidth / items.length;

              final double activeLeft =
                  (itemWidth * selectedIndex) +
                  ((itemWidth - _activeCircleSize) / 2);

              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 430),
                    curve: Curves.easeOutBack,
                    left: activeLeft,
                    top: 6,
                    child: Container(
                      width: _activeCircleSize,
                      height: _activeCircleSize,
                      decoration: const BoxDecoration(
                        color: _activeColor,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Color(0x32000000),
                            blurRadius: 9,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: List<Widget>.generate(
                      items.length,
                      (int index) {
                        return Expanded(
                          child: _SiapFloatingNavItem(
                            item: items[index],
                            active: selectedIndex == index,
                            activeColor: _activeColor,
                            inactiveColor: _inactiveColor,
                            onTap: () => onItemSelected(index),
                          ),
                        );
                      },
                    ),
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

class _SiapFloatingNavItem extends StatelessWidget {
  final _SiapNavItem item;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _SiapFloatingNavItem({
    required this.item,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: item.label,
      button: true,
      selected: active,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 46,
                child: Center(
                  child: AnimatedScale(
                    scale: active ? 1 : 0.92,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    child: Iconify(
                      item.icon,
                      size: item.iconSize,
                      color: active ? Colors.white : inactiveColor,
                    ),
                  ),
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: active
                      ? activeColor
                      : activeColor.withOpacity(0),
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: active ? 46 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SiapNavItem {
  final String icon;
  final String label;
  final double iconSize;

  const _SiapNavItem({
    required this.icon,
    required this.label,
    required this.iconSize,
  });
}
