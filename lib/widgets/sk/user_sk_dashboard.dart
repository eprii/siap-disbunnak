import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../config/sk_definitions.dart';
import '../../models/profilepegawai_model.dart';
import '../../models/users_model.dart';
import '../../pages/kelola_data/form_sk/form_sk_angka_kredit_page.dart';
import '../../pages/kelola_data/form_sk/form_sk_cpns_page.dart';
import '../../pages/kelola_data/form_sk/form_sk_cuti_page.dart';
import '../../pages/kelola_data/form_sk/form_sk_diklat_page.dart';
import '../../pages/kelola_data/form_sk/form_sk_jabatan_page.dart';
import '../../pages/kelola_data/form_sk/form_sk_kgb_page.dart';
import '../../pages/kelola_data/form_sk/form_sk_pangkat_page.dart';
import '../../pages/kelola_data/form_sk/form_sk_pendidikan_page.dart';
import '../../pages/kelola_data/form_sk/form_sk_penghargaan_page.dart';
import '../../pages/kelola_data/form_sk/form_sk_penugasan_tim_page.dart';
import '../../pages/kelola_data/form_sk/form_sk_pns_page.dart';
import '../../pages/pratinjau_dokumen/pratinjau_pdf_page.dart';
import '../../services/employee_sk_file_service.dart';
import '../../services/employee_sk_management_service.dart';
import '../../services/sk_comment_service.dart';
import '../feedback/siap_top_notification.dart';
import '../navigation/bottom_navigation_bar.dart';

class UserSkDashboard extends StatefulWidget {
  final UsersModel user;
  final ProfilePegawaiModel profile;

  const UserSkDashboard({
    super.key,
    required this.user,
    required this.profile,
  });

  @override
  State<UserSkDashboard> createState() => _UserSkDashboardState();
}

class _UserSkDashboardState extends State<UserSkDashboard> {
  static const Color _accent = Color(0xFF9D6A18);
  static const Color _muted = Color(0xFF756F65);

  late Future<List<EmployeeSkItem>> _future;
  final Set<String> _busyFiles = <String>{};
  final Set<String> _busyDeletes = <String>{};
  final Set<String> _dismissedRejected = <String>{};

  @override
  void initState() {
    super.initState();
    _future = _load();
    SiapNavigationController.selectedIndex.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    SiapNavigationController.selectedIndex.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (!mounted || SiapNavigationController.selectedIndex.value != 2) {
      return;
    }

    setState(() {
      _future = _load();
    });
  }

  Future<List<EmployeeSkItem>> _load() {
    return SkCommentService.instance.loadEmployeeSk(widget.user.uid);
  }

  Future<void> _refresh() async {
    final Future<List<EmployeeSkItem>> next = _load();
    setState(() => _future = next);
    await next;
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

  Future<void> _preview(EmployeeSkItem item) async {
    if (item.filePath.trim().isEmpty ||
        _busyFiles.contains(item.commentKey)) {
      return;
    }

    setState(() => _busyFiles.add(item.commentKey));

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
            pemilik: widget.user.nama_lengkap,
            jabatan: widget.profile.jabatan_sekarang,
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
        setState(() => _busyFiles.remove(item.commentKey));
      }
    }
  }

  Future<void> _download(EmployeeSkItem item) async {
    if (item.filePath.trim().isEmpty ||
        _busyFiles.contains(item.commentKey)) {
      return;
    }

    setState(() => _busyFiles.add(item.commentKey));

    try {
      final String? path = await EmployeeSkFileService.instance
          .downloadFile(
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
        setState(() => _busyFiles.remove(item.commentKey));
      }
    }
  }

  Future<void> _delete(EmployeeSkItem item) async {
    if (_busyDeletes.contains(item.commentKey)) return;

    final SiapSkReviewStatus status = normalizeSiapSkStatus(item.status);
    if (status == SiapSkReviewStatus.approved) {
      await _showMessage(
        title: 'SK Tidak Dapat Dihapus',
        message: 'SK yang sudah disetujui hanya dapat dihapus oleh admin.',
        error: true,
      );
      return;
    }

    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFFCF5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              title: const Text(
                'Hapus Dokumen SK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                'Hapus ${item.jenisLabel} dari arsip Anda? '
                'Tindakan ini tidak dapat dibatalkan.',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('BATAL'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB3261E),
                  ),
                  child: const Text('HAPUS'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() => _busyDeletes.add(item.commentKey));

    try {
      await EmployeeSkManagementService.instance.deleteOwnedSk(item);
      _dismissedRejected.remove(item.commentKey);
      await _refresh();
      await _showMessage(
        title: 'SK Dihapus',
        message: '${item.jenisLabel} berhasil dihapus.',
      );
    } on EmployeeSkManagementException catch (error) {
      await _showMessage(
        title: 'SK Gagal Dihapus',
        message: error.message,
        error: true,
      );
    } catch (error) {
      await _showMessage(
        title: 'SK Gagal Dihapus',
        message: 'Gagal menghapus SK: $error',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _busyDeletes.remove(item.commentKey));
      }
    }
  }

  Future<void> _openReupload(EmployeeSkItem item) async {
    final Widget? page = _formForCollection(item.collection);
    if (page == null) {
      await _showMessage(
        title: 'Form Tidak Tersedia',
        message: 'Form upload ulang untuk jenis SK ini belum tersedia.',
        error: true,
      );
      return;
    }

    SiapNavigationController.selectTab(1);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => page),
    );

    if (mounted) {
      await _refresh();
    }
  }

  Widget? _formForCollection(String collection) {
    switch (collection.trim()) {
      case 'sk_cpns':
        return const FormSkCpnsPage();
      case 'sk_pns':
        return const FormSkPnsPage();
      case 'sk_pangkat':
        return const FormSkPangkatPage();
      case 'sk_jabatan':
        return const FormSkJabatanPage();
      case 'sk_pendidikan':
        return const FormSkPendidikanPage();
      case 'sk_diklat':
        return const FormSkDiklatPage();
      case 'sk_penghargaan':
        return const FormSkPenghargaanPage();
      case 'sk_kgb':
        return const FormSkKgbPage();
      case 'sk_cuti':
        return const FormSkCutiPage();
      case 'sk_angka_kredit':
        return const FormSkAngkaKreditPage();
      case 'sk_penugasan_tim':
        return const FormSkPenugasanTimPage();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: AppTheme.glassSurfaceDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.folder_copy_outlined,
                size: 21,
                color: _accent,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Dokumen SK Saya',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191919),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<EmployeeSkItem>>(
            future: _future,
            builder: (
              BuildContext context,
              AsyncSnapshot<List<EmployeeSkItem>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: CircularProgressIndicator(color: _accent),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _InlineState(
                  icon: Icons.error_outline_rounded,
                  message: 'Gagal memuat daftar SK.',
                  actionLabel: 'COBA LAGI',
                  onAction: _refresh,
                );
              }

              final List<EmployeeSkItem> items =
                  snapshot.data ?? <EmployeeSkItem>[];

              if (items.isEmpty) {
                return const _InlineState(
                  icon: Icons.folder_open_rounded,
                  message: 'Belum ada dokumen SK yang di-upload.',
                );
              }

              final int pending = items
                  .where(
                    (EmployeeSkItem item) =>
                        normalizeSiapSkStatus(item.status) ==
                        SiapSkReviewStatus.pending,
                  )
                  .length;
              final int approved = items
                  .where(
                    (EmployeeSkItem item) =>
                        normalizeSiapSkStatus(item.status) ==
                        SiapSkReviewStatus.approved,
                  )
                  .length;
              final int rejected = items.length - pending - approved;

              return Column(
                children: <Widget>[
                  _SummaryRow(
                    total: items.length,
                    pending: pending,
                    approved: approved,
                    rejected: rejected,
                  ),
                  const SizedBox(height: 12),
                  for (final SkDefinition definition
                      in siapSkDefinitions) ...<Widget>[
                    if (items.any(
                      (EmployeeSkItem item) =>
                          item.collection == definition.collection,
                    ))
                      _SkGroup(
                        definition: definition,
                        items: items
                            .where(
                              (EmployeeSkItem item) =>
                                  item.collection == definition.collection,
                            )
                            .toList(),
                        busyFiles: _busyFiles,
                        busyDeletes: _busyDeletes,
                        dismissedRejected: _dismissedRejected,
                        onPreview: _preview,
                        onDownload: _download,
                        onDelete: _delete,
                        onReupload: _openReupload,
                        onDismissRejected: (EmployeeSkItem item) {
                          setState(() {
                            _dismissedRejected.add(item.commentKey);
                          });
                        },
                      ),
                  ],
                ],
              );
            },
          ),
        ],
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
          (String part) =>
              '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
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

class _SummaryRow extends StatelessWidget {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const _SummaryRow({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _SummaryChip(
            label: 'Total',
            value: total,
            background: const Color(0xFFFFEFD1),
            foreground: const Color(0xFF8A5A00),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _SummaryChip(
            label: 'Belum',
            value: pending,
            background: const Color(0xFFFFEAC0),
            foreground: const Color(0xFF8A5A00),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _SummaryChip(
            label: 'Disetujui',
            value: approved,
            background: const Color(0xFFD7EED0),
            foreground: const Color(0xFF2A7A30),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _SummaryChip(
            label: 'Ditolak',
            value: rejected,
            background: const Color(0xFFFFDAD6),
            foreground: const Color(0xFFB3261E),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final Color background;
  final Color foreground;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkGroup extends StatelessWidget {
  final SkDefinition definition;
  final List<EmployeeSkItem> items;
  final Set<String> busyFiles;
  final Set<String> busyDeletes;
  final Set<String> dismissedRejected;
  final ValueChanged<EmployeeSkItem> onPreview;
  final ValueChanged<EmployeeSkItem> onDownload;
  final ValueChanged<EmployeeSkItem> onDelete;
  final ValueChanged<EmployeeSkItem> onReupload;
  final ValueChanged<EmployeeSkItem> onDismissRejected;

  const _SkGroup({
    required this.definition,
    required this.items,
    required this.busyFiles,
    required this.busyDeletes,
    required this.dismissedRejected,
    required this.onPreview,
    required this.onDownload,
    required this.onDelete,
    required this.onReupload,
    required this.onDismissRejected,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: const Color(0x1A9D6A18),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: const Color(0xDFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9D5CC)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          leading: const Icon(
            Icons.description_outlined,
            size: 21,
            color: Color(0xFF9D6A18),
          ),
          title: Text(
            definition.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFD1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              items.length.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A5A00),
              ),
            ),
          ),
          children: <Widget>[
            for (int index = 0; index < items.length; index++) ...<Widget>[
              _SkItemCard(
                item: items[index],
                fileBusy: busyFiles.contains(items[index].commentKey),
                deleteBusy: busyDeletes.contains(items[index].commentKey),
                rejectedDismissed:
                    dismissedRejected.contains(items[index].commentKey),
                onPreview: () => onPreview(items[index]),
                onDownload: () => onDownload(items[index]),
                onDelete: () => onDelete(items[index]),
                onReupload: () => onReupload(items[index]),
                onDismissRejected: () =>
                    onDismissRejected(items[index]),
              ),
              if (index != items.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkItemCard extends StatelessWidget {
  final EmployeeSkItem item;
  final bool fileBusy;
  final bool deleteBusy;
  final bool rejectedDismissed;
  final VoidCallback onPreview;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onReupload;
  final VoidCallback onDismissRejected;

  const _SkItemCard({
    required this.item,
    required this.fileBusy,
    required this.deleteBusy,
    required this.rejectedDismissed,
    required this.onPreview,
    required this.onDownload,
    required this.onDelete,
    required this.onReupload,
    required this.onDismissRejected,
  });

  @override
  Widget build(BuildContext context) {
    final SiapSkReviewStatus status = normalizeSiapSkStatus(item.status);
    final bool canDelete = status != SiapSkReviewStatus.approved;
    final bool hasFile = item.filePath.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE4DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.nomor.trim().isEmpty ? '-' : item.nomor.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.tanggal == null
                          ? '-'
                          : _UserSkDashboardState._formatDate(item.tanggal!),
                      style: const TextStyle(
                        fontSize: 10,
                        color: _UserSkDashboardState._muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.fileName.trim().isEmpty
                          ? 'File belum tersedia'
                          : item.fileName.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF9D6A18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: status),
            ],
          ),
          if (status == SiapSkReviewStatus.rejected &&
              !rejectedDismissed) ...<Widget>[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.fromLTRB(9, 8, 5, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8E5),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0x66B3261E)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Color(0xFFB3261E),
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Dokumen ini ditolak admin. Periksa kembali dan '
                      'upload ulang dokumen yang benar bila diperlukan.',
                      style: TextStyle(
                        fontSize: 9.5,
                        height: 1.35,
                        color: Color(0xFF7C241E),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup pemberitahuan',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: onDismissRejected,
                    icon: const Icon(Icons.close_rounded, size: 17),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 9),
          Row(
            children: <Widget>[
              if (fileBusy || deleteBusy)
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: Padding(
                    padding: EdgeInsets.all(7),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _UserSkDashboardState._accent,
                    ),
                  ),
                )
              else ...<Widget>[
                _SmallAction(
                  label: 'Lihat',
                  icon: Icons.visibility_outlined,
                  onTap: hasFile ? onPreview : null,
                ),
                const SizedBox(width: 6),
                _SmallAction(
                  label: 'Download',
                  icon: Icons.download_outlined,
                  onTap: hasFile ? onDownload : null,
                ),
                if (status == SiapSkReviewStatus.rejected) ...<Widget>[
                  const SizedBox(width: 6),
                  _SmallAction(
                    label: 'Upload ulang',
                    icon: Icons.upload_file_outlined,
                    onTap: onReupload,
                  ),
                ],
                const Spacer(),
                Tooltip(
                  message: canDelete
                      ? 'Hapus dokumen'
                      : 'SK yang disetujui tidak dapat dihapus',
                  child: IconButton(
                    onPressed: canDelete ? onDelete : null,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: Icon(
                      canDelete
                          ? Icons.delete_outline_rounded
                          : Icons.lock_outline_rounded,
                      size: 19,
                      color: canDelete
                          ? const Color(0xFFB3261E)
                          : const Color(0xFF9A958C),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _SmallAction({
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
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

class _StatusBadge extends StatelessWidget {
  final SiapSkReviewStatus status;

  const _StatusBadge({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        siapSkStatusLabel(siapSkStatusValue(status)),
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _InlineState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InlineState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
          Icon(icon, size: 28, color: const Color(0xFF9D6A18)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF756F65)),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
          ],
        ),
      ),
    );
  }
}
