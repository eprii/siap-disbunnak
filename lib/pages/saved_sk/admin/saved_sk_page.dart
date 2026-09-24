import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_theme.dart';
import '../../../config/sk_definitions.dart';
import '../../../pages/pegawai/detail_pegawai_page.dart';
import '../../../pages/pratinjau_dokumen/pratinjau_pdf_page.dart';
import '../../../services/admin_sk_review_service.dart';
import '../../../services/employee_sk_file_service.dart';
import '../../../services/pegawai_directory_service.dart';
import '../../../services/saved_sk_service.dart';
import '../../../services/saved_user_service.dart';
import '../../../services/sk_comment_service.dart';
import '../../../widgets/feedback/siap_top_notification.dart';
import '../../../widgets/profile/pegawai_avatar.dart';

enum _SavedDataFilter {
  all,
  withSk,
  userOnly,
}

class SavedSKPage extends StatefulWidget {
  const SavedSKPage({super.key});

  @override
  State<SavedSKPage> createState() => _SavedSKPageState();
}

class _SavedSKPageState extends State<SavedSKPage> {
  static const Color _accent = Color(0xFF9D6A18);
  static const Color _muted = Color(0xFF756F65);

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _busyFiles = <String>{};
  final Set<String> _busyStatuses = <String>{};
  final Set<String> _busySavedUsers = <String>{};
  final Set<String> _expandedOwnerIds = <String>{};

  late Stream<List<SavedSkRecord>> _savedSkStream;
  late Stream<List<SavedUserRecord>> _savedUserStream;
  _SavedDataFilter _selectedFilter = _SavedDataFilter.all;

  @override
  void initState() {
    super.initState();
    _reloadStreams();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadStreams() {
    _savedSkStream = SavedSkService.instance.watchSavedSk();
    _savedUserStream = SavedUserService.instance.watchSavedUsers();
  }

  Future<void> _refresh() async {
    setState(_reloadStreams);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  Future<void> _showMessage({
    required String title,
    required String message,
    bool error = false,
  }) async {
    if (!mounted) return;

    await showSiapTopNotification(
      context: context,
      title: title,
      message: message,
      type: error
          ? SiapNotificationType.error
          : SiapNotificationType.success,
    );
  }

  void _openEmployee(_SavedEmployeeGroup group) {
    final String ownerId = group.ownerId.trim();
    if (ownerId.isEmpty) return;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DetailPegawaiPage(employeeUid: ownerId),
      ),
    );
  }

  void _toggleExpanded(String ownerId) {
    setState(() {
      if (!_expandedOwnerIds.add(ownerId)) {
        _expandedOwnerIds.remove(ownerId);
      }
    });
  }

  Future<void> _preview(SavedSkRecord record) async {
    final EmployeeSkItem? item = record.sk;
    if (item == null ||
        item.filePath.trim().isEmpty ||
        _busyFiles.contains(record.bookmarkId)) {
      return;
    }

    setState(() => _busyFiles.add(record.bookmarkId));

    try {
      final pdfBytes = await EmployeeSkFileService.instance
          .preparePreviewData(
        storagePath: item.filePath,
      );

      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PratinjauPdfPage(
            fileBytes: pdfBytes,
            fileName: item.fileName.trim().isEmpty
                ? '${item.jenisLabel}.pdf'
                : item.fileName.trim(),
            jenisSk: item.jenisLabel,
            nomorDokumen: item.nomor,
            tanggalDokumen: item.tanggal,
            pemilik: record.employee?.namaLengkap ??
                _firstString(
                  item.rawData,
                  const <String>['nama_pegawai'],
                ),
            jabatan: record.employee?.jabatanSekarang ??
                _firstString(
                  item.rawData,
                  const <String>['jabatan_saat_upload'],
                ),
            details: _previewDetails(item.rawData),
          ),
        ),
      );
    } on EmployeeSkFileException catch (error) {
      await _showMessage(
        title: 'Dokumen Tidak Dapat Dibuka',
        message: error.message,
        error: true,
      );
    } catch (error) {
      await _showMessage(
        title: 'Dokumen Tidak Dapat Dibuka',
        message: 'Gagal membuka dokumen: $error',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _busyFiles.remove(record.bookmarkId));
      }
    }
  }

  Future<void> _download(SavedSkRecord record) async {
    final EmployeeSkItem? item = record.sk;
    if (item == null ||
        item.filePath.trim().isEmpty ||
        _busyFiles.contains(record.bookmarkId)) {
      return;
    }

    setState(() => _busyFiles.add(record.bookmarkId));

    try {
      final String? path = await EmployeeSkFileService.instance.downloadFile(
        storagePath: item.filePath,
        fileName: item.fileName.trim().isEmpty
            ? '${item.jenisLabel}.pdf'
            : item.fileName.trim(),
      );

      if (path != null) {
        await _showMessage(
          title: 'Dokumen Disimpan',
          message: 'Dokumen berhasil disimpan ke perangkat.',
        );
      }
    } on EmployeeSkFileException catch (error) {
      await _showMessage(
        title: 'Download Gagal',
        message: error.message,
        error: true,
      );
    } catch (error) {
      await _showMessage(
        title: 'Download Gagal',
        message: 'Gagal mengunduh dokumen: $error',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _busyFiles.remove(record.bookmarkId));
      }
    }
  }

  Future<void> _toggleSavedUser(_SavedEmployeeGroup group) async {
    final String ownerId = group.ownerId.trim();
    if (ownerId.isEmpty || _busySavedUsers.contains(ownerId)) return;

    setState(() => _busySavedUsers.add(ownerId));

    try {
      if (group.savedUser == null) {
        await SavedUserService.instance.saveUser(ownerId);
        await _showMessage(
          title: 'User Disimpan',
          message: '${group.displayName} ditambahkan ke Data Tersimpan.',
        );
      } else {
        await SavedUserService.instance.removeBookmark(
          group.savedUser!.bookmarkId,
        );
        await _showMessage(
          title: 'User Dihapus dari Tersimpan',
          message: '${group.displayName} tidak lagi disimpan sebagai user.',
        );
      }
    } on SavedUserException catch (error) {
      await _showMessage(
        title: 'Bookmark User Gagal Diubah',
        message: error.message,
        error: true,
      );
    } catch (error) {
      await _showMessage(
        title: 'Bookmark User Gagal Diubah',
        message: 'Gagal memperbarui bookmark user: $error',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _busySavedUsers.remove(ownerId));
      }
    }
  }

  Future<void> _changeStatus(SavedSkRecord record) async {
    final EmployeeSkItem? item = record.sk;
    if (item == null || _busyStatuses.contains(record.bookmarkId)) return;

    final SiapSkReviewStatus currentStatus =
        normalizeSiapSkStatus(item.status);
    final SiapSkReviewStatus? selected =
        await showModalBottomSheet<SiapSkReviewStatus>(
      context: context,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFFCF5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2CCC0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ganti Status SK',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.jenisLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 12),
              for (final SiapSkReviewStatus status
                  in SiapSkReviewStatus.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _SavedStatusBadge(status: status),
                  title: Text(
                    siapSkStatusLabel(siapSkStatusValue(status)),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: status == currentStatus
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2A7A30),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(bottomSheetContext, status),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == currentStatus || !mounted) return;

    setState(() => _busyStatuses.add(record.bookmarkId));

    try {
      await AdminSkReviewService.instance.updateStatus(
        collection: item.collection,
        documentId: item.documentId,
        status: selected,
      );

      if (!mounted) return;
      setState(_reloadStreams);

      await _showMessage(
        title: 'Status SK Diperbarui',
        message:
            '${item.jenisLabel} diubah menjadi ${siapSkStatusLabel(siapSkStatusValue(selected))}.',
      );
    } on AdminSkReviewException catch (error) {
      await _showMessage(
        title: 'Status SK Gagal Diubah',
        message: error.message,
        error: true,
      );
    } catch (error) {
      await _showMessage(
        title: 'Status SK Gagal Diubah',
        message: 'Gagal memperbarui status: $error',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _busyStatuses.remove(record.bookmarkId));
      }
    }
  }

  List<_SavedEmployeeGroup> _buildGroups({
    required List<SavedSkRecord> savedSk,
    required List<SavedUserRecord> savedUsers,
  }) {
    final Map<String, _SavedEmployeeGroup> groups =
        <String, _SavedEmployeeGroup>{};

    for (final SavedUserRecord record in savedUsers) {
      final String ownerId = record.ownerId.trim();
      if (ownerId.isEmpty) continue;

      final _SavedEmployeeGroup group = groups.putIfAbsent(
        ownerId,
        () => _SavedEmployeeGroup(ownerId: ownerId),
      );
      group.savedUser = record;
      group.employee ??= record.employee;
      group.updateLatest(record.savedAt);
    }

    for (final SavedSkRecord record in savedSk) {
      final String ownerId = record.ownerId.trim();
      if (ownerId.isEmpty) continue;

      final _SavedEmployeeGroup group = groups.putIfAbsent(
        ownerId,
        () => _SavedEmployeeGroup(ownerId: ownerId),
      );
      group.savedSk.add(record);
      group.employee ??= record.employee;
      group.updateLatest(record.savedAt);
    }

    final List<_SavedEmployeeGroup> result = groups.values.toList();

    for (final _SavedEmployeeGroup group in result) {
      group.savedSk.sort((SavedSkRecord a, SavedSkRecord b) {
        final DateTime aDate =
            a.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate =
            b.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    }

    result.sort(
      (_SavedEmployeeGroup a, _SavedEmployeeGroup b) =>
          a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              ),
    );

    return result;
  }

  List<_SavedEmployeeGroup> _filterGroups(
    List<_SavedEmployeeGroup> groups,
  ) {
    final String keyword = _searchController.text.trim().toLowerCase();

    return groups.where((_SavedEmployeeGroup group) {
      final bool matchesFilter;
      switch (_selectedFilter) {
        case _SavedDataFilter.withSk:
          matchesFilter = group.savedSk.isNotEmpty;
          break;
        case _SavedDataFilter.userOnly:
          matchesFilter = group.savedUser != null && group.savedSk.isEmpty;
          break;
        case _SavedDataFilter.all:
          matchesFilter = true;
          break;
      }

      if (!matchesFilter) return false;
      if (keyword.isEmpty) return true;

      return group.displayName.toLowerCase().contains(keyword) ||
          group.nip.toLowerCase().contains(keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.viewPaddingOf(context).top;

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
        body: Stack(
          children: <Widget>[
            RefreshIndicator(
              color: _accent,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        28,
                        topPadding + 24,
                        28,
                        12,
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Data Tersimpan',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Pegawai yang disimpan langsung dan dokumen SK '
                            'yang dibookmark oleh admin.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Color(0xFF6F6F6F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                      child: Container(
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
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau NIP',
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
                                      setState(() {});
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
                                color: _accent,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 48,
                      child: ListView(
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.fromLTRB(26, 3, 26, 4),
                        scrollDirection: Axis.horizontal,
                        children: <Widget>[
                          _SavedFilterChip(
                            label: 'Semua',
                            selected:
                                _selectedFilter == _SavedDataFilter.all,
                            onTap: () => setState(
                              () => _selectedFilter = _SavedDataFilter.all,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _SavedFilterChip(
                            label: 'Ada SK Tersimpan',
                            selected:
                                _selectedFilter == _SavedDataFilter.withSk,
                            onTap: () => setState(
                              () => _selectedFilter =
                                  _SavedDataFilter.withSk,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _SavedFilterChip(
                            label: 'Hanya User Tersimpan',
                            selected:
                                _selectedFilter ==
                                    _SavedDataFilter.userOnly,
                            onTap: () => setState(
                              () => _selectedFilter =
                                  _SavedDataFilter.userOnly,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  StreamBuilder<List<SavedUserRecord>>(
                    stream: _savedUserStream,
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<List<SavedUserRecord>> userSnapshot,
                    ) {
                      return StreamBuilder<List<SavedSkRecord>>(
                        stream: _savedSkStream,
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<List<SavedSkRecord>> skSnapshot,
                        ) {
                          final bool waiting =
                              (userSnapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      !userSnapshot.hasData) ||
                                  (skSnapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      !skSnapshot.hasData);

                          if (waiting) {
                            return const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _accent,
                                ),
                              ),
                            );
                          }

                          if (userSnapshot.hasError || skSnapshot.hasError) {
                            final Object? error =
                                userSnapshot.error ?? skSnapshot.error;
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyState(
                                icon: Icons.error_outline_rounded,
                                title: 'Data tersimpan gagal dimuat',
                                message: error.toString(),
                              ),
                            );
                          }

                          final List<_SavedEmployeeGroup> groups =
                              _buildGroups(
                            savedSk:
                                skSnapshot.data ?? <SavedSkRecord>[],
                            savedUsers:
                                userSnapshot.data ?? <SavedUserRecord>[],
                          );
                          final List<_SavedEmployeeGroup> filteredGroups =
                              _filterGroups(groups);

                          if (filteredGroups.isEmpty) {
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyState(
                                icon: Icons.bookmarks_outlined,
                                title: groups.isEmpty
                                    ? 'Belum ada data tersimpan'
                                    : 'Data tidak ditemukan',
                                message: groups.isEmpty
                                    ? 'Simpan user dari Home atau simpan SK '
                                        'dari halaman Detail Pegawai.'
                                    : 'Ubah pencarian atau filter yang '
                                        'digunakan.',
                              ),
                            );
                          }

                          return SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(22, 6, 22, 130),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int index) {
                                  if (index.isOdd) {
                                    return const SizedBox(height: 18);
                                  }

                                  final _SavedEmployeeGroup group =
                                      filteredGroups[index ~/ 2];
                                  return _SavedEmployeeCard(
                                    group: group,
                                    expanded: _expandedOwnerIds.contains(
                                      group.ownerId,
                                    ),
                                    savedUserBusy: _busySavedUsers.contains(
                                      group.ownerId,
                                    ),
                                    busyFiles: _busyFiles,
                                    busyStatuses: _busyStatuses,
                                    onOpenEmployee: () =>
                                        _openEmployee(group),
                                    onToggleExpanded: () =>
                                        _toggleExpanded(group.ownerId),
                                    onToggleSavedUser: () =>
                                        _toggleSavedUser(group),
                                    onPreview: _preview,
                                    onDownload: _download,
                                    onStatus: _changeStatus,
                                  );
                                },
                                childCount:
                                    filteredGroups.length * 2 - 1,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
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
          ],
        ),
      ),
    );
  }

  List<PratinjauPdfDetail> _previewDetails(
    Map<String, dynamic> rawData,
  ) {
    const Set<String> hidden = <String>{
      'owner_id',
      'file_pdf',
      'file_path',
      'file_sk',
      'created_at',
      'updated_at',
      'status',
      'status_sk',
      'status_verifikasi',
      'reviewed_by',
      'reviewed_at',
    };

    final List<PratinjauPdfDetail> result = <PratinjauPdfDetail>[];
    final List<MapEntry<String, dynamic>> entries = rawData.entries
        .where(
          (MapEntry<String, dynamic> entry) =>
              !hidden.contains(entry.key) && entry.value != null,
        )
        .toList()
      ..sort(
        (MapEntry<String, dynamic> a, MapEntry<String, dynamic> b) =>
            a.key.compareTo(b.key),
      );

    for (final MapEntry<String, dynamic> entry in entries) {
      final String value = _previewValue(entry.value);
      if (value.isEmpty || value == '-') continue;
      result.add(
        PratinjauPdfDetail(
          label: _fieldLabel(entry.key),
          value: value,
        ),
      );
    }

    return result;
  }

  static String _previewValue(dynamic value) {
    if (value == null) return '-';
    if (value is Timestamp) return _formatDate(value.toDate());
    if (value is DateTime) return _formatDate(value);
    if (value is bool) return value ? 'Ya' : 'Tidak';
    if (value is num) return value.toString();
    if (value is List) {
      return value
          .map((dynamic item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .join(', ');
    }
    if (value is Map) return '-';
    return value.toString().trim();
  }

  static String _fieldLabel(String key) {
    return key
        .split('_')
        .where((String part) => part.isNotEmpty)
        .map(
          (String part) => '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  static String _firstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final String value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '-';
  }

  static String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SavedEmployeeGroup {
  final String ownerId;
  final List<SavedSkRecord> savedSk = <SavedSkRecord>[];
  PegawaiDirectoryItem? employee;
  SavedUserRecord? savedUser;
  DateTime? latestSavedAt;

  _SavedEmployeeGroup({required this.ownerId});

  void updateLatest(DateTime? date) {
    if (date == null) return;
    if (latestSavedAt == null || date.isAfter(latestSavedAt!)) {
      latestSavedAt = date;
    }
  }

  String get displayName {
    final String employeeName = employee?.namaLengkap.trim() ?? '';
    if (employeeName.isNotEmpty) return employeeName;

    for (final SavedSkRecord record in savedSk) {
      final EmployeeSkItem? item = record.sk;
      if (item == null) continue;
      final String name =
          item.rawData['nama_pegawai']?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
    }

    return 'Pegawai tidak tersedia';
  }

  String get nip {
    final String value = employee?.nip.trim() ?? '';
    return value.isEmpty ? '-' : value;
  }
}

class _SavedEmployeeCard extends StatelessWidget {
  static const double _savedSkRowHeight = 150;

  final _SavedEmployeeGroup group;
  final bool expanded;
  final bool savedUserBusy;
  final Set<String> busyFiles;
  final Set<String> busyStatuses;
  final VoidCallback onOpenEmployee;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToggleSavedUser;
  final ValueChanged<SavedSkRecord> onPreview;
  final ValueChanged<SavedSkRecord> onDownload;
  final ValueChanged<SavedSkRecord> onStatus;

  const _SavedEmployeeCard({
    required this.group,
    required this.expanded,
    required this.savedUserBusy,
    required this.busyFiles,
    required this.busyStatuses,
    required this.onOpenEmployee,
    required this.onToggleExpanded,
    required this.onToggleSavedUser,
    required this.onPreview,
    required this.onDownload,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final int skCount = group.savedSk.length;
    final int visibleRows = skCount > 3 ? 3 : skCount;

    return Container(
      decoration: AppTheme.glassSurfaceDecoration(radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 10),
            child: Row(
              children: <Widget>[
                PegawaiAvatar(
                  storedPhoto: group.employee?.fotoProfil ?? '',
                  radius: 26,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF191919),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIP: ${group.nip}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: _SavedSKPageState._muted,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: <Widget>[
                          _SavedTag(
                            icon: Icons.description_outlined,
                            label: '$skCount SK tersimpan',
                          ),
                          if (group.savedUser != null)
                            const _SavedTag(
                              icon: Icons.bookmark_rounded,
                              label: 'User tersimpan',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 8, 11),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _SavedPrimaryAction(
                    label: 'Buka Profil',
                    icon: Icons.person_outline_rounded,
                    onTap: onOpenEmployee,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  flex: 2,
                  child: _SavedPrimaryAction(
                    label: expanded
                        ? 'Sembunyikan SK'
                        : 'Lihat SK Tersimpan',
                    icon: expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    onTap: skCount == 0 ? null : onToggleExpanded,
                  ),
                ),
                const SizedBox(width: 3),
                if (savedUserBusy)
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _SavedSKPageState._accent,
                      ),
                    ),
                  )
                else
                  IconButton(
                    tooltip: group.savedUser == null
                        ? 'Simpan user'
                        : 'Hapus user tersimpan',
                    onPressed: onToggleSavedUser,
                    icon: Icon(
                      group.savedUser == null
                          ? Icons.bookmark_border_rounded
                          : Icons.bookmark_rounded,
                      color: const Color(0xFF9D6A18),
                      size: 23,
                    ),
                  ),
              ],
            ),
          ),
          if (expanded && skCount > 0) ...<Widget>[
            const Divider(height: 1, color: Color(0x55C9C1B1)),
            SizedBox(
              height: visibleRows * _savedSkRowHeight,
              child: ListView.separated(
                primary: false,
                padding: EdgeInsets.zero,
                physics: skCount > 3
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: skCount,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: Color(0x33C9C1B1),
                ),
                itemBuilder: (BuildContext context, int index) {
                  final SavedSkRecord record = group.savedSk[index];
                  return SizedBox(
                    height: _savedSkRowHeight - 1,
                    child: _SavedSkRow(
                      record: record,
                      fileBusy: busyFiles.contains(record.bookmarkId),
                      statusBusy: busyStatuses.contains(record.bookmarkId),
                      onPreview: () => onPreview(record),
                      onDownload: () => onDownload(record),
                      onStatus: () => onStatus(record),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SavedPrimaryAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _SavedPrimaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null
          ? const Color(0xFFF1EEE8)
          : const Color(0xFFFFEFD7),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 17,
                color: onTap == null
                    ? const Color(0xFF9A958C)
                    : const Color(0xFF8A5A00),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: onTap == null
                        ? const Color(0xFF9A958C)
                        : const Color(0xFF8A5A00),
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

class _SavedSkRow extends StatelessWidget {
  final SavedSkRecord record;
  final bool fileBusy;
  final bool statusBusy;
  final VoidCallback onPreview;
  final VoidCallback onDownload;
  final VoidCallback onStatus;

  const _SavedSkRow({
    required this.record,
    required this.fileBusy,
    required this.statusBusy,
    required this.onPreview,
    required this.onDownload,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final EmployeeSkItem? item = record.sk;
    final bool available = item != null;
    final bool hasFile = item != null && item.filePath.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFD7),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: Color(0xFF9D6A18),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      available
                          ? item.jenisLabel
                          : siapSkLabelForCollection(record.skCollection),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF191919),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item != null && item.nomor.trim().isNotEmpty
                          ? item.nomor.trim()
                          : 'Dokumen asli tidak tersedia',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _SavedSKPageState._muted,
                      ),
                    ),
                    if (item != null && item.tanggal != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        _SavedSKPageState._formatDate(item.tanggal!),
                        style: const TextStyle(
                          fontSize: 9,
                          color: _SavedSKPageState._muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (available)
                _SavedStatusBadge(
                  status: normalizeSiapSkStatus(item.status),
                )
              else
                const Icon(
                  Icons.link_off_rounded,
                  color: Color(0xFFB3261E),
                  size: 20,
                ),
            ],
          ),
          const Spacer(),
          if (fileBusy || statusBusy)
            const SizedBox(
              height: 32,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _SavedSKPageState._accent,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 6,
              children: <Widget>[
                _SavedAction(
                  label: 'Ganti Status',
                  icon: Icons.sync_alt_rounded,
                  onTap: available ? onStatus : null,
                ),
                _SavedAction(
                  label: 'Lihat',
                  icon: Icons.visibility_outlined,
                  onTap: hasFile ? onPreview : null,
                ),
                _SavedAction(
                  label: 'Download',
                  icon: Icons.download_outlined,
                  onTap: hasFile ? onDownload : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SavedAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _SavedAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null
          ? const Color(0xFFF1EEE8)
          : const Color(0xFFFFEFD7),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 15,
                color: onTap == null
                    ? const Color(0xFF9A958C)
                    : const Color(0xFF8A5A00),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: onTap == null
                      ? const Color(0xFF9A958C)
                      : const Color(0xFF8A5A00),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedStatusBadge extends StatelessWidget {
  final SiapSkReviewStatus status;

  const _SavedStatusBadge({required this.status});

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
      constraints: const BoxConstraints(maxWidth: 82),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        siapSkStatusLabel(siapSkStatusValue(status)),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _SavedTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SavedTag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFD7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: const Color(0xFF8A5A00)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A5A00),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SavedFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFF5A3A06)
                      : const Color(0xFF1E1E1E),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: const Color(0xFF9D6A18)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: _SavedSKPageState._muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
