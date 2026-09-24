import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';
import '../../config/sk_definitions.dart';
import '../../models/users_model.dart';
import 'admin_sk_explorer_page.dart';
import '../../services/admin_dashboard_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/navigation/bottom_navigation_bar.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() =>
      _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  static const Color _accent = Color(0xFF9D6A18);
  static const Color _solidCard = Color(0xFFFFFCF5);

  late final Stream<UsersModel?> _adminStream;
  late Future<AdminDashboardSummary> _dashboardFuture;

  @override
  void initState() {
    super.initState();

    final String uid =
        FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

    _adminStream = uid.isEmpty
        ? Stream<UsersModel?>.value(null)
        : FirestoreService.instance.watchUser(uid);
    _dashboardFuture =
        AdminDashboardService.instance.getSummary();
    AdminDashboardService.instance.changeVersion.addListener(
      _handleDashboardChanged,
    );
  }

  @override
  void dispose() {
    AdminDashboardService.instance.changeVersion.removeListener(
      _handleDashboardChanged,
    );
    super.dispose();
  }

  void _handleDashboardChanged() {
    if (!mounted) return;
    _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    final Future<AdminDashboardSummary> next =
        AdminDashboardService.instance.getSummary();

    setState(() {
      _dashboardFuture = next;
    });

    await next;
  }

  void _openSkStatus(SiapSkReviewStatus status) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdminSkExplorerPage(
          status: status,
          initialMode: AdminSkExplorerViewMode.users,
        ),
      ),
    );
  }

  void _openSkCollection(SkDefinition definition) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdminSkExplorerPage(
          collection: definition.collection,
          initialMode: AdminSkExplorerViewMode.documents,
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: _solidCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Keluar dari akun admin?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: const Text(
                'Sesi administrator pada perangkat ini akan diakhiri.',
                style: TextStyle(fontSize: 13),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('BATAL'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD90000),
                  ),
                  child: const Text('LOGOUT'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await AuthService.instance.logout();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight =
        MediaQuery.viewPaddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: StreamBuilder<UsersModel?>(
          stream: _adminStream,
          builder: (
            BuildContext context,
            AsyncSnapshot<UsersModel?> accountSnapshot,
          ) {
            if (accountSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !accountSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _accent,
                ),
              );
            }

            if (accountSnapshot.hasError ||
                accountSnapshot.data == null) {
              return _AdminProfileErrorView(
                message: accountSnapshot.hasError
                    ? 'Gagal memuat akun admin.'
                    : 'Data akun admin tidak ditemukan.',
                onRetry: _refreshDashboard,
              );
            }

            final UsersModel admin = accountSnapshot.data!;

            return RefreshIndicator(
              color: _accent,
              onRefresh: _refreshDashboard,
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: _AdminTopHeader(
                      statusBarHeight: statusBarHeight,
                      onBack: () {
                        SiapNavigationController.selectTab(0);
                      },
                      onLogout: _confirmLogout,
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _AdminIdentityHeaderDelegate(
                      statusBarHeight: statusBarHeight,
                      admin: admin,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      130,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        <Widget>[
                          _AdminInformationCard(admin: admin),
                          const SizedBox(height: 14),
                          FutureBuilder<AdminDashboardSummary>(
                            future: _dashboardFuture,
                            builder: (
                              BuildContext context,
                              AsyncSnapshot<AdminDashboardSummary>
                                  dashboardSnapshot,
                            ) {
                              if (dashboardSnapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !dashboardSnapshot.hasData) {
                                return const _DashboardLoadingCard();
                              }

                              if (dashboardSnapshot.hasError ||
                                  dashboardSnapshot.data == null) {
                                return _DashboardErrorCard(
                                  onRetry: _refreshDashboard,
                                );
                              }

                              return _AdminDashboardCard(
                                summary: dashboardSnapshot.data!,
                                onOpenStatus: _openSkStatus,
                                onOpenCollection: _openSkCollection,
                              );
                            },
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: _confirmLogout,
                              icon: const Icon(
                                Icons.logout_rounded,
                                size: 19,
                              ),
                              label: const Text('Logout'),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFD90000),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AdminTopHeader extends StatelessWidget {
  final double statusBarHeight;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const _AdminTopHeader({
    required this.statusBarHeight,
    required this.onBack,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: statusBarHeight + 74,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0x20FFFCF4),
                    Color(0x10FFFCF4),
                  ],
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
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 2,
            height: 58,
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: 'Kembali ke Home',
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 2),
                const Expanded(
                  child: Text(
                    'Profil Admin',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF191919),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Menu admin',
                  onSelected: (String value) {
                    if (value == 'logout') {
                      onLogout();
                    }
                  },
                  itemBuilder: (_) =>
                      const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.logout_rounded,
                            size: 19,
                          ),
                          SizedBox(width: 10),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 23,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminIdentityHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  final double statusBarHeight;
  final UsersModel admin;

  const _AdminIdentityHeaderDelegate({
    required this.statusBarHeight,
    required this.admin,
  });

  @override
  double get minExtent => statusBarHeight + 126;

  @override
  double get maxExtent => statusBarHeight + 126;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          statusBarHeight + 5,
          20,
          9,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: const Color(0xF5FFFCF5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0x78FFFFFF),
              width: 1,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 78,
                height: 78,
                decoration: const BoxDecoration(
                  color: Color(0xFFEED8A5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 43,
                  color: Color(0xFF9D6A18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _value(admin.nama_lengkap),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF202020),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Administrator SIAP',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF756F65),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7EED0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A7A30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(
    covariant _AdminIdentityHeaderDelegate oldDelegate,
  ) {
    return oldDelegate.statusBarHeight != statusBarHeight ||
        oldDelegate.admin != admin;
  }
}

class _AdminInformationCard extends StatelessWidget {
  final UsersModel admin;

  const _AdminInformationCard({
    required this.admin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      decoration: AppTheme.glassSurfaceDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.badge_outlined,
                size: 21,
                color: Color(0xFF9D6A18),
              ),
              SizedBox(width: 9),
              Text(
                'Informasi Admin',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AdminInformationRow(
            label: 'Nama',
            value: _value(admin.nama_lengkap),
          ),
          _AdminInformationRow(
            label: 'Username',
            value: _value(admin.username),
          ),
          _AdminInformationRow(
            label: 'Email',
            value: _value(admin.email),
          ),
          const _AdminInformationRow(
            label: 'Role',
            value: 'Admin',
          ),
          _AdminInformationRow(
            label: 'Status akun',
            value: _value(admin.status_akun),
            badge: true,
          ),
        ],
      ),
    );
  }
}

class _AdminDashboardCard extends StatelessWidget {
  final AdminDashboardSummary summary;
  final ValueChanged<SiapSkReviewStatus> onOpenStatus;
  final ValueChanged<SkDefinition> onOpenCollection;

  const _AdminDashboardCard({
    required this.summary,
    required this.onOpenStatus,
    required this.onOpenCollection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: AppTheme.glassSurfaceDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.dashboard_customize_outlined,
                size: 22,
                color: Color(0xFF9D6A18),
              ),
              SizedBox(width: 9),
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _DashboardMetricCard(
                  icon: Icons.group_outlined,
                  label: 'Total User',
                  value: summary.totalUsers,
                  accent: const Color(0xFF2F6FA8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DashboardMetricCard(
                  icon: Icons.folder_copy_outlined,
                  label: 'Total SK',
                  value: summary.totalSk,
                  accent: const Color(0xFF9D6A18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _DashboardMiniMetric(
                  label: 'User Aktif',
                  value: summary.activeUsers,
                  accent: const Color(0xFF2A7A30),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DashboardMiniMetric(
                  label: 'User Nonaktif',
                  value: summary.inactiveUsers,
                  accent: const Color(0xFFB3261E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Status Pemeriksaan SK',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF292929),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (
              BuildContext context,
              BoxConstraints constraints,
            ) {
              final double itemWidth =
                  (constraints.maxWidth - 16) / 3;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  SizedBox(
                    width: itemWidth,
                    child: _StatusMetric(
                      label: 'Belum diperiksa',
                      value: summary.pendingSk,
                      background: const Color(0xFFFFEAC0),
                      foreground: const Color(0xFF8A5A00),
                      onTap: () => onOpenStatus(
                        SiapSkReviewStatus.pending,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _StatusMetric(
                      label: 'Disetujui',
                      value: summary.approvedSk,
                      background: const Color(0xFFD7EED0),
                      foreground: const Color(0xFF2A7A30),
                      onTap: () => onOpenStatus(
                        SiapSkReviewStatus.approved,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _StatusMetric(
                      label: 'Ditolak',
                      value: summary.rejectedSk,
                      background: const Color(0xFFFFDAD6),
                      foreground: const Color(0xFFB3261E),
                      onTap: () => onOpenStatus(
                        SiapSkReviewStatus.rejected,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          const Text(
            'Jumlah SK per Jenis',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF292929),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xA8FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0x70FFFFFF),
              ),
            ),
            child: Column(
              children: List<Widget>.generate(
                siapSkDefinitions.length,
                (int index) {
                  final SkDefinition definition =
                      siapSkDefinitions[index];

                  return Column(
                    children: <Widget>[
                      _SkCountRow(
                        label: definition.label,
                        count: summary.countFor(
                          definition.collection,
                        ),
                        onTap: () => onOpenCollection(definition),
                      ),
                      if (index < siapSkDefinitions.length - 1)
                        const Divider(
                          height: 1,
                          indent: 46,
                          endIndent: 14,
                          color: Color(0x24A0783A),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color accent;

  const _DashboardMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xBCFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x80FFFFFF),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202020),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF756F65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMiniMetric extends StatelessWidget {
  final String label;
  final int value;
  final Color accent;

  const _DashboardMiniMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF5F5B53),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  final String label;
  final int value;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _StatusMetric({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          height: 104,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkCountRow extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;

  const _SkCountRow({
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 10, 9, 10),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.description_outlined,
                size: 19,
                color: Color(0xFF9D6A18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3B3935),
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 34),
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAC0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A5A00),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: Color(0xFF6E675C),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminInformationRow extends StatelessWidget {
  final String label;
  final String value;
  final bool badge;

  const _AdminInformationRow({
    required this.label,
    required this.value,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF756F65),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 6,
            child: badge
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7EED0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2A7A30),
                        ),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF292929),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoadingCard extends StatelessWidget {
  const _DashboardLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: AppTheme.glassSurfaceDecoration(radius: 14),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF9D6A18),
        ),
      ),
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _DashboardErrorCard({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassSurfaceDecoration(radius: 14),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.query_stats_outlined,
            size: 38,
            color: Color(0xFF9D6A18),
          ),
          const SizedBox(height: 10),
          const Text(
            'Dashboard belum dapat dimuat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _AdminProfileErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _AdminProfileErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.admin_panel_settings_outlined,
              size: 58,
              color: Color(0xFF9D6A18),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

String _value(String value) {
  final String clean = value.trim();
  return clean.isEmpty ? '-' : clean;
}
