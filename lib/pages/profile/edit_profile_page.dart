import 'package:flutter/material.dart';

import '../../models/profilepegawai_model.dart';
import '../../models/users_model.dart';

class EditProfilePage extends StatefulWidget {
  final UsersModel user;
  final ProfilePegawaiModel profile;

  const EditProfilePage({
    super.key,
    required this.user,
    required this.profile,
  });

  @override
  State<EditProfilePage> createState() =>
      _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color _primaryColor = Color(0xFF46532E);
  static const Color _backgroundColor = Color(0xFFB7C79E);
  static const Color _headerColor = Color(0xFFF5F2E9);
  static const Color _formColor = Color(0xFFF1EFE6);

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _usernameController;
  late final TextEditingController _nipController;
  late final TextEditingController _emailController;
  late final TextEditingController _teleponController;

  late final TextEditingController _pangkatController;
  late final TextEditingController _jabatanSekarangController;
  late final TextEditingController _tahunJabatanController;
  late final TextEditingController _jabatanSebelumnyaController;
  late final TextEditingController
      _tahunJabatanSebelumnyaController;

  late final TextEditingController _pendidikanController;
  late final TextEditingController _tahunLulusController;
  late final TextEditingController _diklatController;
  late final TextEditingController _tahunDiklatController;

  @override
  void initState() {
    super.initState();

    _namaController = TextEditingController(
      text: widget.user.nama_lengkap,
    );

    _usernameController = TextEditingController(
      text: widget.user.username,
    );

    _nipController = TextEditingController(
      text: widget.user.nip,
    );

    _emailController = TextEditingController(
      text: widget.user.email,
    );

    _teleponController = TextEditingController(
      text: widget.user.no_telepon,
    );

    _pangkatController = TextEditingController(
      text: widget.profile.pangkat,
    );

    _jabatanSekarangController = TextEditingController(
      text: widget.profile.jabatan_sekarang,
    );

    _tahunJabatanController = TextEditingController(
      text: widget.profile.tahun_jabatan_sekarang,
    );

    _jabatanSebelumnyaController = TextEditingController(
      text: widget.profile.jabatan_sebelumnya,
    );

    _tahunJabatanSebelumnyaController =
        TextEditingController(
      text: widget.profile.tahun_jabatan_sebelumnya,
    );

    _pendidikanController = TextEditingController(
      text: widget.profile.pendidikan,
    );

    _tahunLulusController = TextEditingController(
      text: widget.profile.tahun_lulus_pendidikan,
    );

    _diklatController = TextEditingController(
      text: widget.profile.latihan_jabatan,
    );

    _tahunDiklatController = TextEditingController(
      text: widget.profile.tahun_latihan_jabatan,
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    _teleponController.dispose();

    _pangkatController.dispose();
    _jabatanSekarangController.dispose();
    _tahunJabatanController.dispose();
    _jabatanSebelumnyaController.dispose();
    _tahunJabatanSebelumnyaController.dispose();

    _pendidikanController.dispose();
    _tahunLulusController.dispose();
    _diklatController.dispose();
    _tahunDiklatController.dispose();

    super.dispose();
  }

  void _handleChangePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Upload foto profil akan dihubungkan ke Supabase Storage.',
        ),
      ),
    );
  }

  void _saveProfile() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now().toIso8601String();

    final updatedUser = UsersModel(
      uid: widget.user.uid,
      username: _usernameController.text.trim(),
      nama_lengkap: _namaController.text.trim(),
      nip: _nipController.text.trim(),
      email: _emailController.text.trim(),
      no_telepon: _teleponController.text.trim(),
      role: widget.user.role,
      status_akun: widget.user.status_akun,
      created_at: widget.user.created_at,
      updated_at: now,
    );

    final updatedProfile = ProfilePegawaiModel(
      owner_id: widget.profile.owner_id,
      pangkat: _pangkatController.text.trim(),
      jabatan_sekarang:
          _jabatanSekarangController.text.trim(),
      tahun_jabatan_sekarang:
          _tahunJabatanController.text.trim(),
      jabatan_sebelumnya:
          _jabatanSebelumnyaController.text.trim(),
      tahun_jabatan_sebelumnya:
          _tahunJabatanSebelumnyaController.text.trim(),
      latihan_jabatan: _diklatController.text.trim(),
      tahun_latihan_jabatan:
          _tahunDiklatController.text.trim(),
      pendidikan: _pendidikanController.text.trim(),
      tahun_lulus_pendidikan:
          _tahunLulusController.text.trim(),
      foto_profil: widget.profile.foto_profil,
      updated_at: now,
    );

    Navigator.pop(
      context,
      <String, dynamic>{
        'user': updatedUser,
        'profile': updatedProfile,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageTitle(),
                    const SizedBox(height: 18),
                    _buildPhotoSection(),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildAccountSection(),
                          const SizedBox(height: 14),
                          _buildEmploymentSection(),
                          const SizedBox(height: 14),
                          _buildEducationSection(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _headerColor,
      padding: const EdgeInsets.fromLTRB(
        24,
        18,
        24,
        16,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 52,
            child: Image.asset(
              'assets/images/logo/LOGO_KALSEL.png',
              fit: BoxFit.contain,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const Icon(
                  Icons.account_balance_rounded,
                  size: 38,
                  color: _primaryColor,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIKAP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sistem Informasi Kepegawaian dan Arsip Pegawai',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle() {
    return Row(
      children: [
        InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.arrow_back,
              size: 21,
              color: _primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Edit Profil',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black,
                width: 3,
              ),
            ),
            child: ClipOval(
              child:
                  widget.profile.foto_profil.trim().isNotEmpty
                  ? Image.network(
                      widget.profile.foto_profil,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons.person,
                          size: 76,
                          color: Colors.black,
                        );
                      },
                    )
                  : const Icon(
                      Icons.person,
                      size: 76,
                      color: Colors.black,
                    ),
            ),
          ),
          const SizedBox(height: 9),
          TextButton.icon(
            onPressed: _handleChangePhoto,
            icon: const Icon(
              Icons.photo_camera_outlined,
              size: 18,
            ),
            label: const Text(
              'Ubah Foto',
            ),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return _buildSectionCard(
      title: 'Informasi Akun',
      children: [
        _buildField(
          label: 'Nama Lengkap',
          controller: _namaController,
          requiredField: true,
        ),
        _buildField(
          label: 'Username',
          controller: _usernameController,
          requiredField: true,
        ),
        _buildField(
          label: 'NIP',
          controller: _nipController,
          keyboardType: TextInputType.number,
          requiredField: true,
        ),
        _buildField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          requiredField: true,
        ),
        _buildField(
          label: 'Nomor Telepon',
          controller: _teleponController,
          keyboardType: TextInputType.phone,
          requiredField: true,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildEmploymentSection() {
    return _buildSectionCard(
      title: 'Kepegawaian',
      children: [
        _buildField(
          label: 'Pangkat',
          controller: _pangkatController,
        ),
        _buildField(
          label: 'Jabatan Sekarang',
          controller: _jabatanSekarangController,
        ),
        _buildField(
          label: 'Tahun Mulai Menjabat',
          controller: _tahunJabatanController,
          keyboardType: TextInputType.number,
        ),
        _buildField(
          label: 'Jabatan Sebelumnya',
          controller: _jabatanSebelumnyaController,
        ),
        _buildField(
          label: 'Tahun Jabatan Sebelumnya',
          controller:
              _tahunJabatanSebelumnyaController,
          keyboardType: TextInputType.number,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildEducationSection() {
    return _buildSectionCard(
      title: 'Pendidikan & DIKLAT',
      children: [
        _buildField(
          label: 'Pendidikan Terakhir',
          controller: _pendidikanController,
        ),
        _buildField(
          label: 'Tahun Lulus',
          controller: _tahunLulusController,
          keyboardType: TextInputType.number,
        ),
        _buildField(
          label: 'Diklat / Latihan Jabatan',
          controller: _diklatController,
        ),
        _buildField(
          label: 'Tahun Mengikuti Diklat',
          controller: _tahunDiklatController,
          keyboardType: TextInputType.number,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        18,
        18,
      ),
      decoration: BoxDecoration(
        color: _formColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool requiredField = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
            ),
            decoration: _inputDecoration(),
            validator: requiredField
                ? (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return '$label wajib diisi';
                    }

                    if (label == 'Email' &&
                        !value.contains('@')) {
                      return 'Format email tidak valid';
                    }

                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Colors.black54,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: _primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            minimumSize: const Size(90, 40),
            side: const BorderSide(
              color: Colors.black,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Batal'),
        ),
        const SizedBox(width: 14),
        FilledButton(
          onPressed: _saveProfile,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF39F341),
            foregroundColor: Colors.black,
            minimumSize: const Size(90, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Simpan',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}