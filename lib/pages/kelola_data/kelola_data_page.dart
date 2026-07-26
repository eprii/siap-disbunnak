// SIAP_KELOLA_DATA_VISIBLE_CARD_SHADOWS_V6
import 'package:flutter/material.dart';

import 'form_sk/form_sk_angka_kredit_page.dart';
import 'form_sk/form_sk_cpns_page.dart';
import 'form_sk/form_sk_cuti_page.dart';
import 'form_sk/form_sk_jabatan_page.dart';
import 'form_sk/form_sk_kgb_page.dart';
import 'form_sk/form_sk_pangkat_page.dart';
import 'form_sk/form_sk_pendidikan_page.dart';
import 'form_sk/form_sk_penghargaan_page.dart';
import 'form_sk/form_sk_penugasan_tim_page.dart';
import 'form_sk/form_sk_pns_page.dart';

class KelolaDataPage extends StatelessWidget {
  const KelolaDataPage({super.key});

  static const String _logoAsset =
      'assets/images/logo/LOGO_KALSEL.png';

  static const Color _cardColor = Color(0xFFFFFBF2);
  static const Color _textColor = Color(0xFF1E1E1E);

  static const List<_KategoriData> _kategoriData = <_KategoriData>[
    _KategoriData(
      jenis: _JenisData.cpns,
      judul: 'CPNS',
      deskripsi: 'Calon ASN',
      icon: Icons.history_toggle_off_rounded,
      warna: Color(0xFF9F5E00),
      warnaIkon: Color(0xFFFFF2D8),
    ),
    _KategoriData(
      jenis: _JenisData.pns,
      judul: 'PNS',
      deskripsi: 'Data Pegawai\nnegeri aktif',
      icon: Icons.person_add_alt_1_rounded,
      warna: Color(0xFFF38A00),
      warnaIkon: Color(0xFFFFF0D6),
    ),
    _KategoriData(
      jenis: _JenisData.pangkat,
      judul: 'Pangkat',
      deskripsi: 'Golongan &\nkenaikan pangkat',
      icon: Icons.stairs_rounded,
      warna: Color(0xFF1976D2),
      warnaIkon: Color(0xFFE7F2FF),
    ),
    _KategoriData(
      jenis: _JenisData.jabatan,
      judul: 'Jabatan',
      deskripsi: 'Data jabatan\npegawai',
      icon: Icons.workspace_premium_rounded,
      warna: Color(0xFF0667A9),
      warnaIkon: Color(0xFFE5F1FF),
    ),
    _KategoriData(
      jenis: _JenisData.pendidikan,
      judul: 'Pendidikan',
      deskripsi: 'Riwayat\nPendidikan',
      icon: Icons.school_rounded,
      warna: Color(0xFF3C8E14),
      warnaIkon: Color(0xFFEAF6DC),
    ),
    _KategoriData(
      jenis: _JenisData.penghargaan,
      judul: 'Penghargaan',
      deskripsi: 'Prestasi\npegawai',
      icon: Icons.workspace_premium_outlined,
      warna: Color(0xFFF03948),
      warnaIkon: Color(0xFFFFE8EB),
    ),
    _KategoriData(
      jenis: _JenisData.kgb,
      judul: 'KGB',
      deskripsi: 'Kenaikan gaji\nberkala',
      icon: Icons.account_balance_wallet_outlined,
      warna: Color(0xFFB56900),
      warnaIkon: Color(0xFFFFF0D7),
    ),
    _KategoriData(
      jenis: _JenisData.cuti,
      judul: 'Cuti',
      deskripsi: 'Pengajuan &\nriwayat cuti',
      icon: Icons.edit_calendar_outlined,
      warna: Color(0xFFB6242A),
      warnaIkon: Color(0xFFFFE8E9),
    ),
    _KategoriData(
      jenis: _JenisData.angkaKredit,
      judul: 'AK',
      deskripsi: 'Angka kredit\npegawai',
      icon: Icons.credit_card_rounded,
      warna: Color(0xFF1976D2),
      warnaIkon: Color(0xFFE7F2FF),
    ),
    _KategoriData(
      jenis: _JenisData.penugasanTim,
      judul: 'Penugasan TIM',
      deskripsi: 'Riwayat tugas\ntim',
      icon: Icons.groups_rounded,
      warna: Color(0xFF3C8E14),
      warnaIkon: Color(0xFFEAF6DC),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CustomScrollView(
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: <Widget>[
          SliverToBoxAdapter(child: _buildHeader(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverToBoxAdapter(child: _buildIntroductionCard()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final _KategoriData kategori = _kategoriData[index];
                  return _buildCategoryCard(context, kategori);
                },
                childCount: _kategoriData.length,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 118,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 132),
            sliver: SliverToBoxAdapter(child: _buildLastUpdateCard()),
          ),
          ],
        ),

        // Gradient hitam ringan di area header agar konsisten dengan Homepage.
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
                  stops: <double>[
                    0.0,
                    1.0,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        28,
        statusBarHeight + 10,
        22,
        0,
      ),
      child: Row(
        children: <Widget>[
          Image.asset(
            _logoAsset,
            width: 42,
            height: 50,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.account_balance_rounded,
              size: 42,
              color: Color(0xFF9B5E05),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SIAP',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Sistem Informasi Administrasi\nPegawai',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.18,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroductionCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x2B000000),
            blurRadius: 9,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD6C59F)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.badge_rounded,
              size: 34,
              color: Color(0xFFD08309),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Kelola Data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Pilih kategori data yang ingin\nditambahkan atau diperbarui.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: Color(0xFF4D4D4D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    _KategoriData kategori,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x42000000),
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openForm(context, kategori.jenis),
          child: Ink(
            decoration: BoxDecoration(
              color: _cardColor,
              border: Border(
                left: BorderSide(
                  color: kategori.warna,
                  width: 8,
                ),
              ),
            ),
            child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: kategori.warnaIkon,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD8D8D8),
                    ),
                  ),
                  child: Icon(
                    kategori.icon,
                    size: 26,
                    color: kategori.warna,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        kategori.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.05,
                          fontWeight: FontWeight.w500,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        kategori.deskripsi,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          height: 1.18,
                          color: Color(0xFF5B5B5B),
                        ),
                      ),
                    ],
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

  Widget _buildLastUpdateCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 9, 16, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFD5),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD9B77D)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        children: <Widget>[
          Icon(
            Icons.edit_calendar_outlined,
            size: 27,
            color: Color(0xFFA45E00),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Update Terakhir',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFA45E00),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '12 Juni 2026 • 10:45 IB',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF5B5B5B),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFC06F00),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, _JenisData jenis) {
    late final Widget destinationPage;

    switch (jenis) {
      case _JenisData.cpns:
        destinationPage = const FormSkCpnsPage();
        break;
      case _JenisData.pns:
        destinationPage = const FormSkPnsPage();
        break;
      case _JenisData.pangkat:
        destinationPage = const FormSkPangkatPage();
        break;
      case _JenisData.jabatan:
        destinationPage = const FormSkJabatanPage();
        break;
      case _JenisData.pendidikan:
        destinationPage = const FormSkPendidikanPage();
        break;
      case _JenisData.penghargaan:
        destinationPage = const FormSkPenghargaanPage();
        break;
      case _JenisData.kgb:
        destinationPage = const FormSkKgbPage();
        break;
      case _JenisData.cuti:
        destinationPage = const FormSkCutiPage();
        break;
      case _JenisData.angkaKredit:
        destinationPage = const FormSkAngkaKreditPage();
        break;
      case _JenisData.penugasanTim:
        destinationPage = const FormSkPenugasanTimPage();
        break;
    }

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return destinationPage;
        },
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return child;
        },
      ),
    );
  }
}

enum _JenisData {
  cpns,
  pns,
  pangkat,
  jabatan,
  pendidikan,
  penghargaan,
  kgb,
  cuti,
  angkaKredit,
  penugasanTim,
}

class _KategoriData {
  final _JenisData jenis;
  final String judul;
  final String deskripsi;
  final IconData icon;
  final Color warna;
  final Color warnaIkon;

  const _KategoriData({
    required this.jenis,
    required this.judul,
    required this.deskripsi,
    required this.icon,
    required this.warna,
    required this.warnaIkon,
  });
}
