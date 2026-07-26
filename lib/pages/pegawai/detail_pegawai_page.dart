import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/employee_sk_file_service.dart';
import '../../services/pegawai_directory_service.dart';
import '../../services/sk_comment_service.dart';
import '../../widgets/navigation/bottom_navigation_bar.dart';
import '../../widgets/profile/pegawai_avatar.dart';
import '../pratinjau_dokumen/pratinjau_pdf_page.dart';

class DetailPegawaiPage extends StatefulWidget {
  final String employeeUid;

  const DetailPegawaiPage({
    super.key,
    required this.employeeUid,
  });

  @override
  State<DetailPegawaiPage> createState() =>
      _DetailPegawaiPageState();
}

class _DetailPegawaiPageState extends State<DetailPegawaiPage> {
  static const Color _accent = Color(0xFF9D6A18);
  static const Color _card = Color(0xFFFFFCF5);
  static const Color _text = Color(0xFF191919);
  static const Color _muted = Color(0xFF756F65);

  final TextEditingController _commentController =
      TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late final Stream<PegawaiDirectoryItem?> _employeeStream;
  late Future<List<EmployeeSkItem>> _skFuture;

  EmployeeSkItem? _selectedSk;
  SkCommentItem? _replyingTo;
  bool _isSending = false;
  bool _isCurrentUserAdmin = false;
  final Set<String> _busySkFiles = <String>{};

  @override
  void initState() {
    super.initState();
    _employeeStream = PegawaiDirectoryService.instance
        .watchEmployee(widget.employeeUid);
    _skFuture = _loadSk();
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final PegawaiDirectoryItem? current =
        await PegawaiDirectoryService.instance.getEmployee(uid);

    if (!mounted || current == null) return;
    setState(() => _isCurrentUserAdmin = current.isAdmin);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<EmployeeSkItem>> _loadSk() async {
    final List<EmployeeSkItem> result =
        await SkCommentService.instance.loadEmployeeSk(
      widget.employeeUid,
    );

    if (mounted) {
      setState(() {
        if (result.isEmpty) {
          _selectedSk = null;
        } else if (_selectedSk == null ||
            !result.any(
              (EmployeeSkItem item) =>
                  item.commentKey == _selectedSk!.commentKey,
            )) {
          _selectedSk = result.first;
        }
      });
    }

    return result;
  }

  Future<void> _refresh() async {
    final Future<List<EmployeeSkItem>> next = _loadSk();
    setState(() => _skFuture = next);
    await next;
  }

  Future<void> _sendComment() async {
    if (_isSending || _selectedSk == null) return;

    final String text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      if (_replyingTo == null) {
        await SkCommentService.instance.addComment(
          skId: _selectedSk!.commentKey,
          text: text,
        );
      } else {
        await SkCommentService.instance.addReply(
          commentId: _replyingTo!.id,
          text: text,
        );
      }

      if (!mounted) return;
      _commentController.clear();
      setState(() => _replyingTo = null);
      _commentFocusNode.unfocus();
    } on SkCommentException catch (error) {
      if (!mounted) return;
      _showMessage(error.message, isError: true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        'Gagal mengirim komentar: $error',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startReply(SkCommentItem comment) {
    setState(() => _replyingTo = comment);
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isError ? Colors.red.shade700 : null,
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
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              'assets/images/background/background_image.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            StreamBuilder<PegawaiDirectoryItem?>(
              stream: _employeeStream,
              builder: (
                BuildContext context,
                AsyncSnapshot<PegawaiDirectoryItem?> snapshot,
              ) {
                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _accent,
                    ),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return _DetailErrorView(
                    message: snapshot.hasError
                        ? 'Gagal memuat detail pegawai.\n${snapshot.error}'
                        : 'Data pegawai tidak ditemukan.',
                  );
                }

                return _buildContent(snapshot.data!);
              },
            ),
          ],
        ),
        bottomNavigationBar: SiapPageBottomNavigationBar(
          selectedIndex: 0,
          isAdmin: _isCurrentUserAdmin,
          showBackgroundLayer: true,
        ),
      ),
    );
  }

  Widget _buildContent(PegawaiDirectoryItem employee) {
    final double statusBarHeight =
        MediaQuery.viewPaddingOf(context).top;

    return RefreshIndicator(
      color: _accent,
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverPersistentHeader(
            pinned: true,
            delegate: _DetailHeaderDelegate(
              statusBarHeight: statusBarHeight,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 130),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                _buildIdentityCard(employee),
                const SizedBox(height: 14),
                _buildEmploymentCard(employee),
                const SizedBox(height: 14),
                _buildHistorySummary(employee),
                const SizedBox(height: 14),
                _buildSkSection(employee),
                const SizedBox(height: 14),
                _buildCommentSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(PegawaiDirectoryItem employee) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: _cardDecoration(),
      child: Row(
        children: <Widget>[
          PegawaiAvatar(
            storedPhoto: employee.fotoProfil,
            radius: 43,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  employee.namaLengkap,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIP: ${_value(employee.nip)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF484848),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _value(employee.jabatanSekarang),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          _statusBadge(employee.statusKepegawaian),
        ],
      ),
    );
  }

  Widget _buildEmploymentCard(PegawaiDirectoryItem employee) {
    return _SectionCard(
      title: 'Informasi Kepegawaian',
      icon: Icons.work_outline_rounded,
      child: Column(
        children: <Widget>[
          _InfoRow(label: 'NIP', value: _value(employee.nip)),
          _InfoRow(
            label: 'Status kepegawaian',
            value: _value(employee.statusKepegawaian),
          ),
          if (employee.jenisAsn.trim().isNotEmpty)
            _InfoRow(
              label: 'Jenis ASN',
              value: employee.jenisAsn,
            ),
          _InfoRow(
            label: 'Jabatan sekarang',
            value: _withYear(
              employee.jabatanSekarang,
              employee.tahunJabatanSekarang,
            ),
          ),
          _InfoRow(
            label: 'Pangkat',
            value: _value(employee.pangkat),
          ),
          _InfoRow(
            label: 'Tempat, tanggal lahir',
            value: _birthLine(employee),
          ),
          _InfoRow(
            label: 'Pendidikan terakhir',
            value: _withYear(
              employee.pendidikan,
              employee.tahunLulusPendidikan,
            ),
          ),
          _InfoRow(
            label: 'Diklat terakhir',
            value: _withYear(
              employee.latihanJabatan,
              employee.tahunLatihanJabatan,
            ),
          ),
          _InfoRow(
            label: 'Email',
            value: _value(employee.email),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySummary(PegawaiDirectoryItem employee) {
    return Column(
      children: <Widget>[
        _SectionCard(
          title: 'Riwayat Jabatan',
          icon: Icons.timeline_rounded,
          child: _MiniHistoryBlock(
            items: employee.riwayatJabatan,
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Riwayat Pendidikan',
          icon: Icons.school_outlined,
          child: _MiniHistoryBlock(
            items: employee.riwayatPendidikan,
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Riwayat Diklat',
          icon: Icons.workspace_premium_outlined,
          child: _MiniHistoryBlock(
            items: employee.riwayatDiklat,
          ),
        ),
      ],
    );
  }

  Widget _buildSkSection(PegawaiDirectoryItem employee) {
    return _SectionCard(
      title: 'Data SK',
      icon: Icons.folder_copy_outlined,
      child: FutureBuilder<List<EmployeeSkItem>>(
        future: _skFuture,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<EmployeeSkItem>> snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: CircularProgressIndicator(
                  color: _accent,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return _InlineError(
              message: 'Gagal memuat SK: ${snapshot.error}',
              onRetry: () {
                setState(() => _skFuture = _loadSk());
              },
            );
          }

          final List<EmployeeSkItem> items =
              snapshot.data ?? <EmployeeSkItem>[];

          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'Belum ada dokumen SK.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _muted,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: <Widget>[
              for (int index = 0; index < items.length; index++) ...<Widget>[
                _SkCard(
                  item: items[index],
                  selected: _selectedSk?.commentKey ==
                      items[index].commentKey,
                  canAccessFile: _canAccessSkFile,
                  isBusy: _busySkFiles.contains(
                    items[index].commentKey,
                  ),
                  onPreview: () => _previewSk(
                    employee,
                    items[index],
                  ),
                  onDownload: () => _downloadSk(
                    items[index],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedSk = items[index];
                      _replyingTo = null;
                      _commentController.clear();
                    });
                  },
                ),
                if (index != items.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentSection() {
    final EmployeeSkItem? selected = _selectedSk;

    return _SectionCard(
      title: selected == null
          ? 'Komentar'
          : 'Komentar • ${selected.jenisLabel}',
      icon: Icons.forum_outlined,
      child: selected == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'Pilih dokumen SK untuk membuka diskusi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _muted,
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SelectedSkHint(item: selected),
                const SizedBox(height: 13),
                StreamBuilder<List<SkCommentItem>>(
                  stream: SkCommentService.instance.watchComments(
                    selected.commentKey,
                  ),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<List<SkCommentItem>> snapshot,
                  ) {
                    if (snapshot.connectionState ==
                            ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _accent,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Text(
                        'Gagal memuat komentar: ${snapshot.error}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      );
                    }

                    final List<SkCommentItem> comments =
                        snapshot.data ?? <SkCommentItem>[];

                    if (comments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: Text(
                            'Belum ada komentar.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _muted,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: <Widget>[
                        for (int index = 0;
                            index < comments.length;
                            index++) ...<Widget>[
                          _CommentCard(
                            comment: comments[index],
                            onReply: () =>
                                _startReply(comments[index]),
                            onDelete: () =>
                                _deleteComment(comments[index]),
                          ),
                          if (index != comments.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                if (_replyingTo != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1D5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Membalas ${_replyingTo!.namaPengguna}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF76500D),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _cancelReply,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _commentFocusNode,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 1000,
                        textCapitalization:
                            TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: _replyingTo == null
                              ? 'Tulis komentar...'
                              : 'Tulis balasan...',
                          hintStyle: const TextStyle(fontSize: 12),
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD4D0C6),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _accent,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: FilledButton(
                        onPressed: _isSending ? null : _sendComment,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: _accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                size: 20,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  bool get _canAccessSkFile {
    final String? currentUid =
        FirebaseAuth.instance.currentUser?.uid;

    return currentUid != null &&
        (_isCurrentUserAdmin ||
            currentUid == widget.employeeUid);
  }

  Future<void> _previewSk(
    PegawaiDirectoryItem employee,
    EmployeeSkItem item,
  ) async {
    if (!_canAccessSkFile ||
        item.filePath.trim().isEmpty ||
        _busySkFiles.contains(item.commentKey)) {
      return;
    }

    setState(() {
      _busySkFiles.add(item.commentKey);
    });

    try {
      final String localPath =
          await EmployeeSkFileService.instance
              .preparePreviewFile(
        storagePath: item.filePath,
        fileName: item.fileName,
      );

      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PratinjauPdfPage(
            filePath: localPath,
            fileName: item.fileName.trim().isEmpty
                ? '${item.jenisLabel}.pdf'
                : item.fileName.trim(),
            jenisSk: item.jenisLabel,
            nomorDokumen: item.nomor,
            tanggalDokumen: item.tanggal,
            pemilik: employee.namaLengkap,
            jabatan: employee.jabatanSekarang,
            details: _previewDetails(item.rawData),
          ),
        ),
      );
    } on EmployeeSkFileException catch (error) {
      if (mounted) {
        _showMessage(error.message, isError: true);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Gagal membuka dokumen: $error',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busySkFiles.remove(item.commentKey);
        });
      }
    }
  }

  Future<void> _downloadSk(
    EmployeeSkItem item,
  ) async {
    if (!_canAccessSkFile ||
        item.filePath.trim().isEmpty ||
        _busySkFiles.contains(item.commentKey)) {
      return;
    }

    setState(() {
      _busySkFiles.add(item.commentKey);
    });

    try {
      final String? savedPath =
          await EmployeeSkFileService.instance.downloadFile(
        storagePath: item.filePath,
        fileName: item.fileName.trim().isEmpty
            ? '${item.jenisLabel}.pdf'
            : item.fileName.trim(),
      );

      if (!mounted || savedPath == null) return;

      _showMessage('Dokumen berhasil disimpan.');
    } on EmployeeSkFileException catch (error) {
      if (mounted) {
        _showMessage(error.message, isError: true);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Gagal mengunduh dokumen: $error',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busySkFiles.remove(item.commentKey);
        });
      }
    }
  }

  List<PratinjauPdfDetail> _previewDetails(
    Map<String, dynamic> rawData,
  ) {
    const Set<String> hiddenKeys = <String>{
      'owner_id',
      'file_pdf',
      'file_path',
      'file_sk',
      'created_at',
      'updated_at',
      'status',
      'status_sk',
      'status_verifikasi',
    };

    final List<PratinjauPdfDetail> result =
        <PratinjauPdfDetail>[];

    final List<MapEntry<String, dynamic>> entries =
        rawData.entries
            .where(
              (MapEntry<String, dynamic> entry) =>
                  !hiddenKeys.contains(entry.key) &&
                  entry.value != null,
            )
            .toList()
          ..sort(
            (
              MapEntry<String, dynamic> a,
              MapEntry<String, dynamic> b,
            ) =>
                a.key.compareTo(b.key),
          );

    for (final MapEntry<String, dynamic> entry in entries) {
      final String value = _previewValue(entry.value);
      if (value == '-' || value.trim().isEmpty) continue;

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

    if (value is Timestamp) {
      return _formatDate(value.toDate());
    }

    if (value is DateTime) {
      return _formatDate(value);
    }

    if (value is bool) {
      return value ? 'Ya' : 'Tidak';
    }

    if (value is num) {
      return value.toString();
    }

    if (value is List) {
      final List<String> parts = value
          .map((dynamic item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .toList();

      return parts.isEmpty ? '-' : parts.join(', ');
    }

    if (value is Map) {
      return '-';
    }

    final String text = value.toString().trim();
    return text.isEmpty ? '-' : text;
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

  Future<void> _deleteComment(SkCommentItem comment) async {
    final bool confirmed = await _confirmDelete(
      'Hapus komentar ini beserta seluruh balasannya?',
    );
    if (!confirmed) return;

    try {
      await SkCommentService.instance.deleteComment(comment);
    } on SkCommentException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } catch (error) {
      if (mounted) {
        _showMessage('Gagal menghapus komentar: $error', isError: true);
      }
    }
  }

  Future<bool> _confirmDelete(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: _card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              title: const Text(
                'Konfirmasi Hapus',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  child: const Text('BATAL'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  child: const Text('HAPUS'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFD7EED0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.trim().isEmpty ? '-' : status.trim(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2A7A30),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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
    );
  }

  static String _value(String value) {
    final String clean = value.trim();
    return clean.isEmpty ? '-' : clean;
  }

  static String _withYear(String value, int year) {
    final String clean = value.trim();
    if (clean.isEmpty && year <= 0) return '-';
    if (year <= 0) return clean;
    if (clean.isEmpty) return year.toString();
    return '$clean • $year';
  }

  static String _birthLine(PegawaiDirectoryItem employee) {
    final String place = employee.tempatLahir.trim();
    final DateTime? date = employee.tanggalLahir;

    if (place.isEmpty && date == null) return '-';
    if (date == null) return place;
    if (place.isEmpty) return _formatDate(date);
    return '$place, ${_formatDate(date)}';
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

class _DetailHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double statusBarHeight;
  final VoidCallback onBack;

  const _DetailHeaderDelegate({
    required this.statusBarHeight,
    required this.onBack,
  });

  @override
  double get minExtent => statusBarHeight + 60;

  @override
  double get maxExtent => statusBarHeight + 76;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double distance = maxExtent - minExtent;
    final double progress = distance == 0
        ? 1
        : (shrinkOffset / distance).clamp(0.0, 1.0);
    final double eased = Curves.easeOut.transform(
      (progress * 0.6).clamp(0.0, 1.0),
    );
    final Color topColor = Color.lerp(
      const Color(0x20FFFCF4),
      const Color(0xFFFFFCF4),
      eased,
    )!;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    topColor,
                    const Color(0x10FFFCF4),
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
            right: 18,
            bottom: 2,
            height: 58,
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: 'Kembali',
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 2),
                const Expanded(
                  child: Text(
                    'Detail Pegawai',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: _DetailPegawaiPageState._text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DetailHeaderDelegate oldDelegate) {
    return oldDelegate.statusBarHeight != statusBarHeight ||
        oldDelegate.onBack != onBack;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 19,
                  color: const Color(0xFF9D6A18),
                ),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            color: Color(0xFFE2DDD2),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF756F65),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
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

class _MiniHistoryBlock extends StatelessWidget {
  final List<PegawaiHistoryItem> items;

  const _MiniHistoryBlock({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final List<PegawaiHistoryItem> visible =
        items.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x9CFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x66D9CBA9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (visible.isEmpty)
            const Text(
              '-',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF756F65),
              ),
            )
          else
            for (final PegawaiHistoryItem item in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.circle,
                      size: 6,
                      color: Color(0xFF9D6A18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Text(
                      item.year.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF756F65),
                      ),
                    ),
                  ],
                ),
              ),
          if (items.length > 3)
            Text(
              '+${items.length - 3} riwayat lainnya',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9D6A18),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _SkCard extends StatelessWidget {
  final EmployeeSkItem item;
  final bool selected;
  final bool canAccessFile;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onPreview;
  final VoidCallback onDownload;

  const _SkCard({
    required this.item,
    required this.selected,
    required this.canAccessFile,
    required this.isBusy,
    required this.onTap,
    required this.onPreview,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFile = item.filePath.trim().isNotEmpty;
    final bool showActions = canAccessFile && hasFile;

    return Material(
      color: selected
          ? const Color(0xFFFFF1D4)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFFE19A22)
                  : const Color(0xFFD9D5CC),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFD7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFFE58A00),
                  size: 21,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.jenisLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.nomor.trim().isEmpty
                          ? '-'
                          : item.nomor.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF756F65),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.tanggal == null
                          ? '-'
                          : _DetailPegawaiPageState
                              ._formatDate(item.tanggal!),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF756F65),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.fileName.trim().isEmpty
                          ? 'File belum tersedia'
                          : item.fileName.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: hasFile
                            ? const Color(0xFF9D6A18)
                            : const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              if (showActions) ...<Widget>[
                const SizedBox(width: 5),
                if (isBusy)
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF9D6A18),
                      ),
                    ),
                  )
                else ...<Widget>[
                  _SkActionButton(
                    tooltip: 'Pratinjau dokumen',
                    icon: Icons.visibility_outlined,
                    onTap: onPreview,
                  ),
                  const SizedBox(width: 5),
                  _SkActionButton(
                    tooltip: 'Unduh dokumen',
                    icon: Icons.download_outlined,
                    onTap: onDownload,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SkActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _SkActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFFFFCF5),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: const Color(0xFFE7DEC9),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF191919),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedSkHint extends StatelessWidget {
  final EmployeeSkItem item;

  const _SelectedSkHint({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D5),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        '${item.jenisLabel} • '
        '${item.nomor.trim().isEmpty ? '-' : item.nomor.trim()}',
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF76500D),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CommentCard extends StatefulWidget {
  final SkCommentItem comment;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _CommentCard({
    required this.comment,
    required this.onReply,
    required this.onDelete,
  });

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    final String? currentUid =
        FirebaseAuth.instance.currentUser?.uid;
    final bool ownComment = currentUid == widget.comment.ownerId;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD9D5CC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFFFFEFD7),
                child: Icon(
                  Icons.person_rounded,
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
                      widget.comment.namaPengguna,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _formatCommentTime(widget.comment.createdAt),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF89847A),
                      ),
                    ),
                  ],
                ),
              ),
              if (ownComment)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 19,
                  onSelected: (String value) {
                    if (value == 'delete') widget.onDelete();
                  },
                  itemBuilder: (_) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Hapus komentar'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            widget.comment.isiKomentar,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            children: <Widget>[
              InkWell(
                onTap: widget.onReply,
                child: const Text(
                  'Balas',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9D6A18),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() => _showReplies = !_showReplies);
                },
                child: Text(
                  _showReplies
                      ? 'Sembunyikan balasan'
                      : widget.comment.jumlahBalasan > 0
                          ? 'Lihat ${widget.comment.jumlahBalasan} balasan'
                          : 'Lihat balasan',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C6F8B),
                  ),
                ),
              ),
            ],
          ),
          if (_showReplies) ...<Widget>[
            const SizedBox(height: 10),
            StreamBuilder<List<SkReplyItem>>(
              stream: SkCommentService.instance.watchReplies(
                widget.comment.id,
              ),
              builder: (
                BuildContext context,
                AsyncSnapshot<List<SkReplyItem>> snapshot,
              ) {
                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const LinearProgressIndicator(
                    minHeight: 2,
                    color: Color(0xFF9D6A18),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Gagal memuat balasan: ${snapshot.error}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade700,
                    ),
                  );
                }

                final List<SkReplyItem> replies =
                    snapshot.data ?? <SkReplyItem>[];

                if (replies.isEmpty) {
                  return const Text(
                    'Belum ada balasan.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF89847A),
                    ),
                  );
                }

                return Column(
                  children: <Widget>[
                    for (int index = 0;
                        index < replies.length;
                        index++) ...<Widget>[
                      _ReplyTile(reply: replies[index]),
                      if (index != replies.length - 1)
                        const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  static String _formatCommentTime(DateTime? date) {
    if (date == null) return 'Baru saja';

    final Duration difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inHours < 1) {
      return '${difference.inMinutes} menit lalu';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} jam lalu';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    }
    return _DetailPegawaiPageState._formatDate(date);
  }
}

class _ReplyTile extends StatelessWidget {
  final SkReplyItem reply;

  const _ReplyTile({required this.reply});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 18),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5ED),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            reply.namaPengguna,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reply.isiBalasan,
            style: const TextStyle(
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: <Widget>[
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 10),
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

class _DetailErrorView extends StatelessWidget {
  final String message;

  const _DetailErrorView({required this.message});

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
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
