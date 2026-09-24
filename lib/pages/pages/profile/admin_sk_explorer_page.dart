import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';
import '../../config/sk_definitions.dart';
import '../../services/admin_sk_explorer_service.dart';
import '../../services/pegawai_directory_service.dart';
import '../../services/sk_comment_service.dart';
import '../../widgets/navigation/bottom_navigation_bar.dart';
import '../../widgets/profile/pegawai_avatar.dart';
import '../pegawai/detail_pegawai_page.dart';

enum AdminSkExplorerViewMode {
  users,
  documents,
}

class AdminSkExplorerPage extends StatefulWidget {
  final String collection;
  final SiapSkReviewStatus? status;
  final AdminSkExplorerViewMode initialMode;

  const AdminSkExplorerPage({
    super.key,
    this.collection = '',
    this.status,
    this.initialMode = AdminSkExplorerViewMode.users,
  });

  @override
  State<AdminSkExplorerPage> createState() =>
      _AdminSkExplorerPageState();
}

class _AdminSkExplorerPageState extends State<AdminSkExplorerPage> {
  static const Color _accent = Color(0xFF9D6A18);
  static const Color _muted = Color(0xFF756F65);

  final TextEditingController _searchController = TextEditingController();

  late Future<List<AdminSkExplorerRecord>> _recordsFuture;
  late AdminSkExplorerViewMode _viewMode;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialMode;
    _recordsFuture = _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<AdminSkExplorerRecord>> _loadRecords() {
    return AdminSkExplorerService.instance.loadRecords(
      collection: widget.collection,
      status: widget.status,
    );
  }

  Future<void> _refresh() async {
    final Future<List<AdminSkExplorerRecord>> next = _loadRecords();
    setState(() => _recordsFuture = next);
    await next;
  }

  String get _pageTitle {
    if (widget.status != null) {
      return siapSkStatusLabel(siapSkStatusValue(widget.status!));
    }
    return siapSkLabelForCollection(widget.collection);
  }

  String get _pageSubtitle {
    if (widget.status != null) {
      return 'Daftar pegawai dan dokumen dengan status ${_pageTitle.toLowerCase()}.';
    }
    return 'Daftar pegawai dan dokumen untuk $_pageTitle.';
  }

  void _openEmployee(AdminSkExplorerRecord record) {
    final String ownerId = record.sk.ownerId.trim();
    if (ownerId.isEmpty) return;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DetailPegawaiPage(
          employeeUid: ownerId,
          initialSkKey: record.sk.commentKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: const Color(0xFF191919),
          leading: IconButton(
            tooltip: 'Kembali',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 24,
            ),
          ),
          title: Text(
            _pageTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF191919),
            ),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              'assets/images/background/background_image.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
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
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.viewPaddingOf(context).top + kToolbarHeight,
              ),
              child: RefreshIndicator(
                color: _accent,
                onRefresh: _refresh,
                child: FutureBuilder<List<AdminSkExplorerRecord>>(
            future: _recordsFuture,
            builder: (
              BuildContext context,
              AsyncSnapshot<List<AdminSkExplorerRecord>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: _accent),
                );
              }

              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 120),
                  children: <Widget>[
                    _ExplorerEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Data SK gagal dimuat',
                      message: snapshot.error.toString(),
                    ),
                  ],
                );
              }

              final List<AdminSkExplorerRecord> allRecords =
                  snapshot.data ?? <AdminSkExplorerRecord>[];
              final String keyword =
                  _searchController.text.trim().toLowerCase();
              final List<AdminSkExplorerRecord> records = allRecords.where(
                (AdminSkExplorerRecord record) {
                  if (keyword.isEmpty) return true;
                  final String name =
                      record.employee?.namaLengkap.toLowerCase() ?? '';
                  final String nip = record.employee?.nip.toLowerCase() ?? '';
                  final String number = record.sk.nomor.toLowerCase();
                  final String type = record.sk.jenisLabel.toLowerCase();
                  return name.contains(keyword) ||
                      nip.contains(keyword) ||
                      number.contains(keyword) ||
                      type.contains(keyword);
                },
              ).toList(growable: false);

              final List<_EmployeeSkGroup> groups =
                  _groupByEmployee(records);

              return CustomScrollView(
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Text(
                        _pageSubtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: _muted,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Cari nama, NIP, jenis, atau nomor SK',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Hapus pencarian',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: const Color(0xFFFFFCF5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0x55C9C1B1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0x55C9C1B1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _accent,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: _ExplorerModeButton(
                              label: 'User',
                              icon: Icons.people_alt_outlined,
                              selected:
                                  _viewMode == AdminSkExplorerViewMode.users,
                              onTap: () => setState(
                                () => _viewMode =
                                    AdminSkExplorerViewMode.users,
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _ExplorerModeButton(
                              label: 'SK',
                              icon: Icons.description_outlined,
                              selected: _viewMode ==
                                  AdminSkExplorerViewMode.documents,
                              onTap: () => setState(
                                () => _viewMode =
                                    AdminSkExplorerViewMode.documents,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if ((_viewMode == AdminSkExplorerViewMode.users &&
                          groups.isEmpty) ||
                      (_viewMode == AdminSkExplorerViewMode.documents &&
                          records.isEmpty))
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ExplorerEmptyState(
                        icon: Icons.folder_off_outlined,
                        title: keyword.isEmpty
                            ? 'Belum ada data yang sesuai'
                            : 'Data tidak ditemukan',
                        message: keyword.isEmpty
                            ? 'Belum ada SK pada kategori ini.'
                            : 'Ubah kata pencarian yang digunakan.',
                      ),
                    )
                  else if (_viewMode == AdminSkExplorerViewMode.users)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            if (index.isOdd) {
                              return const SizedBox(height: 10);
                            }
                            final _EmployeeSkGroup group = groups[index ~/ 2];
                            return _EmployeeGroupCard(
                              group: group,
                              onTap: () => _openEmployee(group.records.first),
                            );
                          },
                          childCount: groups.length * 2 - 1,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            if (index.isOdd) {
                              return const SizedBox(height: 10);
                            }
                            final AdminSkExplorerRecord record =
                                records[index ~/ 2];
                            return _DocumentCard(
                              record: record,
                              onTap: () => _openEmployee(record),
                            );
                          },
                          childCount: records.length * 2 - 1,
                        ),
                      ),
                    ),
                ],
              );
                },
              ),
            ),
          ),
          ],
        ),
        bottomNavigationBar: const SiapPageBottomNavigationBar(
          selectedIndex: 2,
          isAdmin: true,
          showBackgroundLayer: true,
        ),
      ),
    );
  }

  List<_EmployeeSkGroup> _groupByEmployee(
    List<AdminSkExplorerRecord> records,
  ) {
    final Map<String, _EmployeeSkGroup> groups =
        <String, _EmployeeSkGroup>{};

    for (final AdminSkExplorerRecord record in records) {
      final String ownerId = record.sk.ownerId.trim();
      if (ownerId.isEmpty) continue;
      final _EmployeeSkGroup group = groups.putIfAbsent(
        ownerId,
        () => _EmployeeSkGroup(
          ownerId: ownerId,
          employee: record.employee,
        ),
      );
      group.records.add(record);
    }

    final List<_EmployeeSkGroup> result = groups.values.toList()
      ..sort(
        (_EmployeeSkGroup a, _EmployeeSkGroup b) =>
            a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                ),
      );
    return result;
  }
}

class _EmployeeSkGroup {
  final String ownerId;
  final PegawaiDirectoryItem? employee;
  final List<AdminSkExplorerRecord> records =
      <AdminSkExplorerRecord>[];

  _EmployeeSkGroup({
    required this.ownerId,
    required this.employee,
  });

  String get displayName {
    final String value = employee?.namaLengkap.trim() ?? '';
    return value.isEmpty ? 'Pegawai tidak tersedia' : value;
  }

  String get nip {
    final String value = employee?.nip.trim() ?? '';
    return value.isEmpty ? '-' : value;
  }
}

class _ExplorerModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ExplorerModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFDDEFD4)
          : const Color(0xFFFFFCF5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF9CC58E)
                  : const Color(0x55C9C1B1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: selected
                    ? const Color(0xFF2A7A30)
                    : const Color(0xFF756F65),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xFF2A7A30)
                      : const Color(0xFF4E4A43),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeGroupCard extends StatelessWidget {
  final _EmployeeSkGroup group;
  final VoidCallback onTap;

  const _EmployeeGroupCard({
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Set<SiapSkReviewStatus> statuses = group.records
        .map(
          (AdminSkExplorerRecord record) =>
              normalizeSiapSkStatus(record.sk.status),
        )
        .toSet();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          decoration: AppTheme.glassSurfaceDecoration(radius: 15),
          child: Row(
            children: <Widget>[
              PegawaiAvatar(
                storedPhoto: group.employee?.fotoProfil ?? '',
                radius: 25,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      group.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF191919),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIP: ${group.nip}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: _AdminSkExplorerPageState._muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: <Widget>[
                        _ExplorerTag(
                          label: '${group.records.length} SK',
                          icon: Icons.description_outlined,
                        ),
                        for (final SiapSkReviewStatus status in statuses)
                          _ExplorerStatusBadge(status: status),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6E675C),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final AdminSkExplorerRecord record;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final EmployeeSkItem item = record.sk;
    final String name = record.employee?.namaLengkap.trim().isNotEmpty == true
        ? record.employee!.namaLengkap.trim()
        : 'Pegawai tidak tersedia';
    final String nip = record.employee?.nip.trim().isNotEmpty == true
        ? record.employee!.nip.trim()
        : '-';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          decoration: AppTheme.glassSurfaceDecoration(radius: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PegawaiAvatar(
                storedPhoto: record.employee?.fotoProfil ?? '',
                radius: 23,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.jenisLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF191919),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.nomor.trim().isEmpty
                          ? 'Nomor SK belum tersedia'
                          : item.nomor.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _AdminSkExplorerPageState._muted,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '$name • NIP: $nip',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4E4A43),
                      ),
                    ),
                    if (item.tanggal != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(item.tanggal!),
                        style: const TextStyle(
                          fontSize: 10,
                          color: _AdminSkExplorerPageState._muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _ExplorerStatusBadge(
                      status: normalizeSiapSkStatus(item.status),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6E675C),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _ExplorerTag extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ExplorerTag({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFD7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: const Color(0xFF8A5A00)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A5A00),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplorerStatusBadge extends StatelessWidget {
  final SiapSkReviewStatus status;

  const _ExplorerStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;

    switch (status) {
      case SiapSkReviewStatus.pending:
        background = const Color(0xFFFFEAC0);
        foreground = const Color(0xFF8A5A00);
        break;
      case SiapSkReviewStatus.approved:
        background = const Color(0xFFD7EED0);
        foreground = const Color(0xFF2A7A30);
        break;
      case SiapSkReviewStatus.rejected:
        background = const Color(0xFFFFDAD6);
        foreground = const Color(0xFFB3261E);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        siapSkStatusLabel(siapSkStatusValue(status)),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _ExplorerEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ExplorerEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 46, color: const Color(0xFF9D6A18)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF292929),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF756F65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
