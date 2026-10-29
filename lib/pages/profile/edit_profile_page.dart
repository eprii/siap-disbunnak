import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/profilepegawai_model.dart';
import '../../models/users_model.dart';
import '../../services/profile_account_service.dart';
import '../../services/profile_photo_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/feedback/siap_top_notification.dart';
import '../../widgets/navigation/bottom_navigation_bar.dart';

enum _PositionChangeMode {
  newPosition,
  correction,
}

class EditProfilePage extends StatefulWidget {
  final UsersModel initialUser;
  final ProfilePegawaiModel initialProfile;
  final ProfileExtendedData initialExtendedData;
  final String initialPhotoUrl;

  const EditProfilePage({
    super.key,
    required this.initialUser,
    required this.initialProfile,
    required this.initialExtendedData,
    this.initialPhotoUrl = '',
  });

  @override
  State<EditProfilePage> createState() =>
      _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color _accent = Color(0xFF9D6A18);
  static const Color _card = Color(0xFFFFFCF5);
  static const Color _text = Color(0xFF191919);

  static const List<String> _statusKepegawaianOptions =
      <String>[
    'ASN',
    'P3K',
    'P3K Paruh Waktu',
    'PJLP',
  ];

  static const List<String> _jenisAsnOptions = <String>[
    'Jabatan Struktural',
    'Jabatan Fungsional',
  ];


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

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _namaController =
      TextEditingController();
  final TextEditingController _nipController =
      TextEditingController();
  final TextEditingController _usernameController =
      TextEditingController();
  final TextEditingController _emailController =
      TextEditingController();
  final TextEditingController _teleponController =
      TextEditingController();
  final TextEditingController _statusKepegawaianController =
      TextEditingController();
  final TextEditingController _jenisAsnController =
      TextEditingController();
  final TextEditingController _pangkatController =
      TextEditingController();
  final TextEditingController _jabatanSekarangController =
      TextEditingController();
  final TextEditingController _tahunJabatanSekarangController =
      TextEditingController();
  final TextEditingController _tempatLahirController =
      TextEditingController();
  final List<PositionHistoryEntry> _positionHistory =
      <PositionHistoryEntry>[];
  final List<EducationHistoryEntry> _educationHistory =
      <EducationHistoryEntry>[];
  final TextEditingController _latihanJabatanController =
      TextEditingController();
  final TextEditingController _tahunLatihanController =
      TextEditingController();
  final TextEditingController _passwordBaruController =
      TextEditingController();
  final TextEditingController _konfirmasiPasswordController =
      TextEditingController();

  Uint8List? _selectedPhotoBytes;
  String _selectedPhotoName = '';
  DateTime? _tanggalLahir;
  bool _removePhoto = false;

  bool _profilExpanded = true;
  bool _kepegawaianExpanded = true;
  bool _jabatanSekarangExpanded = true;
  bool _riwayatJabatanExpanded = true;
  bool _pendidikanExpanded = true;
  bool _diklatExpanded = true;
  bool _akunExpanded = true;
  bool _isSaving = false;
  _PositionChangeMode _positionChangeMode =
      _PositionChangeMode.newPosition;

  @override
  void initState() {
    super.initState();

    final UsersModel user = widget.initialUser;
    final ProfilePegawaiModel profile = widget.initialProfile;

    _namaController.text = user.nama_lengkap;
    _nipController.text = user.nip;
    _usernameController.text = user.username;
    _emailController.text = user.email;
    _teleponController.text = user.no_telepon;

    _statusKepegawaianController.text =
        profile.status_kepegawaian;
    _jenisAsnController.text = profile.jenis_asn;
    _pangkatController.text = profile.pangkat;
    _jabatanSekarangController.text =
        profile.jabatan_sekarang;
    _tahunJabatanSekarangController.text =
        profile.tahun_jabatan_sekarang <= 0
            ? ''
            : profile.tahun_jabatan_sekarang.toString();
    final ProfileExtendedData extended =
        widget.initialExtendedData;
    _tempatLahirController.text = extended.tempatLahir;
    _tanggalLahir = extended.tanggalLahir;
    _positionHistory
      ..clear()
      ..addAll(extended.positionHistory);
    _sortPositionHistory();
    _educationHistory
      ..clear()
      ..addAll(extended.educationHistory);
    _sortEducationHistory();
    _latihanJabatanController.text = extended.latihanJabatan;
    _tahunLatihanController.text =
        extended.tahunLatihanJabatan <= 0
            ? ''
            : extended.tahunLatihanJabatan.toString();

    _jabatanSekarangController.addListener(
      _handleCurrentPositionChanged,
    );
    _tahunJabatanSekarangController.addListener(
      _handleCurrentPositionChanged,
    );
  }

  @override
  void dispose() {
    _jabatanSekarangController.removeListener(
      _handleCurrentPositionChanged,
    );
    _tahunJabatanSekarangController.removeListener(
      _handleCurrentPositionChanged,
    );
    _namaController.dispose();
    _nipController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    _statusKepegawaianController.dispose();
    _jenisAsnController.dispose();
    _pangkatController.dispose();
    _jabatanSekarangController.dispose();
    _tahunJabatanSekarangController.dispose();
    _tempatLahirController.dispose();
    _latihanJabatanController.dispose();
    _tahunLatihanController.dispose();
    _passwordBaruController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  bool get _isAsn {
    return _statusKepegawaianController.text
            .trim()
            .toLowerCase() ==
        'asn';
  }

  bool get _hasCurrentPositionChanged {
    final String currentPosition =
        _jabatanSekarangController.text.trim().toLowerCase();
    final String initialPosition = widget
        .initialProfile.jabatan_sekarang
        .trim()
        .toLowerCase();
    final int currentYear =
        _optionalYear(_tahunJabatanSekarangController);
    final int initialYear =
        widget.initialProfile.tahun_jabatan_sekarang;

    return currentPosition != initialPosition ||
        currentYear != initialYear;
  }

  void _handleCurrentPositionChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _showOptions({
    required String title,
    required List<String> options,
    required TextEditingController controller,
    VoidCallback? afterSelect,
  }) async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext sheetContext) {
        final double maxHeight =
            MediaQuery.sizeOf(sheetContext).height * 0.82;
        final double bottomPadding =
            MediaQuery.viewPaddingOf(sheetContext).bottom;
        final double desiredListHeight = options.length * 53.0;
        final double availableListHeight = maxHeight - 92;
        final double listHeight = desiredListHeight < availableListHeight
            ? desiredListHeight
            : availableListHeight;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              16 + bottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: listHeight,
                  child: Scrollbar(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: Color(0x1F000000),
                      ),
                      itemBuilder: (
                        BuildContext context,
                        int index,
                      ) {
                        final String option = options[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          title: Text(
                            option,
                            style: const TextStyle(fontSize: 15),
                          ),
                          trailing: controller.text == option
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: _accent,
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(sheetContext, option);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      controller.text = selected;
      afterSelect?.call();
    });
  }

  Future<void> _openPositionEditor({
    int? editIndex,
  }) async {
    final PositionHistoryEntry? existing = editIndex == null
        ? null
        : _positionHistory[editIndex];
    final TextEditingController positionController =
        TextEditingController(
      text: existing?.jabatan ?? '',
    );
    final TextEditingController yearController =
        TextEditingController(
      text: existing == null ? '' : existing.tahun.toString(),
    );
    String? localError;

    final PositionHistoryEntry? result =
        await showModalBottomSheet<PositionHistoryEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setSheetState,
          ) {
            final EdgeInsets viewInsets =
                MediaQuery.viewInsetsOf(context);
            final double safeBottom =
                MediaQuery.viewPaddingOf(context).bottom;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                20 + safeBottom + viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          existing == null
                              ? 'Tambah Riwayat Jabatan'
                              : 'Edit Riwayat Jabatan',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'NAMA JABATAN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    controller: positionController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _educationInputDecoration(
                      hintText: 'Masukkan nama jabatan sebelumnya',
                    ),
                    onChanged: (_) {
                      if (localError != null) {
                        setSheetState(() {
                          localError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TAHUN JABATAN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: _educationInputDecoration(
                      hintText: 'Masukkan tahun mulai menjabat',
                    ),
                    onChanged: (_) {
                      if (localError != null) {
                        setSheetState(() {
                          localError = null;
                        });
                      }
                    },
                  ),
                  if (localError != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      localError!,
                      style: const TextStyle(
                        color: Color(0xFFB3261E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: () {
                        final String position =
                            positionController.text.trim();
                        final int year = int.tryParse(
                              yearController.text.trim(),
                            ) ??
                            0;
                        final int currentYear = DateTime.now().year;

                        if (position.isEmpty ||
                            year < 1900 ||
                            year > currentYear) {
                          setSheetState(() {
                            localError =
                                'Masukkan nama jabatan dan tahun yang valid.';
                          });
                          return;
                        }

                        Navigator.pop(
                          sheetContext,
                          PositionHistoryEntry(
                            jabatan: position,
                            tahun: year,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        existing == null
                            ? 'TAMBAH JABATAN'
                            : 'SIMPAN PERUBAHAN',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    positionController.dispose();
    yearController.dispose();
    if (result == null || !mounted) return;

    final String currentPosition =
        _jabatanSekarangController.text.trim().toLowerCase();
    final int currentPositionYear =
        _optionalYear(_tahunJabatanSekarangController);
    if (result.jabatan.trim().toLowerCase() == currentPosition &&
        result.tahun == currentPositionYear) {
      await _showProfileNotification(
        title: 'Jabatan Sudah Aktif',
        message:
            'Jabatan tersebut sudah tercatat sebagai jabatan sekarang dan tidak perlu ditambahkan kembali ke riwayat.',
        type: SiapNotificationType.warning,
      );
      return;
    }

    final int duplicateIndex = _positionHistory.indexWhere(
      (PositionHistoryEntry item) =>
          item.jabatan.trim().toLowerCase() ==
              result.jabatan.trim().toLowerCase() &&
          item.tahun == result.tahun,
    );
    if (duplicateIndex >= 0 && duplicateIndex != editIndex) {
      await _showProfileNotification(
        title: 'Riwayat Jabatan Duplikat',
        message:
            '${result.jabatan} pada tahun ${result.tahun} sudah ada.',
        type: SiapNotificationType.warning,
      );
      return;
    }

    setState(() {
      if (editIndex == null) {
        _positionHistory.add(result);
      } else {
        _positionHistory[editIndex] = result;
      }
      _sortPositionHistory();
    });
  }

  void _removePosition(int index) {
    setState(() {
      _positionHistory.removeAt(index);
    });
  }

  void _sortPositionHistory() {
    _positionHistory.sort(
      (PositionHistoryEntry a, PositionHistoryEntry b) {
        final int yearCompare = b.tahun.compareTo(a.tahun);
        if (yearCompare != 0) return yearCompare;
        return a.jabatan.toLowerCase().compareTo(
              b.jabatan.toLowerCase(),
            );
      },
    );
  }

  Widget _buildPositionChangeModeSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x3D9D6A18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'JENIS PERUBAHAN JABATAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Perubahan jabatan terdeteksi. Pilih cara menyimpan data ini.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF756F65),
            ),
          ),
          const SizedBox(height: 10),
          _PositionChangeOption(
            selected: _positionChangeMode ==
                _PositionChangeMode.newPosition,
            title: 'Jabatan baru',
            description:
                'Jabatan aktif lama otomatis dipindahkan ke riwayat jabatan sebelumnya.',
            onTap: () {
              setState(() {
                _positionChangeMode =
                    _PositionChangeMode.newPosition;
              });
            },
          ),
          const SizedBox(height: 8),
          _PositionChangeOption(
            selected: _positionChangeMode ==
                _PositionChangeMode.correction,
            title: 'Koreksi data',
            description:
                'Perbaiki nama atau tahun jabatan aktif tanpa membuat riwayat baru.',
            onTap: () {
              setState(() {
                _positionChangeMode =
                    _PositionChangeMode.correction;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPositionHistoryEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_positionHistory.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 18,
            ),
            decoration: BoxDecoration(
              color: const Color(0x66FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0x3D9D6A18),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.timeline_rounded,
                  color: _accent,
                  size: 21,
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Belum ada riwayat jabatan sebelumnya. Tambahkan jabatan yang pernah dijabat beserta tahun mulai menjabat.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF6D675E),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...List<Widget>.generate(
            _positionHistory.length,
            (int index) {
              final PositionHistoryEntry item =
                  _positionHistory[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _positionHistory.length - 1
                      ? 0
                      : 10,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: const Color(0x80FFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0x3D9D6A18),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEFD1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.work_history_outlined,
                          color: _accent,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.jabatan,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _text,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Mulai menjabat ${item.tahun}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF756F65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit jabatan',
                        onPressed: () {
                          _openPositionEditor(editIndex: index);
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF35623B),
                          size: 20,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hapus jabatan',
                        onPressed: () {
                          _removePosition(index);
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFB3261E),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            _openPositionEditor();
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('TAMBAH RIWAYAT JABATAN'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _accent,
            side: const BorderSide(color: _accent),
            minimumSize: const Size.fromHeight(45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 11),
        const _HelperText(
          text:
              'Tambahkan jabatan yang pernah dijabat sebelum jabatan saat ini. Data dapat diedit atau dihapus sebelum profil disimpan.',
        ),
      ],
    );
  }

  Future<void> _openEducationEditor({
    int? editIndex,
  }) async {
    final EducationHistoryEntry? existing = editIndex == null
        ? null
        : _educationHistory[editIndex];
    final TextEditingController yearController =
        TextEditingController(
      text: existing == null ? '' : existing.tahun.toString(),
    );
    String selectedEducation = existing?.pendidikan ?? '';
    String? localError;

    final EducationHistoryEntry? result =
        await showModalBottomSheet<EducationHistoryEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setSheetState,
          ) {
            final EdgeInsets viewInsets =
                MediaQuery.viewInsetsOf(context);
            final double safeBottom =
                MediaQuery.viewPaddingOf(context).bottom;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                20 + safeBottom + viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          existing == null
                              ? 'Tambah Pendidikan'
                              : 'Edit Pendidikan',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'JENJANG PENDIDIKAN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 7),
                  DropdownButtonFormField<String>(
                    value: selectedEducation.isEmpty
                        ? null
                        : selectedEducation,
                    isExpanded: true,
                    menuMaxHeight:
                        MediaQuery.sizeOf(context).height * 0.52,
                    hint: const Text('Pilih jenjang pendidikan'),
                    decoration: _educationInputDecoration(),
                    items: _pendidikanOptions
                        .map(
                          (String option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      setSheetState(() {
                        selectedEducation = value ?? '';
                        localError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TAHUN LULUS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: _educationInputDecoration(
                      hintText: 'Masukkan tahun lulus',
                    ),
                    onChanged: (_) {
                      if (localError != null) {
                        setSheetState(() {
                          localError = null;
                        });
                      }
                    },
                  ),
                  if (localError != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      localError!,
                      style: const TextStyle(
                        color: Color(0xFFB3261E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: () {
                        final int year = int.tryParse(
                              yearController.text.trim(),
                            ) ??
                            0;
                        if (selectedEducation.isEmpty ||
                            year < 1900 ||
                            year > 2200) {
                          setSheetState(() {
                            localError =
                                'Pilih jenjang dan masukkan tahun lulus yang valid.';
                          });
                          return;
                        }

                        Navigator.pop(
                          sheetContext,
                          EducationHistoryEntry(
                            pendidikan: selectedEducation,
                            tahun: year,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        existing == null
                            ? 'TAMBAH PENDIDIKAN'
                            : 'SIMPAN PERUBAHAN',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    yearController.dispose();
    if (result == null || !mounted) return;

    final int duplicateIndex = _educationHistory.indexWhere(
      (EducationHistoryEntry item) =>
          item.pendidikan.trim().toLowerCase() ==
          result.pendidikan.trim().toLowerCase(),
    );
    if (duplicateIndex >= 0 && duplicateIndex != editIndex) {
      _showMessage(
        'Jenjang ${result.pendidikan} sudah ada. Edit data yang sudah tersimpan agar tidak duplikat.',
        isError: true,
        title: 'Pendidikan Duplikat',
      );
      return;
    }

    setState(() {
      if (editIndex == null) {
        _educationHistory.add(result);
      } else {
        _educationHistory[editIndex] = result;
      }
      _sortEducationHistory();
    });
  }

  void _removeEducation(int index) {
    setState(() {
      _educationHistory.removeAt(index);
    });
  }

  void _sortEducationHistory() {
    _educationHistory.sort(
      (EducationHistoryEntry a, EducationHistoryEntry b) {
        final int yearCompare = b.tahun.compareTo(a.tahun);
        if (yearCompare != 0) return yearCompare;
        return _educationRank(b.pendidikan).compareTo(
          _educationRank(a.pendidikan),
        );
      },
    );
  }

  int _educationRank(String value) {
    final int index = _pendidikanOptions.indexWhere(
      (String option) =>
          option.toLowerCase() == value.trim().toLowerCase(),
    );
    return index < 0 ? 0 : index + 1;
  }

  Widget _buildEducationHistoryEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_educationHistory.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 18,
            ),
            decoration: BoxDecoration(
              color: const Color(0x66FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0x3D9D6A18),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.school_outlined,
                  color: _accent,
                  size: 21,
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Belum ada riwayat pendidikan. Tambahkan pendidikan dari SD sampai jenjang tertinggi yang pernah ditempuh.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF6D675E),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...List<Widget>.generate(
            _educationHistory.length,
            (int index) {
              final EducationHistoryEntry item =
                  _educationHistory[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _educationHistory.length - 1
                      ? 0
                      : 10,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: const Color(0x80FFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0x3D9D6A18),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEFD1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: _accent,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.pendidikan,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _text,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Lulus ${item.tahun}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF756F65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit pendidikan',
                        onPressed: () {
                          _openEducationEditor(editIndex: index);
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF35623B),
                          size: 20,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hapus pendidikan',
                        onPressed: () {
                          _removeEducation(index);
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFB3261E),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            _openEducationEditor();
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('TAMBAH PENDIDIKAN'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _accent,
            side: const BorderSide(color: _accent),
            minimumSize: const Size.fromHeight(45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 11),
        const _HelperText(
          text:
              'Tambahkan seluruh riwayat pendidikan dalam satu kali edit. Pendidikan terakhir akan ditentukan otomatis dari data dengan tahun lulus terbaru.',
        ),
      ],
    );
  }

  static InputDecoration _educationInputDecoration({
    String? hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Color(0xFFCBC8C0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Color(0xFFCBC8C0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: _accent,
          width: 1.4,
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(1940);
    DateTime initial = _tanggalLahir ?? DateTime(1990);
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(now)) initial = now;

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: now,
      helpText: 'Pilih tanggal lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _accent,
              onPrimary: Colors.white,
              surface: _card,
              onSurface: _text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() {
      _tanggalLahir = selected;
    });
  }

  Future<void> _showProfileNotification({
    required String title,
    required String message,
    required SiapNotificationType type,
  }) async {
    if (!mounted) return;

    await Future<void>.delayed(
      const Duration(milliseconds: 160),
    );
    if (!mounted) return;

    await showSiapTopNotification(
      context: context,
      title: title,
      message: message,
      type: type,
    );
  }

  Future<void> _pickProfilePhoto() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final PlatformFile selected = result.files.single;
    final Uint8List? bytes = selected.bytes;

    if (bytes == null || bytes.isEmpty) {
      await _showProfileNotification(
        title: 'Foto Tidak Dapat Dibaca',
        message:
            'File foto tidak dapat dibaca. Silakan pilih foto lain.',
        type: SiapNotificationType.error,
      );
      return;
    }

    if (bytes.length > ProfilePhotoService.maxPhotoBytes) {
      await _showProfileNotification(
        title: 'Ukuran Foto Terlalu Besar',
        message:
            'Foto yang dipilih memiliki ukuran lebih dari 2 MB. Silakan perkecil ukuran file atau gunakan kompresor foto online.',
        type: SiapNotificationType.error,
      );
      return;
    }

    String extension = (selected.extension ?? '').toLowerCase();
    if (extension.isEmpty && selected.name.contains('.')) {
      extension = selected.name.split('.').last.toLowerCase();
    }

    if (!<String>{'jpg', 'jpeg', 'png', 'webp'}
        .contains(extension)) {
      await _showProfileNotification(
        title: 'Format Foto Tidak Didukung',
        message: 'Foto harus berformat JPG, JPEG, PNG, atau WEBP.',
        type: SiapNotificationType.error,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _selectedPhotoBytes = bytes;
      _selectedPhotoName = selected.name;
      _removePhoto = false;
    });
  }

  void _removeProfilePhoto() {
    final bool hasExistingPhoto =
        widget.initialProfile.foto_profil.trim().isNotEmpty ||
        widget.initialPhotoUrl.trim().isNotEmpty ||
        _selectedPhotoBytes != null;

    if (!hasExistingPhoto) return;

    setState(() {
      _selectedPhotoBytes = null;
      _selectedPhotoName = '';
      _removePhoto = true;
    });
  }

  int _optionalYear(TextEditingController controller) {
    final String value = controller.text.trim();
    if (value.isEmpty) return 0;
    return int.tryParse(value) ?? 0;
  }

  bool _validateOptionalPairs() {
    final String birthPlace = _tempatLahirController.text.trim();
    if (birthPlace.isEmpty != (_tanggalLahir == null)) {
      _showMessage(
        'Tempat dan tanggal lahir harus diisi bersama-sama.',
        isError: true,
      );
      return false;
    }

    final String rawTraining =
        _latihanJabatanController.text.trim();
    final String normalizedTraining =
        _normalizeTrainingInput(rawTraining);
    final int trainingYear = _optionalYear(_tahunLatihanController);

    if (normalizedTraining.isEmpty && rawTraining.isNotEmpty) {
      _latihanJabatanController.clear();
      _tahunLatihanController.clear();
    } else if ((normalizedTraining.isEmpty && trainingYear > 0) ||
        (normalizedTraining.isNotEmpty && trainingYear == 0)) {
      _showMessage(
        'Nama diklat dan tahun diklat harus diisi bersama-sama, '
        'atau kosongkan kedua kolom jika belum pernah mengikuti diklat.',
        isError: true,
      );
      return false;
    }

    return true;
  }

  String _normalizeTrainingInput(String value) {
    final String clean = value.trim();
    final String lower = clean.toLowerCase();
    if (lower.isEmpty ||
        lower == '-' ||
        lower == 'tidak ada' ||
        lower == 'belum ada') {
      return '';
    }
    return clean;
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showMessage(
        'Lengkapi seluruh data wajib terlebih dahulu.',
        isError: true,
      );
      return;
    }

    final List<String> missingProfileSections = <String>[];
    if (_tanggalLahir == null) {
      missingProfileSections.add('tanggal lahir');
    }
    if (_positionHistory.isEmpty) {
      missingProfileSections.add('riwayat jabatan sebelumnya');
    }
    if (_educationHistory.isEmpty) {
      missingProfileSections.add('riwayat pendidikan');
    }

    if (missingProfileSections.isNotEmpty) {
      setState(() {
        _kepegawaianExpanded = true;
        if (_positionHistory.isEmpty) {
          _riwayatJabatanExpanded = true;
        }
        if (_educationHistory.isEmpty) {
          _pendidikanExpanded = true;
        }
      });
      _showMessage(
        'Lengkapi ${missingProfileSections.join(', ')} terlebih dahulu.',
        isError: true,
        title: 'Profil Belum Lengkap',
      );
      return;
    }

    if (!_validateOptionalPairs()) return;

    final bool confirmed = await _showConfirmDialog();
    if (!confirmed || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    String nextPhotoPath = widget.initialProfile.foto_profil;
    String? uploadedPhotoPath;

    try {
      if (_selectedPhotoBytes != null) {
        uploadedPhotoPath =
            await ProfilePhotoService.instance.uploadPhoto(
          uid: widget.initialUser.uid,
          bytes: _selectedPhotoBytes!,
          originalFileName: _selectedPhotoName,
        );
        nextPhotoPath = uploadedPhotoPath;
      } else if (_removePhoto) {
        nextPhotoPath = '';
      }

      final AccountUpdateResult accountResult =
          await ProfileAccountService.instance.updateAccount(
        uid: widget.initialUser.uid,
        oldUsername: widget.initialUser.username,
        oldEmail: widget.initialUser.email,
        username: _usernameController.text,
        email: _emailController.text,
        newPassword: _passwordBaruController.text,
        confirmPassword: _konfirmasiPasswordController.text,
      );

      await ProfileService.instance.updateEmploymentProfile(
        uid: widget.initialUser.uid,
        namaLengkap: _namaController.text,
        nip: _nipController.text,
        noTelepon: _teleponController.text,
        statusKepegawaian:
            _statusKepegawaianController.text,
        jenisAsn: _isAsn ? _jenisAsnController.text : '',
        pangkat: _pangkatController.text,
        tempatLahir: _tempatLahirController.text,
        tanggalLahir: _tanggalLahir,
        jabatanSekarang: _jabatanSekarangController.text,
        tahunJabatanSekarang:
            _optionalYear(_tahunJabatanSekarangController),
        positionHistory: List<PositionHistoryEntry>.unmodifiable(
          _positionHistory,
        ),
        movePreviousPositionToHistory:
            _hasCurrentPositionChanged &&
            _positionChangeMode ==
                _PositionChangeMode.newPosition,
        educationHistory: List<EducationHistoryEntry>.unmodifiable(
          _educationHistory,
        ),
        latihanJabatan: _normalizeTrainingInput(
          _latihanJabatanController.text,
        ),
        tahunLatihanJabatan:
            _optionalYear(_tahunLatihanController),
        fotoProfil: nextPhotoPath,
      );

      final String oldPhotoPath =
          widget.initialProfile.foto_profil.trim();
      if (oldPhotoPath.isNotEmpty &&
          oldPhotoPath != nextPhotoPath) {
        try {
          await ProfilePhotoService.instance
              .deletePhoto(oldPhotoPath);
        } catch (_) {
          // Data profil tetap tersimpan walau file lama gagal dibersihkan.
        }
      }

      if (!mounted) return;

      if (accountResult.verificationEmailSent) {
        await showSiapTopNotification(
          context: context,
          title: 'Verifikasi Email Dikirim',
          message:
              'Link verifikasi telah dikirim ke ${_emailController.text.trim()}. '
              'Periksa Kotak Masuk dan folder Spam. Setelah email berhasil '
              'diverifikasi, kembali ke aplikasi untuk login ulang menggunakan '
              'alamat email baru.',
          type: SiapNotificationType.information,
          primaryButtonLabel: 'MENGERTI',
        );
      } else {
        String successMessage = 'Profil berhasil diperbarui.';
        if (accountResult.passwordChanged) {
          successMessage =
              'Profil dan kata sandi berhasil diperbarui.';
        }
        await _showSuccessDialog(successMessage);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ProfileAccountException catch (error) {
      if (uploadedPhotoPath != null) {
        try {
          await ProfilePhotoService.instance
              .deletePhoto(uploadedPhotoPath);
        } catch (_) {}
      }
      if (!mounted) return;
      final bool requiresRecentLogin =
          error.code == 'requires-recent-login';
      _showMessage(
        error.message,
        isError: !requiresRecentLogin,
        isWarning: requiresRecentLogin,
        title: requiresRecentLogin
            ? 'Sesi Login Perlu Diperbarui'
            : 'Perubahan Gagal',
      );
    } on ProfileServiceException catch (error) {
      if (uploadedPhotoPath != null) {
        try {
          await ProfilePhotoService.instance
              .deletePhoto(uploadedPhotoPath);
        } catch (_) {}
      }
      if (!mounted) return;
      _showMessage(error.message, isError: true);
    } on ProfilePhotoException catch (error) {
      if (!mounted) return;
      final bool isOversized = error.message.contains('2 MB');
      _showMessage(
        error.message,
        isError: true,
        title: isOversized
            ? 'Ukuran Foto Terlalu Besar'
            : 'Unggah Foto Gagal',
      );
    } catch (_) {
      if (uploadedPhotoPath != null) {
        try {
          await ProfilePhotoService.instance
              .deletePhoto(uploadedPhotoPath);
        } catch (_) {}
      }
      if (!mounted) return;
      _showMessage(
        'Gagal memperbarui profil. Silakan coba kembali.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: false,
          barrierLabel: 'Konfirmasi simpan profil',
          barrierColor: Colors.black.withOpacity(0.46),
          transitionDuration:
              const Duration(milliseconds: 220),
          pageBuilder: (_, _, _) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width:
                      MediaQuery.sizeOf(context).width * 0.76,
                  padding:
                      const EdgeInsets.fromLTRB(24, 22, 24, 22),
                  decoration: BoxDecoration(
                    color: _card,
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
                          Icons.edit_rounded,
                          color: Color(0xFFF08A00),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Simpan perubahan profil?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context, false);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _text,
                                side: const BorderSide(
                                  color: Color(0xFFE19000),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(11),
                                ),
                              ),
                              child: const Text('BATAL'),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFEA8C00),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(11),
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
          transitionBuilder: (
            _,
            Animation<double> animation,
            _,
            Widget child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.92,
                  end: 1,
                ).animate(animation),
                child: child,
              ),
            );
          },
        ) ??
        false;
  }

  Future<void> _showSuccessDialog(String message) async {
    final Future<void> dialogFuture = showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Profil berhasil diperbarui',
      barrierColor: Colors.black.withOpacity(0.46),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.72,
              padding:
                  const EdgeInsets.fromLTRB(24, 22, 24, 20),
              decoration: BoxDecoration(
                color: _card,
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
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFE9F7DD),
                    child: Icon(
                      Icons.task_alt_rounded,
                      color: Color(0xFF31801E),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 720),
    );

    if (mounted) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();
    }

    await dialogFuture;
  }

  void _showMessage(
    String message, {
    bool isError = false,
    bool isWarning = false,
    String? title,
  }) {
    if (!mounted) {
      return;
    }

    final SiapNotificationType type = isWarning
        ? SiapNotificationType.warning
        : isError
            ? SiapNotificationType.error
            : SiapNotificationType.information;

    unawaited(
      showSiapTopNotification(
        context: context,
        title: title ??
            (isWarning
                ? 'Perhatian'
                : isError
                    ? 'Periksa Kembali'
                    : 'Informasi'),
        message: message,
        type: type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight =
        MediaQuery.viewPaddingOf(context).top;
    final double systemBottom =
        MediaQuery.viewPaddingOf(context).bottom;
    final double keyboardBottom =
        MediaQuery.viewInsetsOf(context).bottom;
    final double stickySaveBottom = keyboardBottom > 0
        ? keyboardBottom + 12
        : systemBottom + 102;

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
            Form(
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
                    delegate: _EditProfileHeaderDelegate(
                      statusBarHeight: statusBarHeight,
                      onBack: () {
                        Navigator.of(context).pop(false);
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _EditIdentityCard(
                      user: widget.initialUser,
                      profile: widget.initialProfile,
                      initialPhotoUrl: widget.initialPhotoUrl,
                      selectedPhotoBytes: _selectedPhotoBytes,
                      removePhoto: _removePhoto,
                      onPickPhoto: _pickProfilePhoto,
                      onRemovePhoto: _removeProfilePhoto,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      6,
                      18,
                      190,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(<Widget>[
                        _EditSection(
                          title: 'DATA PEGAWAI',
                          icon: Icons.badge_outlined,
                          expanded: _profilExpanded,
                          onToggle: () {
                            setState(() {
                              _profilExpanded = !_profilExpanded;
                            });
                          },
                          children: <Widget>[
                            _EditTextField(
                              label: 'NAMA PEGAWAI',
                              hint: 'Masukkan nama pegawai',
                              controller: _namaController,
                            ),
                            _EditTextField(
                              label: 'NIP',
                              hint: 'Masukkan NIP',
                              controller: _nipController,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                            _EditTextField(
                              label: 'NOMOR TELEPON',
                              hint: 'Masukkan nomor telepon',
                              controller: _teleponController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _EditSection(
                          title: 'INFORMASI KEPEGAWAIAN',
                          icon: Icons.work_outline_rounded,
                          expanded: _kepegawaianExpanded,
                          onToggle: () {
                            setState(() {
                              _kepegawaianExpanded =
                                  !_kepegawaianExpanded;
                            });
                          },
                          children: <Widget>[
                            _EditDropdownField(
                              label: 'STATUS KEPEGAWAIAN',
                              hint: 'Pilih status kepegawaian',
                              controller:
                                  _statusKepegawaianController,
                              onOpen: () => _showOptions(
                                title: 'Pilih Status Kepegawaian',
                                options: _statusKepegawaianOptions,
                                controller:
                                    _statusKepegawaianController,
                                afterSelect: () {
                                  if (!_isAsn) {
                                    _jenisAsnController.clear();
                                  }
                                },
                              ),
                            ),
                            if (_isAsn)
                              _EditDropdownField(
                                label: 'JENIS ASN',
                                hint: 'Pilih jenis ASN',
                                controller: _jenisAsnController,
                                onOpen: () => _showOptions(
                                  title: 'Pilih Jenis ASN',
                                  options: _jenisAsnOptions,
                                  controller: _jenisAsnController,
                                ),
                              ),
                            _EditTextField(
                              label: 'PANGKAT',
                              hint: 'Masukkan pangkat',
                              controller: _pangkatController,
                            ),
                            _EditTextField(
                              label: 'TEMPAT LAHIR',
                              hint: 'Masukkan tempat lahir',
                              controller: _tempatLahirController,
                            ),
                            _EditDateField(
                              label: 'TANGGAL LAHIR',
                              date: _tanggalLahir,
                              onTap: _pickBirthDate,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _EditSection(
                          title: 'JABATAN SEKARANG',
                          icon: Icons.account_tree_outlined,
                          expanded: _jabatanSekarangExpanded,
                          onToggle: () {
                            setState(() {
                              _jabatanSekarangExpanded =
                                  !_jabatanSekarangExpanded;
                            });
                          },
                          children: <Widget>[
                            _EditTextField(
                              label: 'JABATAN SEKARANG',
                              hint: 'Masukkan jabatan sekarang',
                              controller: _jabatanSekarangController,
                            ),
                            _EditYearField(
                              label: 'TAHUN JABATAN SEKARANG',
                              controller:
                                  _tahunJabatanSekarangController,
                            ),
                            const _HelperText(
                              text:
                                  'Isi jabatan yang sedang aktif beserta tahun mulai menjabat. Jabatan sebelumnya dapat ditambahkan atau diperbaiki pada bagian Riwayat Jabatan.',
                            ),
                            if (_hasCurrentPositionChanged)
                              _buildPositionChangeModeSelector(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _EditSection(
                          title: 'RIWAYAT JABATAN',
                          icon: Icons.timeline_rounded,
                          expanded: _riwayatJabatanExpanded,
                          onToggle: () {
                            setState(() {
                              _riwayatJabatanExpanded =
                                  !_riwayatJabatanExpanded;
                            });
                          },
                          children: <Widget>[
                            _buildPositionHistoryEditor(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _EditSection(
                          title: 'RIWAYAT PENDIDIKAN',
                          icon: Icons.school_outlined,
                          expanded: _pendidikanExpanded,
                          onToggle: () {
                            setState(() {
                              _pendidikanExpanded =
                                  !_pendidikanExpanded;
                            });
                          },
                          children: <Widget>[
                            _buildEducationHistoryEditor(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _EditSection(
                          title: 'DIKLAT TERAKHIR',
                          icon: Icons.workspace_premium_outlined,
                          expanded: _diklatExpanded,
                          onToggle: () {
                            setState(() {
                              _diklatExpanded = !_diklatExpanded;
                            });
                          },
                          children: <Widget>[
                            _EditTextField(
                              label: 'NAMA DIKLAT / LATIHAN JABATAN',
                              hint: 'Masukkan nama diklat terakhir',
                              controller: _latihanJabatanController,
                              requiredField: false,
                            ),
                            _EditYearField(
                              label: 'TAHUN DIKLAT',
                              controller: _tahunLatihanController,
                              requiredField: false,
                            ),
                            const _HelperText(
                              text:
                                  'Kosongkan kedua kolom jika belum pernah mengikuti diklat. Input “-” atau “Tidak ada” akan dianggap sebagai data kosong.',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _EditSection(
                          title: 'EDIT AKUN',
                          icon: Icons.manage_accounts_outlined,
                          expanded: _akunExpanded,
                          onToggle: () {
                            setState(() {
                              _akunExpanded = !_akunExpanded;
                            });
                          },
                          children: <Widget>[
                            _EditTextField(
                              label: 'USERNAME',
                              hint: 'Masukkan username',
                              controller: _usernameController,
                            ),
                            _EditTextField(
                              label: 'EMAIL',
                              hint: 'Masukkan email baru',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _EditTextField(
                              label: 'KATA SANDI BARU',
                              hint:
                                  'Kosongkan jika tidak ingin mengganti',
                              controller: _passwordBaruController,
                              requiredField: false,
                              obscureText: true,
                              validator: (String? value) {
                                final String clean =
                                    value?.trim() ?? '';
                                if (clean.isNotEmpty &&
                                    clean.length < 6) {
                                  return 'Minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            _EditTextField(
                              label: 'KONFIRMASI SANDI BARU',
                              hint: 'Ulangi kata sandi baru',
                              controller:
                                  _konfirmasiPasswordController,
                              requiredField: false,
                              obscureText: true,
                              validator: (String? value) {
                                if (_passwordBaruController.text
                                        .trim()
                                        .isEmpty &&
                                    (value?.trim().isEmpty ?? true)) {
                                  return null;
                                }
                                if (value !=
                                    _passwordBaruController.text) {
                                  return 'Konfirmasi tidak sama';
                                }
                                return null;
                              },
                            ),
                            const _HelperText(
                              text:
                                  'Perubahan email memerlukan verifikasi melalui email baru. Role dan status akun hanya dapat diubah oleh admin.',
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: stickySaveBottom,
              child: Material(
                color: Colors.transparent,
                elevation: 8,
                shadowColor: const Color(0x55000000),
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.save_outlined,
                            size: 21,
                          ),
                    label: Text(
                      _isSaving
                          ? 'MENYIMPAN...'
                          : 'SIMPAN PERUBAHAN',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      disabledBackgroundColor:
                          _accent.withOpacity(0.65),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SiapPageBottomNavigationBar(
          selectedIndex: 2,
          isAdmin: widget.initialUser.role
                  .trim()
                  .toLowerCase() ==
              'admin',
          showBackgroundLayer: true,
        ),
      ),
    );
  }
}

class _EditProfileHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  final double statusBarHeight;
  final VoidCallback onBack;

  const _EditProfileHeaderDelegate({
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
        : (shrinkOffset / collapseDistance)
            .clamp(0.0, 1.0);

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
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(10, 2, 18, 2),
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
                      'Edit Profil',
                      style: TextStyle(
                        fontSize: 22,
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
  bool shouldRebuild(
    covariant _EditProfileHeaderDelegate oldDelegate,
  ) {
    return oldDelegate.statusBarHeight != statusBarHeight ||
        oldDelegate.onBack != onBack;
  }
}

class _EditIdentityCard extends StatelessWidget {
  final UsersModel user;
  final ProfilePegawaiModel profile;
  final String initialPhotoUrl;
  final Uint8List? selectedPhotoBytes;
  final bool removePhoto;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  const _EditIdentityCard({
    required this.user,
    required this.profile,
    required this.initialPhotoUrl,
    required this.selectedPhotoBytes,
    required this.removePhoto,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasNetworkPhoto =
        !removePhoto && initialPhotoUrl.trim().startsWith('http');
    final bool hasPhoto =
        selectedPhotoBytes != null || hasNetworkPhoto;

    final ImageProvider? imageProvider =
        selectedPhotoBytes != null
            ? MemoryImage(selectedPhotoBytes!)
            : hasNetworkPhoto
                ? NetworkImage(initialPhotoUrl.trim())
                : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
        decoration: BoxDecoration(
          color: const Color(0xF5FFFCF5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0x78FFFFFF),
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x2E000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 43,
                  backgroundColor: const Color(0xFFEAD8B2),
                  foregroundImage: imageProvider,
                  child: imageProvider == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: Color(0xFF9D6A18),
                        )
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIP: ${user.nip.trim().isEmpty ? '-' : user.nip.trim()}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickPhoto,
                    icon: Icon(
                      hasPhoto
                          ? Icons.photo_library_outlined
                          : Icons.add_a_photo_outlined,
                      size: 18,
                    ),
                    label: Text(
                      hasPhoto ? 'GANTI FOTO' : 'TAMBAH FOTO',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9D6A18),
                      side: const BorderSide(
                        color: Color(0xFF9D6A18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasPhoto ? onRemovePhoto : null,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('HAPUS FOTO'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC62828),
                      side: const BorderSide(
                        color: Color(0xFFC62828),
                      ),
                      disabledForegroundColor:
                          const Color(0xFFAAA69E),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionChangeOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _PositionChangeOption({
    required this.selected,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFEFD1)
                : const Color(0x4DFFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFF9D6A18)
                  : const Color(0x339D6A18),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: const Color(0xFF9D6A18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF292929),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: Color(0xFF6D675E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _EditSection({
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
              padding:
                  const EdgeInsets.fromLTRB(11, 9, 10, 9),
              child: Row(
                children: <Widget>[
                  Icon(
                    icon,
                    size: 17,
                    color: const Color(0xFF9A6410),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4E4E4E),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration:
                        const Duration(milliseconds: 180),
                    turns: expanded ? 0 : 0.5,
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...<Widget>[
            const Divider(
              height: 1,
              color: Color(0xFFE6E1D7),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(11, 12, 11, 12),
              child: Column(children: children),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool readOnly;
  final bool requiredField;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  const _EditTextField({
    required this.label,
    required this.hint,
    required this.controller,
    // ignore: unused_element_parameter
    this.readOnly = false,
    this.requiredField = true,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            obscureText: obscureText,
            enableSuggestions: !obscureText,
            autocorrect: !obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: const TextStyle(fontSize: 13),
            validator: (String? value) {
              if (requiredField &&
                  (value == null || value.trim().isEmpty)) {
                return 'Wajib diisi';
              }
              return validator?.call(value);
            },
            decoration: _editFieldDecoration(
              hint,
              readOnly: readOnly,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditYearField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool requiredField;

  const _EditYearField({
    required this.label,
    required this.controller,
    this.requiredField = true,
  });

  @override
  Widget build(BuildContext context) {
    return _EditTextField(
      label: label,
      hint: 'Masukkan tahun',
      controller: controller,
      requiredField: requiredField,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      validator: (String? value) {
        final String clean = value?.trim() ?? '';
        if (clean.isEmpty && !requiredField) return null;
        final int? year = int.tryParse(clean);
        if (year == null || year < 1900 || year > 2200) {
          return 'Tahun tidak valid';
        }
        return null;
      },
    );
  }
}

class _EditDateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _EditDateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String value = date == null
        ? 'Pilih tanggal lahir'
        : '${date!.day.toString().padLeft(2, '0')}/'
            '${date!.month.toString().padLeft(2, '0')}/'
            '${date!.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: InputDecorator(
              decoration: _editFieldDecoration(
                'Pilih tanggal lahir',
              ).copyWith(
                prefixIcon: const Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: date == null
                      ? const Color(0xFF929292)
                      : const Color(0xFF191919),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onOpen;
  final bool requiredField;

  const _EditDropdownField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onOpen,
    // ignore: unused_element_parameter
    this.requiredField = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            readOnly: true,
            showCursor: false,
            onTap: onOpen,
            style: const TextStyle(fontSize: 13),
            validator: (String? value) {
              if (requiredField &&
                  (value == null || value.trim().isEmpty)) {
                return 'Wajib diisi';
              }
              return null;
            },
            decoration: _editFieldDecoration(hint).copyWith(
              suffixIcon: IconButton(
                tooltip: 'Buka pilihan',
                onPressed: onOpen,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelperText extends StatelessWidget {
  final String text;

  const _HelperText({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 0, 1, 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFF8A651A),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: Color(0xFF756F65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _editFieldDecoration(
  String hint, {
  bool readOnly = false,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontSize: 11.5,
      color: Color(0xFF929292),
    ),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 11,
    ),
    filled: true,
    fillColor: readOnly
        ? const Color(0xFFF0EEE8)
        : const Color(0xFFFEFEFC),
    errorStyle: const TextStyle(
      fontSize: 10,
      height: 1,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide:
          const BorderSide(color: Color(0xFFD6D3CC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide:
          const BorderSide(color: Color(0xFFD6D3CC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: Color(0xFF9D6A18),
        width: 1.2,
      ),
    ),
  );
}
