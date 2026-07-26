import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/profilepegawai_model.dart';
import '../../../models/users_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/sk_document_service.dart';
import '../../../widgets/navigation/bottom_navigation_bar.dart';
import '../../../widgets/profile/pegawai_avatar.dart';
import '../../pratinjau_dokumen/pratinjau_pdf_page.dart';

class FormSkPendidikanPage extends StatefulWidget {
  const FormSkPendidikanPage({super.key});

  @override
  State<FormSkPendidikanPage> createState() => _FormSkPendidikanPageState();
}

class _FormSkPendidikanPageState extends State<FormSkPendidikanPage> with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF9D6A18);
  static const Color _green = Color(0xFF27972D);
  static const Color _card = Color(0xFFFFFCF5);
  static const Color _fieldFill = Color(0xFFFEFEFC);
  static const Color _border = Color(0xFFD6D3CC);
  static const Color _text = Color(0xFF191919);

  static const List<String> _pendidikanOptions = <String>[
    'SD',
    'SMP',
    'SMA/SMK',
    'D-I',
    'D-II',
    'D-III',
    'D-IV',
    'S-1',
    'S-2',
    'S-3',
  ];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _tingkatController = TextEditingController();
  final TextEditingController _jurusanController = TextEditingController();
  final TextEditingController _nomorIjazahController = TextEditingController();
  final TextEditingController _namaSekolahController = TextEditingController();
  final TextEditingController _kotaController = TextEditingController();

  late final Future<_EmployeeHeaderData> _employeeFuture;
  late final AnimationController _entryController;
  late final Animation<double> _entryOpacity;
  late final Animation<Offset> _entryOffset;

  DateTime? _tanggalIjazah;
  PlatformFile? _pdfFile;

  bool _showHint = true;
  bool _isSubmitting = false;
  bool _dataPendidikanExpanded = true;
  bool _dataIjazahExpanded = true;
  bool _instansiExpanded = true;
  bool _dokumenExpanded = true;


  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final CurvedAnimation entryCurve = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryOpacity = Tween<double>(begin: 0, end: 1).animate(entryCurve);
    _entryOffset = Tween<Offset>(
      begin: const Offset(0.035, 0),
      end: Offset.zero,
    ).animate(entryCurve);
    _employeeFuture = _loadEmployeeData();
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _tingkatController.dispose();
    _jurusanController.dispose();
    _nomorIjazahController.dispose();
    _namaSekolahController.dispose();
    _kotaController.dispose();
    super.dispose();
  }

  Future<_EmployeeHeaderData> _loadEmployeeData() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const _EmployeeHeaderData();

    final List<dynamic> result = await Future.wait<dynamic>(<Future<dynamic>>[
      FirestoreService.instance.getUserData(uid),
      FirestoreService.instance.getProfilePegawai(uid),
    ]);

    return _EmployeeHeaderData(
      user: result[0] as UsersModel?,
      profile: result[1] as ProfilePegawaiModel?,
    );
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 10),
      helpText: 'Pilih tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _accent,
              onPrimary: Colors.white,
              surface: Color(0xFFFFFCF5),
              onSurface: _text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (selected == null || !mounted) return;
    onSelected(selected);
  }

  Future<void> _pickPdf() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf'],
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final PlatformFile file = result.files.single;
    const int maxBytes = 5 * 1024 * 1024;
    if (file.extension?.toLowerCase() != 'pdf') {
      _showMessage('File harus berformat PDF.');
      return;
    }
    if (file.size > maxBytes) {
      _showMessage('Ukuran PDF maksimal 5 MB.');
      return;
    }
    setState(() { _pdfFile = file; });
  }

  Future<void> _showOptions({
    required String title,
    required List<String> options,
    required TextEditingController controller,
    ValueChanged<String>? onSelected,
  }) async {
    final TextEditingController searchController = TextEditingController();
    String keyword = '';
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final List<String> filtered = options.where((String item) {
              return item.toLowerCase().contains(keyword.toLowerCase());
            }).toList();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 18,
                ),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.62,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: searchController,
                        autofocus: false,
                        onChanged: (String value) {
                          setSheetState(() { keyword = value.trim(); });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari atau ketik pilihan',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('Pilihan tidak ditemukan'))
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (BuildContext context, int index) {
                                  final String item = filtered[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      item,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    onTap: () => Navigator.pop(context, item),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    searchController.dispose();
    if (selected != null && mounted) {
      controller.text = selected;
      onSelected?.call(selected);
      setState(() {});
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final bool fieldsValid = _formKey.currentState?.validate() ?? false;
    if (!fieldsValid) {
      _showMessage('Lengkapi seluruh data wajib terlebih dahulu.');
      return;
    }

    if (_tanggalIjazah == null) {
      _showMessage('Semua tanggal wajib dipilih.');
      return;
    }

    if (_pdfFile == null) {
      _showMessage('Dokumen PDF SK wajib dipilih.');
      return;
    }
    final bool confirmed = await _showConfirmDialog();
    if (!confirmed || !mounted) return;
    setState(() { _isSubmitting = true; });
    try {
      final PlatformFile selectedPdf = _pdfFile!;
      final String? localPath = selectedPdf.path;

      if (localPath == null || localPath.trim().isEmpty) {
        throw const SkDocumentException(
          'File PDF tidak dapat dibaca dari perangkat.',
        );
      }

      final _EmployeeHeaderData employee =
          await _employeeFuture;

      await SkDocumentService.instance.createDocument(
        collection: 'sk_pendidikan',
        storageFolder: 'pendidikan',
        file: File(localPath),
        originalFileName: selectedPdf.name,
        data: <String, dynamic>{
          'tingkat_pendidikan': _tingkatController.text.trim(),
          'jurusan': _jurusanController.text.trim(),
          'nomor_ijazah': _nomorIjazahController.text.trim(),
          'tanggal_ijazah': Timestamp.fromDate(_tanggalIjazah!),
          'nama_sekolah': _namaSekolahController.text.trim(),
          'kota': _kotaController.text.trim(),
          'nomor_dokumen': _nomorIjazahController.text.trim(),
          'tanggal_dokumen': Timestamp.fromDate(_tanggalIjazah!),
          'jenis_sk': 'SK Pendidikan',
          'nama_pegawai': employee.user?.nama_lengkap.trim() ?? '',
          'nip': employee.user?.nip.trim() ?? '',
          'jabatan_saat_upload':
              employee.profile?.jabatan_sekarang.trim() ?? '',
          'status': 'Pending',
        },
      );

      if (!mounted) return;
      await _showSuccessDialog();
    } on SkDocumentException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.message ?? 'Firestore gagal menyimpan data SK.',
      );
    } catch (error, stackTrace) {
      debugPrint('SAVE SK ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showMessage('Gagal menyimpan data SK: $error');
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }


  void _resetForm() {
    FocusScope.of(context).unfocus();
    _formKey.currentState?.reset();
    _tingkatController.clear();
    _jurusanController.clear();
    _nomorIjazahController.clear();
    _namaSekolahController.clear();
    _kotaController.clear();
    setState(() {
      _tanggalIjazah = null;
      _pdfFile = null;

    });
  }


  Future<bool> _showConfirmDialog() async {
    return await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: false,
          barrierLabel: 'Konfirmasi simpan',
          barrierColor: Colors.black.withOpacity(0.46),
          transitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (_, _, _) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.sizeOf(context).width * 0.72,
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF5),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFEFD7),
                        ),
                        child: const Icon(
                          Icons.save_rounded,
                          color: Color(0xFFF08A00),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(width: 42, child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 7),
                            child: CircleAvatar(
                              radius: 2,
                              backgroundColor: Color(0xFF6D6D6D),
                            ),
                          ),
                          SizedBox(width: 42, child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 13),
                      const Text(
                        'Anda Yakin Ingin Simpan Data?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _text,
                                side: const BorderSide(color: Color(0xFFE19000)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                              child: const Text('BATAL'),
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFEA8C00),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                              child: const Text('SIMPAN'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          transitionBuilder: (_, Animation<double> animation, _, Widget child) {
            final Animation<double> curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: curved, child: child),
            );
          },
        ) ??
        false;
  }

  Future<void> _showSuccessDialog() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Data berhasil disimpan',
      barrierColor: Colors.black.withOpacity(0.46),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.72,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF5),
                borderRadius: BorderRadius.circular(17),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE9F7DD),
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: Color(0xFF31801E),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(width: 42, child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 7),
                        child: CircleAvatar(
                          radius: 2,
                          backgroundColor: Color(0xFF6D6D6D),
                        ),
                      ),
                      SizedBox(width: 42, child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Data Berhasil Disimpan',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('TUTUP'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, Animation<double> animation, _, Widget child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.viewPaddingOf(context).top;
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
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              'assets/images/background/background_image.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            FadeTransition(
              opacity: _entryOpacity,
              child: SlideTransition(
                position: _entryOffset,
                child: Form(
                  key: _formKey,
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: <Widget>[
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SkTopHeaderDelegate(
                          title: 'PENDIDIKAN',
                          statusBarHeight: statusBarHeight,
                          onBack: () => Navigator.of(context).pop(),
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildEmployeeHeader()),
                      if (_showHint)
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _HintHeaderDelegate(
                            onClose: () {
                              setState(() { _showHint = false; });
                            },
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 18)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(<Widget>[
                        _FormSection(
                          title: 'DATA PENDIDIKAN',
                          icon: Icons.school_rounded,
                          expanded: _dataPendidikanExpanded,
                          onToggle: () {
                            setState(() { _dataPendidikanExpanded = !_dataPendidikanExpanded; });
                          },
                          children: <Widget>[
                            _InputDropdownField(
                                                          label: 'TINGKAT PENDIDIKAN',
                                                          hint: 'Pilih Tingkat Pendidikan',
                                                          controller: _tingkatController,
                                                          onOpen: () => _showOptions(
                                                            title: 'Pilih Tingkat Pendidikan',
                                                            options: _pendidikanOptions,
                                                            controller: _tingkatController,
                                                          ),
                                                        ),
                            _CompactTextField(
                                                          label: 'JURUSAN PENDIDIKAN',
                                                          hint: 'Masukkan Jurusan Pendidikan',
                                                          controller: _jurusanController,
                                                        ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _FormSection(
                          title: 'DATA IJAZAH',
                          icon: Icons.description_outlined,
                          expanded: _dataIjazahExpanded,
                          onToggle: () {
                            setState(() { _dataIjazahExpanded = !_dataIjazahExpanded; });
                          },
                          children: <Widget>[
                            _CompactTextField(
                                                          label: 'NOMOR IJAZAH',
                                                          hint: 'Masukkan Nomor Ijazah',
                                                          controller: _nomorIjazahController,
                                                        ),
                            _CompactDateField(
                                                          label: 'TANGGAL IJAZAH / LULUS',
                                                          date: _tanggalIjazah,
                                                          onTap: () => _pickDate(
                                                            current: _tanggalIjazah,
                                                            onSelected: (DateTime value) {
                                                              setState(() { _tanggalIjazah = value; });
                                                            },
                                                          ),
                                                        ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _FormSection(
                          title: 'INSTANSI PENDIDIKAN',
                          icon: Icons.account_balance_outlined,
                          expanded: _instansiExpanded,
                          onToggle: () {
                            setState(() { _instansiExpanded = !_instansiExpanded; });
                          },
                          children: <Widget>[
                            _CompactTextField(
                                                          label: 'NAMA SEKOLAH / PERGURUAN TINGGI',
                                                          hint: 'Masukkan nama sekolah atau perguruan tinggi',
                                                          controller: _namaSekolahController,
                                                        ),
                            _CompactTextField(
                                                          label: 'KOTA SEKOLAH / PENDIDIKAN TINGGI ASAL',
                                                          hint: 'Masukkan kota asal pendidikan',
                                                          controller: _kotaController,
                                                        ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _FormSection(
                          title: 'DOKUMEN SK',
                          icon: Icons.description_outlined,
                          expanded: _dokumenExpanded,
                          onToggle: () {
                            setState(() { _dokumenExpanded = !_dokumenExpanded; });
                          },
                          children: <Widget>[
                            _PdfPickerField(
                              file: _pdfFile,
                              onTap: _pickPdf,
                              jenisSk: 'SK PENDIDIKAN',
                              employeeFuture: _employeeFuture,
                              nomorDokumenBuilder: () =>
                                  _nomorIjazahController.text,
                              tanggalDokumenBuilder: () =>
                                  _tanggalIjazah,
                              detailBuilder: () =>
                                  <PratinjauPdfDetail>[
                                PratinjauPdfDetail.text(
                                  label: 'Tingkat Pendidikan',
                                  value: _tingkatController.text,
                                ),
                                PratinjauPdfDetail.text(
                                  label: 'Jurusan Pendidikan',
                                  value: _jurusanController.text,
                                ),
                                PratinjauPdfDetail.text(
                                  label: 'Nomor Ijazah',
                                  value: _nomorIjazahController.text,
                                ),
                                PratinjauPdfDetail.date(
                                  label: 'Tanggal Ijazah/Lulus',
                                  value: _tanggalIjazah,
                                ),
                                PratinjauPdfDetail.text(
                                  label: 'Nama Sekolah/Perguruan Tinggi',
                                  value: _namaSekolahController.text,
                                ),
                                PratinjauPdfDetail.text(
                                  label: 'Kota Sekolah/Pendidikan Tinggi Asal',
                                  value: _kotaController.text,
                                ),
                                  ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 45,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined, size: 20),
                            label: Text(
                              _isSubmitting ? 'MENYIMPAN...' : 'SIMPAN DATA',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              disabledBackgroundColor: _accent.withOpacity(0.65),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _resetForm,
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text('RESET'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accent,
                              side: const BorderSide(color: _accent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 112),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const SiapPageBottomNavigationBar(
          selectedIndex: 1,
          showBackgroundLayer: true,
        ),
      ),
    );
  }

  Widget _buildEmployeeHeader() {
    return FutureBuilder<_EmployeeHeaderData>(
      future: _employeeFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<_EmployeeHeaderData> snapshot,
      ) {
        final _EmployeeHeaderData data =
            snapshot.data ?? const _EmployeeHeaderData();
        final String name = data.user?.nama_lengkap.trim().isNotEmpty == true
            ? data.user!.nama_lengkap.trim()
            : 'Pengguna';
        final String nip = data.user?.nip.trim().isNotEmpty == true
            ? data.user!.nip.trim()
            : '-';
        final String photo = data.profile?.foto_profil.trim() ?? '';

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 13, 18, 18),
          child: Column(
            children: <Widget>[
              PegawaiAvatar(
                storedPhoto: photo,
                radius: 51,
                backgroundColor: const Color(0xFFF4F4F4),
                iconColor: const Color(0xFFD8D8D8),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'NIP: $nip',
                style: const TextStyle(fontSize: 12, letterSpacing: 0.7),
              ),
            ],
          ),
        );
      },
    );
  }

}

class _SkTopHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final double statusBarHeight;
  final VoidCallback onBack;

  const _SkTopHeaderDelegate({
    required this.title,
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
    final double collapseDistance = maxExtent - minExtent;
    final double progress = collapseDistance == 0
        ? 1
        : (shrinkOffset / collapseDistance).clamp(0.0, 1.0);
    final double easedProgress = Curves.easeOut.transform(
      (progress * 0.6).clamp(0.0, 1.0),
    );
    final Color pinnedGradientColor = Color.lerp(
      const Color(0x20FFFCF4),
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
                    const Color(0x10FFFCF4),
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
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 18, 2),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 24),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF191919),
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
  }

  @override
  bool shouldRebuild(covariant _SkTopHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.statusBarHeight != statusBarHeight ||
        oldDelegate.onBack != onBack;
  }
}

class _EmployeeHeaderData {
  final UsersModel? user;
  final ProfilePegawaiModel? profile;

  const _EmployeeHeaderData({this.user, this.profile});
}

class _HintHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onClose;

  const _HintHeaderDelegate({
    required this.onClose,
  });

  @override
  double get minExtent => 96;

  @override
  double get maxExtent => 96;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 7, 18, 7),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 1.6,
              sigmaY: 1.6,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 8, 9, 8),
              decoration: BoxDecoration(
                color: const Color(0x40EDD59D),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: const Color.fromARGB(129, 255, 255, 255),
                  width: 1,
                ),
              ),
              child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.info_rounded,
                  size: 18,
                  color: Color(0xFF8A651A),
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Petunjuk',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF7B5A17),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pastikan data yang dimasukkan sudah sesuai.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6F6049),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onClose,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Color(0xFF6E4F16),
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HintHeaderDelegate oldDelegate) {
    return oldDelegate.onClose != onClose;
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF5),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x36000000),
            blurRadius: 5,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 10, 9),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 17, color: const Color(0xFF9A6410)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4E4E4E),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: expanded ? 0 : 0.5,
                    child: const Icon(Icons.keyboard_arrow_up_rounded, size: 22),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...<Widget>[
            const Divider(height: 1, color: Color(0xFFE6E1D7)),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
              child: Column(children: children),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactTextField extends StatelessWidget {
  final String? label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool requiredField;
  final int maxLines;

  const _CompactTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.requiredField = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (label != null) ...<Widget>[
            Text(
              label!,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
          ],
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 11),
            validator: requiredField
                ? (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Wajib diisi';
                    }
                    return null;
                  }
                : null,
            decoration: _fieldDecoration(hint),
          ),
        ],
      ),
    );
  }
}

class _CompactReadOnlyField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const _CompactReadOnlyField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: true,
            style: const TextStyle(fontSize: 11),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) return 'Wajib diisi';
              return null;
            },
            decoration: _fieldDecoration(hint),
          ),
        ],
      ),
    );
  }
}

class _CompactDateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _CompactDateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String value = date == null
        ? 'Pilih Tanggal'
        : '${date!.day.toString().padLeft(2, '0')}/'
            '${date!.month.toString().padLeft(2, '0')}/'
            '${date!.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: InputDecorator(
              decoration: _fieldDecoration('Pilih Tanggal').copyWith(
                prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 10,
                  color: date == null
                      ? const Color(0xFF8A8A8A)
                      : const Color(0xFF1E1E1E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onOpen;

  const _InputDropdownField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: true,
            showCursor: false,
            onTap: onOpen,
            style: const TextStyle(fontSize: 11),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) return 'Wajib diisi';
              return null;
            },
            decoration: _fieldDecoration(hint).copyWith(
              suffixIcon: IconButton(
                tooltip: 'Buka pilihan',
                onPressed: onOpen,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableInputDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onOpen;

  const _EditableInputDropdownField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 11),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) return 'Wajib diisi';
              return null;
            },
            decoration: _fieldDecoration(hint).copyWith(
              suffixIcon: IconButton(
                tooltip: 'Buka pilihan',
                onPressed: onOpen,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCheckboxField extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CompactCheckboxField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD6D3CC)),
      ),
      child: CheckboxListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF9D6A18),
        value: value,
        onChanged: (bool? next) => onChanged(next ?? false),
        title: Text(label, style: const TextStyle(fontSize: 10)),
      ),
    );
  }
}

class _PdfPickerField extends StatelessWidget {
  final PlatformFile? file;
  final VoidCallback onTap;
  final String jenisSk;
  final Future<_EmployeeHeaderData> employeeFuture;
  final String Function() nomorDokumenBuilder;
  final DateTime? Function() tanggalDokumenBuilder;
  final List<PratinjauPdfDetail> Function() detailBuilder;

  const _PdfPickerField({
    required this.file,
    required this.onTap,
    required this.jenisSk,
    required this.employeeFuture,
    required this.nomorDokumenBuilder,
    required this.tanggalDokumenBuilder,
    required this.detailBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final String fileName = file?.name ?? 'Choose File';
    final String? filePath = file?.path;
    final bool canPreview =
        filePath != null && filePath.trim().isNotEmpty;

    Future<void> openPreview() async {
      if (!canPreview) return;

      _EmployeeHeaderData employee =
          const _EmployeeHeaderData();

      try {
        employee = await employeeFuture;
      } catch (_) {
        employee = const _EmployeeHeaderData();
      }

      if (!context.mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PratinjauPdfPage(
            filePath: filePath!,
            fileName: file!.name,
            jenisSk: jenisSk,
            nomorDokumen: nomorDokumenBuilder(),
            tanggalDokumen: tanggalDokumenBuilder(),
            pemilik: employee.user?.nama_lengkap ?? '-',
            jabatan:
                employee.profile?.jabatan_sekarang ?? '-',
            details: detailBuilder(),
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(6),
          ),
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFD7D7D7),
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.upload_file_rounded,
                  size: 28,
                  color: Color(0xFFFF6D78),
                ),
                const SizedBox(height: 3),
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        Semantics(
          button: true,
          enabled: canPreview,
          label: 'Pratinjau dokumen',
          child: InkWell(
            onTap: canPreview ? openPreview : null,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(6),
            ),
            child: Container(
              width: double.infinity,
              height: 27,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFD7D7D7),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(6),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Pratinjau dokumen',
                style: TextStyle(
                  fontSize: 9,
                  color: canPreview
                      ? const Color(0xFF0069E8)
                      : const Color(0xFF9E9E9E),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 9, color: Color(0xFF929292)),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    filled: true,
    fillColor: const Color(0xFFFEFEFC),
    errorStyle: const TextStyle(fontSize: 8, height: 0.8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFD6D3CC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFD6D3CC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFF9D6A18), width: 1.2),
    ),
  );
}

