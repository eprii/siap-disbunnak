import 'package:flutter/material.dart';

import '../../models/profilepegawai_model.dart';
import '../../models/users_model.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _primaryColor = Color(0xFF46532E);
  static const Color _backgroundColor = Color(0xFFB7C79E);
  static const Color _headerColor = Color(0xFFF5F2E9);
  static const Color _cardColor = Colors.white;

  late UsersModel _user;
  late ProfilePegawaiModel _profile;

  @override
  void initState() {
    super.initState();

    // Dummy data sementara.
    // Nantinya akan diganti dengan data Firestore.
    _user = UsersModel(
      uid: 'user_001',
      username: 'Arief Muhammad',
      nama_lengkap: 'Arief Muhammad',
      nip: '196809111995032003',
      email: 'arief.m@disbunak.go.id',
      no_telepon: '0812xxxxxxxx',
      role: 'user',
      status_akun: 'Aktif',
      created_at: '2026-07-01T08:00:00',
      updated_at: '2026-07-02T08:00:00',
    );

    _profile = ProfilePegawaiModel(
      owner_id: 'user_001',
      pangkat: 'Penata Muda /III-a',
      jabatan_sekarang: 'Penyuluh Pertanian Muda',
      tahun_jabatan_sekarang: '2022',
      jabatan_sebelumnya: 'Staf Teknis',
      tahun_jabatan_sebelumnya: '2022',
      latihan_jabatan: 'Diklat Fungsional',
      tahun_latihan_jabatan: '2021',
      pendidikan: 'S1 Arkeologi',
      tahun_lulus_pendidikan: '2010',
      foto_profil: '',
      updated_at: '2026-07-02T08:00:00',
    );
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          user: _user,
          profile: _profile,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final updatedUser = result['user'];
    final updatedProfile = result['profile'];

    if (updatedUser is UsersModel &&
        updatedProfile is ProfilePegawaiModel) {
      setState(() {
        _user = updatedUser;
        _profile = updatedProfile;
      });
    }
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFD6D6),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Anda yakin ingin keluar\ndari akun ini?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(
                            color: Colors.black54,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Tidak'),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || shouldLogout != true) {
      return;
    }

    // FirebaseAuth.signOut() akan dipasang pada tahap autentikasi.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Fungsi logout akan dihubungkan ke Firebase Authentication.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _backgroundColor,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                24,
                22,
                24,
                26,
              ),
              child: Column(
                children: [
                  _buildProfileIdentity(),
                  const SizedBox(height: 16),
                  _buildAccountCard(),
                  const SizedBox(height: 12),
                  _buildEmploymentCard(),
                  const SizedBox(height: 12),
                  _buildEducationCard(),
                  const SizedBox(height: 10),
                  Text(
                    'Telah Diperbarui ${_formatDate(_profile.updated_at)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildProfileIdentity() {
    return Column(
      children: [
        _buildAvatar(),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _user.nama_lengkap,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 5),
            InkWell(
              onTap: _openEditProfile,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'NIP:${_user.nip}',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black,
          width: 3,
        ),
      ),
      child: ClipOval(
        child: _profile.foto_profil.trim().isNotEmpty
            ? Image.network(
                _profile.foto_profil,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons.person,
                    size: 72,
                    color: Colors.black,
                  );
                },
              )
            : const Icon(
                Icons.person,
                size: 72,
                color: Colors.black,
              ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return _buildInfoCard(
      title: 'Akun',
      titleColor: Colors.red.shade700,
      children: [
        _buildInfoRow(
          label: 'Username',
          value: _user.username,
        ),
        _buildInfoRow(
          label: 'Email',
          value: _user.email,
        ),
        _buildInfoRow(
          label: 'Nomor Telepon',
          value: _user.no_telepon,
        ),
        _buildInfoRow(
          label: 'Status Akun',
          value: _user.status_akun,
        ),
      ],
    );
  }

  Widget _buildEmploymentCard() {
    return _buildInfoCard(
      title: 'Kepegawaian',
      children: [
        _buildInfoRow(
          label: 'Pangkat',
          value: _profile.pangkat,
        ),
        _buildInfoRow(
          label: 'Jabatan Sekarang',
          value: _profile.jabatan_sekarang,
        ),
        _buildInfoRow(
          label: 'Sejak Tahun',
          value: _profile.tahun_jabatan_sekarang,
        ),
        _buildInfoRow(
          label: 'Jabatan Sebelumnya',
          value: _profile.jabatan_sebelumnya,
        ),
        _buildInfoRow(
          label: 'Berakhir Tahun',
          value: _profile.tahun_jabatan_sebelumnya,
        ),
      ],
    );
  }

  Widget _buildEducationCard() {
    return _buildInfoCard(
      title: 'Pendidikan & DIKLAT',
      children: [
        _buildInfoRow(
          label: 'Pendidikan Terakhir',
          value: _profile.pendidikan,
        ),
        _buildInfoRow(
          label: 'Tahun Lulus',
          value: _profile.tahun_lulus_pendidikan,
        ),
        _buildInfoRow(
          label: 'Diklat / Tahun Diklat',
          value: _profile.latihan_jabatan,
        ),
        _buildInfoRow(
          label: 'Tahun Diklat',
          value: _profile.tahun_latihan_jabatan,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
    Color titleColor = Colors.black,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        12,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: FilledButton.icon(
        onPressed: _showLogoutDialog,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: const Icon(
          Icons.logout_rounded,
          size: 18,
        ),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value.isEmpty ? '-' : value;
    }

    const months = [
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