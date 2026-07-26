import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/profilepegawai_model.dart';
import '../../models/users_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/profile_account_service.dart';
import '../../services/profile_photo_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/feedback/siap_top_notification.dart';
import '../../widgets/navigation/bottom_navigation_bar.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with WidgetsBindingObserver {
  static const Color _accent = Color(0xFF9D6A18);
  static const Color _card = Color(0xFFFFFCF5);

  late Future<_ProfilePageData> _profileFuture;

  bool _isCheckingVerifiedEmail = false;
  bool _isVerifiedEmailNoticeVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profileFuture = _loadProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkVerifiedEmailChange());
    }
  }

  Future<_ProfilePageData> _loadProfile() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw const _ProfilePageException(
        'Sesi pengguna tidak ditemukan.',
      );
    }

    try {
      final EmailSyncResult emailSyncResult =
          await ProfileAccountService.instance
              .syncFirebaseEmailToFirestore();
      _scheduleVerifiedEmailNotice(emailSyncResult);
    } catch (_) {
      // Profil tetap dimuat walau sinkronisasi email belum berhasil.
    }

    final List<dynamic> result =
        await Future.wait<dynamic>(<Future<dynamic>>[
      FirestoreService.instance.getUserData(uid),
      FirestoreService.instance.getProfilePegawai(uid),
    ]);

    final UsersModel? user = result[0] as UsersModel?;
    final ProfilePegawaiModel? profile =
        result[1] as ProfilePegawaiModel?;

    if (user == null || profile == null) {
      throw const _ProfilePageException(
        'Data profil belum tersedia.',
      );
    }

    final ProfileExtendedData extendedData =
        await ProfileService.instance.getExtendedProfileData(
      uid: uid,
      fallbackProfile: profile,
    );

    final String photoUrl = await ProfilePhotoService.instance
        .resolvePhotoUrl(profile.foto_profil);

    return _ProfilePageData(
      user: user,
      profile: profile,
      extendedData: extendedData,
      photoUrl: photoUrl,
    );
  }

  void _scheduleVerifiedEmailNotice(EmailSyncResult result) {
    if (!result.emailChangeVerified || !mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_showVerifiedEmailNotice(result.email));
    });
  }

  Future<void> _checkVerifiedEmailChange() async {
    if (_isCheckingVerifiedEmail ||
        _isVerifiedEmailNoticeVisible ||
        !mounted) {
      return;
    }

    _isCheckingVerifiedEmail = true;

    try {
      final EmailSyncResult result =
          await ProfileAccountService.instance
              .syncFirebaseEmailToFirestore();

      if (!mounted || !result.emailChangeVerified) {
        return;
      }

      await _showVerifiedEmailNotice(result.email);
    } catch (_) {
      // Pengecekan akan dicoba kembali saat aplikasi aktif lagi.
    } finally {
      _isCheckingVerifiedEmail = false;
    }
  }

  Future<void> _showVerifiedEmailNotice(String email) async {
    if (_isVerifiedEmailNoticeVisible || !mounted) {
      return;
    }

    _isVerifiedEmailNoticeVisible = true;

    try {
      await showSiapTopNotification(
        context: context,
        title: 'Email Berhasil Diubah',
        message:
            'Alamat email akun Anda telah diperbarui menjadi $email. '
            'Silakan login kembali menggunakan email baru Anda.',
        type: SiapNotificationType.success,
        primaryButtonLabel: 'LOGIN ULANG',
      );

      if (!mounted) {
        return;
      }

      final bool completed = await ProfileAccountService.instance
          .completeVerifiedEmailChange();

      if (!completed) {
        await showSiapTopNotification(
          context: context,
          title: 'Sinkronisasi Belum Selesai',
          message:
              'Status perubahan email belum dapat dipastikan. '
              'Pastikan koneksi internet aktif, lalu buka kembali aplikasi.',
          type: SiapNotificationType.error,
        );
        return;
      }

      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((Route<dynamic> route) => route.isFirst);

      await AuthService.instance.logout();
    } finally {
      _isVerifiedEmailNoticeVisible = false;
    }
  }

  Future<void> _refreshProfile() async {
    final Future<_ProfilePageData> next = _loadProfile();
    setState(() {
      _profileFuture = next;
    });
    await next;
  }

  Future<void> _openEditProfile(_ProfilePageData data) async {
    final bool? updated = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        pageBuilder: (_, _, _) => EditProfilePage(
          initialUser: data.user,
          initialProfile: data.profile,
          initialExtendedData: data.extendedData,
          initialPhotoUrl: data.photoUrl,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
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

    if (updated == true && mounted) {
      await _refreshProfile();
    }
  }

  Future<void> _confirmLogout() async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: _card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Keluar dari akun?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: const Text(
                'Sesi login pada perangkat ini akan diakhiri.',
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

    if (!confirmed) return;
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
        body: FutureBuilder<_ProfilePageData>(
          future: _profileFuture,
          builder: (
            BuildContext context,
            AsyncSnapshot<_ProfilePageData> snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _accent,
                ),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return _ProfileErrorView(
                message: snapshot.error is _ProfilePageException
                    ? (snapshot.error! as _ProfilePageException).message
                    : 'Gagal memuat profil.',
                onRetry: _refreshProfile,
              );
            }

            final _ProfilePageData data = snapshot.data!;

            return RefreshIndicator(
              color: _accent,
              onRefresh: _refreshProfile,
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: _ProfileTopHeader(
                      statusBarHeight: statusBarHeight,
                      onBack: () {
                        SiapNavigationController.selectTab(0);
                      },
                      onLogout: _confirmLogout,
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _IdentityHeaderDelegate(
                      statusBarHeight: statusBarHeight,
                      user: data.user,
                      profile: data.profile,
                      photoUrl: data.photoUrl,
                      onEdit: () => _openEditProfile(data),
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
                      delegate: SliverChildListDelegate(<Widget>[
                        _ProfileSectionCard(
                          title: 'Informasi Akun',
                          icon: Icons.badge_outlined,
                          children: <Widget>[
                            _InformationRow(
                              label: 'Nama pegawai',
                              value: _value(data.user.nama_lengkap),
                            ),
                            _InformationRow(
                              label: 'Username',
                              value: _value(data.user.username),
                            ),
                            _InformationRow(
                              label: 'Email',
                              value: _value(data.user.email),
                            ),
                            _InformationRow(
                              label: 'Nomor telepon',
                              value: _value(data.user.no_telepon),
                            ),
                            _InformationRow(
                              label: 'Role',
                              value: _value(data.user.role),
                            ),
                            _InformationRow(
                              label: 'Status akun',
                              value: _value(data.user.status_akun),
                              badge: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _ProfileSectionCard(
                          title: 'Informasi Kepegawaian',
                          icon: Icons.work_outline_rounded,
                          children: <Widget>[
                            _InformationRow(
                              label: 'NIP',
                              value: _value(data.user.nip),
                            ),
                            _InformationRow(
                              label: 'Status kepegawaian',
                              value: _value(
                                data.profile.status_kepegawaian,
                              ),
                            ),
                            if (_isAsn(
                              data.profile.status_kepegawaian,
                            ))
                              _InformationRow(
                                label: 'Jenis ASN',
                                value: _value(
                                  data.profile.jenis_asn,
                                ),
                              ),
                            _InformationRow(
                              label: 'Jabatan sekarang',
                              value: _value(
                                data.profile.jabatan_sekarang,
                              ),
                            ),
                            _InformationRow(
                              label: 'Tahun jabatan',
                              value: _year(
                                data.profile.tahun_jabatan_sekarang,
                              ),
                            ),
                            _InformationRow(
                              label: 'Pangkat',
                              value: _value(data.profile.pangkat),
                            ),
                            _InformationRow(
                              label: 'Tempat, tanggal lahir',
                              value: _placeAndDate(
                                data.extendedData.tempatLahir,
                                data.extendedData.tanggalLahir,
                              ),
                            ),
                            _InformationRow(
                              label: 'Pendidikan terakhir',
                              value: _nameAndYear(
                                data.extendedData.pendidikan,
                                data.extendedData
                                    .tahunLulusPendidikan,
                              ),
                            ),
                            _InformationRow(
                              label: 'Diklat terakhir',
                              value: _nameAndYear(
                                data.extendedData.latihanJabatan,
                                data.extendedData
                                    .tahunLatihanJabatan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _ExpandableHistoryCard(
                          title: 'Riwayat Pendidikan',
                          icon: Icons.school_outlined,
                          items: _educationHistoryItems(
                            data.extendedData.educationHistory,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ExpandableHistoryCard(
                          title: 'Riwayat Diklat',
                          icon: Icons.workspace_premium_outlined,
                          items: _trainingHistoryItems(
                            data.extendedData.trainingHistory,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ExpandableHistoryCard(
                          title: 'Riwayat Jabatan',
                          icon: Icons.timeline_rounded,
                          items: _positionHistoryItems(
                            data.extendedData.positionHistory,
                          ),
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
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ]),
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

  static bool _isAsn(String status) {
    return status.trim().toLowerCase() == 'asn';
  }

  static String _value(String value) {
    final String clean = value.trim();
    return clean.isEmpty ? '-' : clean;
  }

  static String _year(int year) {
    return year <= 0 ? '-' : year.toString();
  }

  static String _nameAndYear(String name, int year) {
    final String cleanName = name.trim();
    if (cleanName.isEmpty && year <= 0) return '-';
    if (year <= 0) return cleanName.isEmpty ? '-' : cleanName;
    if (cleanName.isEmpty) return year.toString();
    return '$cleanName ($year)';
  }

  static String _placeAndDate(String place, DateTime? date) {
    final String cleanPlace = place.trim();
    if (cleanPlace.isEmpty && date == null) return '-';
    if (date == null) return cleanPlace.isEmpty ? '-' : cleanPlace;

    const List<String> months = <String>[
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final String formatted =
        '${date.day} ${months[date.month - 1]} ${date.year}';
    return cleanPlace.isEmpty ? formatted : '$cleanPlace, $formatted';
  }

  static List<_HistoryDisplayItem> _positionHistoryItems(
    List<PositionHistoryEntry> history,
  ) {
    return history
        .asMap()
        .entries
        .map(
          (MapEntry<int, PositionHistoryEntry> entry) =>
              _HistoryDisplayItem(
            title: entry.value.jabatan,
            year: entry.value.tahun,
            subtitle: entry.key == 0
                ? 'Jabatan sekarang'
                : 'Jabatan sebelumnya',
          ),
        )
        .toList();
  }

  static List<_HistoryDisplayItem> _educationHistoryItems(
    List<EducationHistoryEntry> history,
  ) {
    return history
        .asMap()
        .entries
        .map(
          (MapEntry<int, EducationHistoryEntry> entry) =>
              _HistoryDisplayItem(
            title: entry.value.pendidikan,
            year: entry.value.tahun,
            subtitle: entry.key == 0
                ? 'Pendidikan terakhir'
                : 'Pendidikan sebelumnya',
          ),
        )
        .toList();
  }

  static List<_HistoryDisplayItem> _trainingHistoryItems(
    List<TrainingHistoryEntry> history,
  ) {
    return history
        .asMap()
        .entries
        .map(
          (MapEntry<int, TrainingHistoryEntry> entry) =>
              _HistoryDisplayItem(
            title: entry.value.latihanJabatan,
            year: entry.value.tahun,
            subtitle: entry.key == 0
                ? 'Diklat terakhir'
                : 'Diklat sebelumnya',
          ),
        )
        .toList();
  }
}

class _ProfileTopHeader extends StatelessWidget {
  final double statusBarHeight;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const _ProfileTopHeader({
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
                    'Profil',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF191919),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Menu profil',
                  onSelected: (String value) {
                    if (value == 'logout') {
                      onLogout();
                    }
                  },
                  itemBuilder: (_) => const <PopupMenuEntry<String>>[
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

class _IdentityHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  final double statusBarHeight;
  final UsersModel user;
  final ProfilePegawaiModel profile;
  final String photoUrl;
  final VoidCallback onEdit;

  const _IdentityHeaderDelegate({
    required this.statusBarHeight,
    required this.user,
    required this.profile,
    required this.photoUrl,
    required this.onEdit,
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
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  10,
                  42,
                  10,
                ),
                child: Row(
                  children: <Widget>[
                    _ProfileAvatar(
                      photoUrl: photoUrl,
                      radius: 41,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            user.nama_lengkap.trim().isEmpty
                                ? 'Pengguna'
                                : user.nama_lengkap.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: Color(0xFF191919),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'NIP: ${user.nip.trim().isEmpty ? '-' : user.nip.trim()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              letterSpacing: 0.5,
                              color: Color(0xFF383838),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 3,
                right: 3,
                child: IconButton(
                  tooltip: 'Edit profil',
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_square,
                    size: 20,
                    color: Color(0xFF2F2F2F),
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
    covariant _IdentityHeaderDelegate oldDelegate,
  ) {
    return oldDelegate.statusBarHeight != statusBarHeight ||
        oldDelegate.user != user ||
        oldDelegate.profile != profile ||
        oldDelegate.photoUrl != photoUrl ||
        oldDelegate.onEdit != onEdit;
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String photoUrl;
  final double radius;

  const _ProfileAvatar({
    required this.photoUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final String cleanUrl = photoUrl.trim();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEAD8B2),
      foregroundImage:
          cleanUrl.startsWith('http') ? NetworkImage(cleanUrl) : null,
      child: cleanUrl.startsWith('http')
          ? null
          : Icon(
              Icons.person_rounded,
              size: radius * 1.2,
              color: const Color(0xFF9D6A18),
            ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ProfileSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 12),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFCF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x66FFFFFF),
          width: 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF9D6A18),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191919),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final String label;
  final String value;
  final bool badge;

  const _InformationRow({
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

class _HistoryDisplayItem {
  final String title;
  final int year;
  final String subtitle;

  const _HistoryDisplayItem({
    required this.title,
    required this.year,
    required this.subtitle,
  });
}

class _ExpandableHistoryCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<_HistoryDisplayItem> items;

  const _ExpandableHistoryCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  State<_ExpandableHistoryCard> createState() =>
      _ExpandableHistoryCardState();
}

class _ExpandableHistoryCardState
    extends State<_ExpandableHistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final List<_HistoryDisplayItem> history =
        widget.items.isEmpty
            ? const <_HistoryDisplayItem>[
                _HistoryDisplayItem(
                  title: '-',
                  year: 0,
                  subtitle: 'Belum ada data',
                ),
              ]
            : widget.items;

    final bool canExpand = history.length > 3;
    final List<_HistoryDisplayItem> visibleItems =
        _expanded || !canExpand
            ? history
            : history.take(3).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 17),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFCF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x66FFFFFF),
          width: 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                widget.icon,
                size: 21,
                color: const Color(0xFF9D6A18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (canExpand)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: _expanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                    ),
                  ),
                  label: Text(
                    _expanded ? 'Ringkas' : 'Lihat semua',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          ...List<Widget>.generate(
            visibleItems.length,
            (int index) {
              final _HistoryDisplayItem item = visibleItems[index];
              return _TimelineItem(
                active: index == 0 && item.title.trim() != '-',
                title: item.title.trim().isEmpty
                    ? '-'
                    : item.title.trim(),
                year: item.year <= 0 ? '-' : item.year.toString(),
                subtitle: item.subtitle,
                showLine: index < visibleItems.length - 1,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final bool active;
  final String title;
  final String year;
  final String subtitle;
  final bool showLine;

  const _TimelineItem({
    required this.active,
    required this.title,
    required this.year,
    required this.subtitle,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 36,
            child: Column(
              children: <Widget>[
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF9EC7A0)
                        : const Color(0xFFFFFCF5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active
                          ? const Color(0xFF5B8E60)
                          : const Color(0xFFE4A23C),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF5B8E60)
                            : const Color(0xFFE4A23C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: 3,
                      ),
                      color: const Color(0xFFD8D8D8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: showLine ? 24 : 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF202020),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF756F65),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    year,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF756F65),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ProfileErrorView({
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
              Icons.person_off_outlined,
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

class _ProfilePageData {
  final UsersModel user;
  final ProfilePegawaiModel profile;
  final ProfileExtendedData extendedData;
  final String photoUrl;

  const _ProfilePageData({
    required this.user,
    required this.profile,
    required this.extendedData,
    required this.photoUrl,
  });
}

class _ProfilePageException implements Exception {
  final String message;

  const _ProfilePageException(this.message);

  @override
  String toString() => message;
}
