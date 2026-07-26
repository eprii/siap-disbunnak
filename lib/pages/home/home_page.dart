import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/pegawai_directory_service.dart';
import '../../utils/common_first_names.dart';
import '../../widgets/profile/pegawai_avatar.dart';
import '../pegawai/detail_pegawai_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver {
  static const String _logoAsset =
      'assets/images/logo/LOGO_KALSEL.png';

  static const Color _accentColor = Color(0xFFB87915);
  static const Color _cardColor = Color(0xFFFFFBF2);
  static const Color _textColor = Color(0xFF1E1E1E);
  static const Color _mutedTextColor = Color(0xFF6F6F6F);

  static const double _expandedTopHeight = 176;
  static const double _controlsBodyHeight = 112;
  static const double _bottomFadeHeight = 14;

  static const List<String> _filters = <String>[
    'ALL',
    'ASN',
    'Jabatan Struktural',
    'Jabatan Fungsional',
    'P3K',
    'P3K Paruh Waktu',
    'PJLP',
  ];

  final TextEditingController _searchController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final Stream<List<PegawaiDirectoryItem>> _employeesStream;
  late String _currentGreeting;

  Timer? _greetingTimer;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentGreeting = _resolveGreeting(DateTime.now());
    _employeesStream =
        PegawaiDirectoryService.instance.watchEmployees();
    _scheduleGreetingUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshGreeting();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _greetingTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<PegawaiDirectoryItem> _filterEmployees(
    List<PegawaiDirectoryItem> source,
  ) {
    final String keyword =
        _searchController.text.trim().toLowerCase();

    return source.where((PegawaiDirectoryItem employee) {
      final bool matchSearch = keyword.isEmpty ||
          employee.namaLengkap.toLowerCase().contains(keyword) ||
          employee.nip.toLowerCase().contains(keyword) ||
          employee.jabatanSekarang.toLowerCase().contains(keyword) ||
          employee.statusKepegawaian.toLowerCase().contains(keyword) ||
          employee.pangkat.toLowerCase().contains(keyword);

      if (!matchSearch) return false;

      switch (_selectedFilter) {
        case 'ASN':
          return employee.statusKepegawaian.toLowerCase() == 'asn';
        case 'Jabatan Struktural':
          return employee.jenisAsn.toLowerCase().contains('struktural');
        case 'Jabatan Fungsional':
          return employee.jenisAsn.toLowerCase().contains('fungsional');
        case 'P3K':
          return employee.statusKepegawaian.toLowerCase() == 'p3k';
        case 'P3K Paruh Waktu':
          return employee.statusKepegawaian.toLowerCase() ==
              'p3k paruh waktu';
        case 'PJLP':
          return employee.statusKepegawaian.toLowerCase() == 'pjlp';
        default:
          return true;
      }
    }).toList();
  }

  double _collapsedHeaderExtent(BuildContext context) {
    return MediaQuery.viewPaddingOf(context).top +
        _controlsBodyHeight +
        _bottomFadeHeight;
  }

  double _headerCollapseDistance(BuildContext context) {
    return _expandedTopHeight -
        MediaQuery.viewPaddingOf(context).top;
  }

  void _moveResultsToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final double collapseDistance =
          _headerCollapseDistance(context);
      final double target =
          _scrollController.offset > collapseDistance
              ? collapseDistance
              : 0;

      _scrollController.animateTo(
        target
            .clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            )
            .toDouble(),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _selectFilter(String filter) {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);
    _moveResultsToTop();
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _moveResultsToTop();
  }

  void _openEmployee(PegawaiDirectoryItem employee) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => DetailPegawaiPage(
          employeeUid: employee.uid,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration:
            const Duration(milliseconds: 220),
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final Animation<Offset> position = Tween<Offset>(
            begin: const Offset(0.035, 0),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight =
        MediaQuery.viewPaddingOf(context).top;
    final double listBottomPadding =
        80 +
        12 +
        MediaQuery.viewPaddingOf(context).bottom +
        28;

    return StreamBuilder<List<PegawaiDirectoryItem>>(
      stream: _employeesStream,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<PegawaiDirectoryItem>> snapshot,
      ) {
        final List<PegawaiDirectoryItem> allEmployees =
            snapshot.data ?? <PegawaiDirectoryItem>[];
        final List<PegawaiDirectoryItem> filteredEmployees =
            _filterEmployees(allEmployees);
        final PegawaiDirectoryItem? currentEmployee =
            _findCurrentEmployee(allEmployees);

        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: const <PointerDeviceKind>{
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverPersistentHeader(
                pinned: true,
                delegate: _HomePinnedHeaderDelegate(
                  minHeaderExtent:
                      _collapsedHeaderExtent(context),
                  maxHeaderExtent: _expandedTopHeight +
                      _controlsBodyHeight +
                      _bottomFadeHeight,
                  statusBarHeight: statusBarHeight,
                  expandedContent: _buildExpandedHeader(
                    currentEmployee,
                  ),
                  searchField: _buildSearchField(),
                  filterList: _buildFilterList(),
                ),
              ),
              if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                  !snapshot.hasData)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: listBottomPadding,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: _accentColor,
                      ),
                    ),
                  ),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      28,
                      30,
                      28,
                      listBottomPadding,
                    ),
                    child: _HomeErrorState(
                      message:
                          'Gagal memuat data pegawai.\n${snapshot.error}',
                    ),
                  ),
                )
              else if (filteredEmployees.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: listBottomPadding,
                    ),
                    child: const _EmptyState(),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    6,
                    22,
                    listBottomPadding,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        if (index.isOdd) {
                          return const SizedBox(height: 18);
                        }

                        final PegawaiDirectoryItem employee =
                            filteredEmployees[index ~/ 2];

                        return _buildPegawaiCard(employee);
                      },
                      childCount:
                          (filteredEmployees.length * 2) - 1,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  PegawaiDirectoryItem? _findCurrentEmployee(
    List<PegawaiDirectoryItem> employees,
  ) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    for (final PegawaiDirectoryItem employee in employees) {
      if (employee.uid == uid) return employee;
    }
    return null;
  }

  Widget _buildExpandedHeader(
    PegawaiDirectoryItem? currentEmployee,
  ) {
    final String displayName = currentEmployee == null
        ? 'Pegawai'
        : _resolveGreetingName(
            currentEmployee.namaLengkap,
          );

    return Column(
      children: <Widget>[
        _buildTopIdentity(),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$_currentGreeting, $displayName',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _resolveGreetingName(String fullName) {
    final String normalizedName = fullName
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    if (normalizedName.isEmpty) {
      return 'Pegawai';
    }

    final List<String> words = normalizedName.split(' ');
    final List<String> normalizedWords = words
        .map((String word) => word.toLowerCase())
        .toList(growable: false);

    int longestMatchedPrefix = 0;

    for (final String prefix in commonFirstNamePrefixes) {
      final List<String> prefixWords = prefix
          .trim()
          .toLowerCase()
          .split(RegExp(r'\s+'));

      if (prefixWords.length > normalizedWords.length ||
          prefixWords.length <= longestMatchedPrefix) {
        continue;
      }

      bool matches = true;

      for (int index = 0; index < prefixWords.length; index++) {
        if (normalizedWords[index] != prefixWords[index]) {
          matches = false;
          break;
        }
      }

      if (matches) {
        longestMatchedPrefix = prefixWords.length;
      }
    }

    if (longestMatchedPrefix == 0) {
      return words.first;
    }

    final int requestedWordCount = longestMatchedPrefix + 1;
    final int displayWordCount =
        requestedWordCount > words.length
            ? words.length
            : requestedWordCount;

    return words.take(displayWordCount).join(' ');
  }

  String _resolveGreeting(DateTime dateTime) {
    final int hour = dateTime.hour;

    if (hour >= 3 && hour < 11) {
      return 'Selamat Pagi';
    }

    if (hour >= 11 && hour < 16) {
      return 'Selamat Siang';
    }

    if (hour >= 16 && hour < 19) {
      return 'Selamat Sore';
    }

    return 'Selamat Malam';
  }

  DateTime _nextGreetingBoundary(DateTime now) {
    final DateTime todayAtThree = DateTime(
      now.year,
      now.month,
      now.day,
      3,
    );
    final DateTime todayAtEleven = DateTime(
      now.year,
      now.month,
      now.day,
      11,
    );
    final DateTime todayAtSixteen = DateTime(
      now.year,
      now.month,
      now.day,
      16,
    );
    final DateTime todayAtNineteen = DateTime(
      now.year,
      now.month,
      now.day,
      19,
    );

    if (now.isBefore(todayAtThree)) {
      return todayAtThree;
    }

    if (now.isBefore(todayAtEleven)) {
      return todayAtEleven;
    }

    if (now.isBefore(todayAtSixteen)) {
      return todayAtSixteen;
    }

    if (now.isBefore(todayAtNineteen)) {
      return todayAtNineteen;
    }

    return DateTime(
      now.year,
      now.month,
      now.day + 1,
      3,
    );
  }

  void _scheduleGreetingUpdate() {
    _greetingTimer?.cancel();

    final DateTime now = DateTime.now();
    final DateTime nextBoundary = _nextGreetingBoundary(now);
    final Duration delay = nextBoundary.difference(now);

    _greetingTimer = Timer(
      delay + const Duration(milliseconds: 100),
      _refreshGreeting,
    );
  }

  void _refreshGreeting() {
    if (!mounted) {
      return;
    }

    final String nextGreeting =
        _resolveGreeting(DateTime.now());

    if (nextGreeting != _currentGreeting) {
      setState(() {
        _currentGreeting = nextGreeting;
      });
    }

    _scheduleGreetingUpdate();
  }

  Widget _buildTopIdentity() {
    final double statusBarHeight =
        MediaQuery.viewPaddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        28,
        statusBarHeight + 10,
        22,
        0,
      ),
      child: Row(
        children: <Widget>[
          Image.asset(
            _logoAsset,
            width: 42,
            height: 50,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.account_balance_rounded,
              size: 42,
              color: _accentColor,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SIAP',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Sistem Informasi Administrasi\nPegawai',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.18,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF8EBCD),
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0x38000000),
                  blurRadius: 7,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Notifikasi',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Fitur notifikasi belum tersedia.',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_rounded,
                size: 21,
                color: Color(0xFF8B570B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Cari nama, NIP, jabatan, atau pangkat',
          hintStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
          suffixIcon: _searchController.text.isEmpty
              ? const Icon(
                  Icons.search_rounded,
                  size: 21,
                  color: Color(0xFF4A4A4A),
                )
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                  ),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(
              color: Color(0xFF898989),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(
              color: _accentColor,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterList() {
    return SizedBox(
      height: 48,
      child: ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(
          dragDevices: const <PointerDeviceKind>{
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: ListView.separated(
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(26, 3, 26, 4),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (BuildContext context, int index) {
            final String filter = _filters[index];
            final bool selected = filter == _selectedFilter;

            return Container(
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x28000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: selected
                    ? const Color(0xFFE3C683)
                    : const Color(0xFFFFFCF5),
                borderRadius: BorderRadius.circular(9),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _selectFilter(filter),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? const Color(0xFF5A3A06)
                              : _textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPegawaiCard(PegawaiDirectoryItem employee) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openEmployee(employee),
          child: SizedBox(
            height: 126,
            child: Stack(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    12,
                    44,
                    12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      PegawaiAvatar(
                        storedPhoto: employee.fotoProfil,
                        radius: 34,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              employee.namaLengkap,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildInfoText(
                              'NIP : ${_value(employee.nip)}',
                            ),
                            const SizedBox(height: 4),
                            _buildInfoText(
                              'Jabatan : ${_value(employee.jabatanSekarang)}',
                            ),
                            const SizedBox(height: 4),
                            _buildInfoText(
                              employee.jenisAsn.isEmpty
                                  ? 'Status : ${_value(employee.statusKepegawaian)}'
                                  : 'Jenis : ${employee.jenisAsn}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 2,
                  child: PopupMenuButton<String>(
                    tooltip: 'Menu pegawai',
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    onSelected: (String value) {
                      if (value == 'detail') {
                        _openEmployee(employee);
                      }
                    },
                    itemBuilder: (_) => const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'detail',
                        child: Text('Lihat profil'),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 10,
                  child: _buildStatusBadge(
                    employee.statusKepegawaian,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 10,
        color: _mutedTextColor,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFD3EBCB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status.trim().isEmpty ? 'Belum diisi' : status.trim(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2A7A30),
        ),
      ),
    );
  }

  static String _value(String value) {
    final String cleanValue = value.trim();
    return cleanValue.isEmpty ? '-' : cleanValue;
  }
}

class _HomePinnedHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  final double minHeaderExtent;
  final double maxHeaderExtent;
  final double statusBarHeight;
  final Widget expandedContent;
  final Widget searchField;
  final Widget filterList;

  const _HomePinnedHeaderDelegate({
    required this.minHeaderExtent,
    required this.maxHeaderExtent,
    required this.statusBarHeight,
    required this.expandedContent,
    required this.searchField,
    required this.filterList,
  });

  @override
  double get minExtent => minHeaderExtent;

  @override
  double get maxExtent => maxHeaderExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double collapseDistance = maxExtent - minExtent;
    final double progress = collapseDistance == 0
        ? 1
        : (shrinkOffset / collapseDistance).clamp(0.0, 1.0);
    final double easedProgress =
        Curves.easeInOutCubic.transform(progress);
    final double controlsTopPadding =
        statusBarHeight * easedProgress;
    final Color pinnedGradientColor = Color.lerp(
      const Color(0x00FFFCF4),
      const Color(0xFFFFFCF4),
      easedProgress,
    )!;

    return Material(
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    pinnedGradientColor,
                    const Color(0x00FFFCF4),
                  ],
                  stops: const <double>[0.0, 1.0],
                ),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 76,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0x2E000000),
                      Color(0x00000000),
                    ],
                    stops: <double>[0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -_HomePageState._expandedTopHeight *
                easedProgress,
            left: 0,
            right: 0,
            height: _HomePageState._expandedTopHeight,
            child: IgnorePointer(
              ignoring: easedProgress > 0.82,
              child: expandedContent,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: _HomePageState._bottomFadeHeight,
            child: Padding(
              padding: EdgeInsets.only(
                top: controlsTopPadding,
              ),
              child: SizedBox(
                height: _HomePageState._controlsBodyHeight,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: searchField,
                    ),
                    const SizedBox(height: 14),
                    filterList,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(
    covariant _HomePinnedHeaderDelegate oldDelegate,
  ) {
    return oldDelegate.minHeaderExtent != minHeaderExtent ||
        oldDelegate.maxHeaderExtent != maxHeaderExtent ||
        oldDelegate.statusBarHeight != statusBarHeight ||
        oldDelegate.expandedContent != expandedContent ||
        oldDelegate.searchField != searchField ||
        oldDelegate.filterList != filterList;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.person_search_outlined,
              size: 56,
              color: Color(0xFF9B681C),
            ),
            SizedBox(height: 12),
            Text(
              'Pegawai tidak ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  final String message;

  const _HomeErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.cloud_off_rounded,
            size: 54,
            color: Color(0xFF9B681C),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
