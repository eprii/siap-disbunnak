import 'dart:async';
import 'dart:io';

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
  final TextEditingController _pendidikanController =
      TextEditingController();
  final TextEditingController _tahunPendidikanController =
      TextEditingController();
  final TextEditingController _latihanJabatanController =
      TextEditingController();
  final TextEditingController _tahunLatihanController =
      TextEditingController();
  final TextEditingController _passwordBaruController =
      TextEditingController();
  final TextEditingController _konfirmasiPasswordController =
      TextEditingController();

  File? _selectedPhoto;
  DateTime? _tanggalLahir;
  bool _removePhoto = false;

  bool _profilExpanded = true;
  bool _kepegawaianExpanded = true;
  bool _jabatanSekarangExpanded = true;
  bool _pendidikanExpanded = true;
  bool _diklatExpanded = true;
  bool _akunExpanded = true;
  bool _isSaving = false;

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
    _pendidikanController.text = extended.pendidikan;
    _tahunPendidikanController.text =
        extended.tahunLulusPendidikan <= 0
            ? ''
            : extended.tahunLulusPendidikan.toString();
    _latihanJabatanController.text = extended.latihanJabatan;
    _tahunLatihanController.text =
        extended.tahunLatihanJabatan <= 0
            ? ''
            : extended.tahunLatihanJabatan.toString();
  }

  @override
  void dispose() {
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
    _pendidikanController.dispose();
    _tahunPendidikanController.dispose();
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

  Future<void> _showOptions({
    required String title,
    required List<String> options,
    required TextEditingController controller,
    VoidCallback? afterSelect,
  }) async {
    final String? selected =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              20,
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
                ...options.map(
                  (String option) => ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4),
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

  Future<void> _pickProfilePhoto() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final PlatformFile selected = result.files.single;
    final String? path = selected.path;
    if (path == null || path.trim().isEmpty) {
      _showMessage(
        'File foto tidak dapat dibaca pada perangkat ini.',
        isError: true,
      );
      return;
    }

    const int maxBytes = 5 * 1024 * 1024;
    if (selected.size > maxBytes) {
      _showMessage(
        'Ukuran foto profil maksimal 5 MB.',
        isError: true,
      );
      return;
    }

    final String extension =
        (selected.extension ?? '').toLowerCase();
    if (!<String>{'jpg', 'jpeg', 'png', 'webp'}
        .contains(extension)) {
      _showMessage(
        'Foto harus berformat JPG, JPEG, PNG, atau WEBP.',
        isError: true,
      );
      return;
    }

    setState(() {
      _selectedPhoto = File(path);
      _removePhoto = false;
    });
  }

  void _removeProfilePhoto() {
    final bool hasExistingPhoto =
        widget.initialProfile.foto_profil.trim().isNotEmpty ||
        widget.initialPhotoUrl.trim().isNotEmpty ||
        _selectedPhoto != null;

    if (!hasExistingPhoto) return;

    setState(() {
      _selectedPhoto = null;
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

    final String education = _pendidikanController.text.trim();
    final int educationYear =
        _optionalYear(_tahunPendidikanController);
    if ((education.isEmpty && educationYear > 0) ||
        (education.isNotEmpty && educationYear == 0)) {
      _showMessage(
        'Pendidikan terakhir dan tahun lulus harus diisi bersama-sama.',
        isError: true,
      );
      return false;
    }

    final String training = _latihanJabatanController.text.trim();
    final int trainingYear = _optionalYear(_tahunLatihanController);
    if ((training.isEmpty && trainingYear > 0) ||
        (training.isNotEmpty && trainingYear == 0)) {
      _showMessage(
        'Nama diklat dan tahun diklat harus diisi bersama-sama.',
        isError: true,
      );
      return false;
    }

    return true;
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

    if (!_validateOptionalPairs()) return;

    final bool confirmed = await _showConfirmDialog();
    if (!confirmed || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    String nextPhotoPath = widget.initialProfile.foto_profil;
    String? uploadedPhotoPath;

    try {
      if (_selectedPhoto != null) {
        uploadedPhotoPath =
            await ProfilePhotoService.instance.uploadPhoto(
          uid: widget.initialUser.uid,
          file: _selectedPhoto!,
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
        pendidikan: _pendidikanController.text,
        tahunLulusPendidikan:
            _optionalYear(_tahunPendidikanController),
        latihanJabatan: _latihanJabatanController.text,
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
      _showMessage(error.message, isError: true);
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
                      selectedPhoto: _selectedPhoto,
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
                      130,
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
                              requiredField: false,
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
                          ],
                        ),
                        const SizedBox(height: 14),
                        _EditSection(
                          title: 'PENDIDIKAN TERAKHIR',
                          icon: Icons.school_outlined,
                          expanded: _pendidikanExpanded,
                          onToggle: () {
                            setState(() {
                              _pendidikanExpanded =
                                  !_pendidikanExpanded;
                            });
                          },
                          children: <Widget>[
                            _EditDropdownField(
                              label: 'PENDIDIKAN TERAKHIR',
                              hint: 'Pilih pendidikan terakhir',
                              controller: _pendidikanController,
                              requiredField: false,
                              onOpen: () => _showOptions(
                                title: 'Pilih Pendidikan Terakhir',
                                options: _pendidikanOptions,
                                controller: _pendidikanController,
                              ),
                            ),
                            _EditYearField(
                              label: 'TAHUN LULUS PENDIDIKAN',
                              controller: _tahunPendidikanController,
                              requiredField: false,
                            ),
                            const _HelperText(
                              text:
                                  'Pendidikan lama otomatis tetap tersimpan saat pendidikan terakhir diganti.',
                            ),
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
                                  'Diklat lama otomatis tetap tersimpan saat data diklat terakhir diganti.',
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
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 47,
                          child: FilledButton.icon(
                            onPressed:
                                _isSaving ? null : _saveProfile,
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
                                borderRadius: BorderRadius.circular(7),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
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
  final File? selectedPhoto;
  final bool removePhoto;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  const _EditIdentityCard({
    required this.user,
    required this.profile,
    required this.initialPhotoUrl,
    required this.selectedPhoto,
    required this.removePhoto,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasNetworkPhoto =
        !removePhoto && initialPhotoUrl.trim().startsWith('http');
    final bool hasPhoto = selectedPhoto != null || hasNetworkPhoto;

    final ImageProvider? imageProvider = selectedPhoto != null
        ? FileImage(selectedPhoto!)
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
