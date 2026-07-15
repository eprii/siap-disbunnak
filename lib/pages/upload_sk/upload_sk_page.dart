import 'package:flutter/material.dart';

class UploadSKPage extends StatefulWidget {
  final VoidCallback onBack;

  const UploadSKPage({
    super.key,
    required this.onBack,
  });

  @override
  State<UploadSKPage> createState() => _UploadSKPageState();
}

class _UploadSKPageState extends State<UploadSKPage> {
  static const Color _primaryColor = Color(0xFF46532E);
  static const Color _backgroundColor = Color(0xFFB7C79E);
  static const Color _headerColor = Color(0xFFF5F2E9);
  static const Color _formColor = Color(0xFFF1EFE6);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaSKController = TextEditingController();
  final TextEditingController _nomorSKController = TextEditingController();
  final TextEditingController _tahunSKController = TextEditingController();
  final TextEditingController _tanggalSKController = TextEditingController();
  final TextEditingController _jabatanController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  String? _selectedJenisSK;
  DateTime? _selectedDate;

  final List<String> _jenisSKList = [
    'Pensiun',
    'Kenaikan Pangkat',
    'Mutasi',
    'Cuti',
  ];

  @override
  void dispose() {
    _namaSKController.dispose();
    _nomorSKController.dispose();
    _tahunSKController.dispose();
    _tanggalSKController.dispose();
    _jabatanController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 10),
      helpText: 'Pilih Tanggal SK',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
      _tanggalSKController.text = _formatDate(pickedDate);
      _tahunSKController.text = pickedDate.year.toString();
    });
  }

  String _formatDate(DateTime date) {
    const List<String> months = [
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

  void _resetForm() {
    _formKey.currentState?.reset();

    _namaSKController.clear();
    _nomorSKController.clear();
    _tahunSKController.clear();
    _tanggalSKController.clear();
    _jabatanController.clear();
    _deskripsiController.clear();

    setState(() {
      _selectedJenisSK = null;
      _selectedDate = null;
    });
  }

  void _handleUploadPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pemilihan file PDF akan diaktifkan pada tahap integrasi Supabase Storage.',
        ),
      ),
    );
  }

  void _handleSave() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Data form sudah valid. Penyimpanan akan dihubungkan ke database pada tahap integrasi.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ColoredBox(
        color: _backgroundColor,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageTitle(),
                    const SizedBox(height: 12),
                    _buildFormCard(),
                    const SizedBox(height: 18),
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
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 52,
            child: Image.asset(
              'assets/images/logo/LOGO_KALSEL.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
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
                    color: Colors.black,
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
        onTap: widget.onBack,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(
            Icons.arrow_back,
            size: 20,
            color: _primaryColor,
          ),
        ),
      ),
      const SizedBox(width: 8),
      const Text(
        'Tambah Surat Keputusan',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    ],
  );
}

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: _formColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Nama SK'),
            const SizedBox(height: 7),
            _buildTextField(
              controller: _namaSKController,
              hintText: 'Masukkan nama SK',
            ),

            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Nomor SK'),
                      const SizedBox(height: 7),
                      _buildTextField(
                        controller: _nomorSKController,
                        hintText: 'Nomor SK',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Tahun SK'),
                      const SizedBox(height: 7),
                      _buildTextField(
                        controller: _tahunSKController,
                        hintText: 'Tahun',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _buildLabel('Jenis SK'),
            const SizedBox(height: 7),
            _buildJenisSKDropdown(),

            const SizedBox(height: 18),

            _buildLabel('Tanggal SK'),
            const SizedBox(height: 7),
            SizedBox(
              width: 175,
              child: _buildDateField(),
            ),

            const SizedBox(height: 22),

            _buildLabel('Jabatan saat SK diterbitkan'),
            const SizedBox(height: 7),
            _buildTextField(
              controller: _jabatanController,
              hintText: 'Masukkan jabatan',
            ),
            const SizedBox(height: 4),
            const Text(
              'Tersimpan sebagai riwayat, tidak berubah walau jabatan Anda berubah nanti.',
              style: TextStyle(
                fontSize: 9,
                color: Colors.black45,
              ),
            ),

            const SizedBox(height: 18),

            _buildLabel('Deskripsi'),
            const SizedBox(height: 7),
            _buildTextField(
              controller: _deskripsiController,
              hintText: 'Deskripsi singkat SK...',
              maxLines: 4,
              minLines: 4,
            ),

            const SizedBox(height: 20),

            _buildLabel('File SK (PDF)'),
            const SizedBox(height: 7),
            _buildUploadBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    int minLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black,
      ),
      decoration: _inputDecoration(
        hintText: hintText,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Wajib diisi';
        }

        return null;
      },
    );
  }

  Widget _buildJenisSKDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedJenisSK,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.black,
      ),
      decoration: _inputDecoration(
        hintText: '',
      ),
      hint: const Text(
        'Pilih jenis SK',
        style: TextStyle(
          fontSize: 14,
          color: Colors.black45,
        ),
      ),
      items: _jenisSKList.map((jenisSK) {
        return DropdownMenuItem<String>(
          value: jenisSK,
          child: Text(
            jenisSK,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedJenisSK = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Jenis SK wajib dipilih';
        }

        return null;
      },
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _tanggalSKController,
      readOnly: true,
      onTap: _selectDate,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black,
      ),
      decoration: _inputDecoration(
        hintText: '',
        suffixIcon: const Icon(
          Icons.calendar_month_outlined,
          size: 19,
          color: _primaryColor,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Pilih tanggal';
        }

        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Colors.black38,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Colors.black87,
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
          width: 1,
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

  Widget _buildUploadBox() {
    return InkWell(
      onTap: _handleUploadPdf,
      borderRadius: BorderRadius.circular(14),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFF8D4A4A),
          radius: 14,
        ),
        child: Container(
          width: double.infinity,
          height: 105,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD5D5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_rounded,
                size: 24,
                color: Colors.black,
              ),
              SizedBox(height: 8),
              Text(
                'Ketuk untuk unggah PDF',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8D1F1F),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Maks. 10MB',
                style: TextStyle(
                  fontSize: 8,
                  color: Color(0xFF8D1F1F),
                ),
              ),
            ],
          ),
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
            _resetForm();
            widget.onBack();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            side: const BorderSide(
              color: Colors.black,
              width: 1,
            ),
            minimumSize: const Size(88, 38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Batal',
            style: TextStyle(
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 14),
        FilledButton(
          onPressed: _handleSave,
          style: FilledButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: const Color(0xFF39F341),
            minimumSize: const Size(88, 38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Simpan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    const double dashLength = 4;
    const double dashSpace = 3;

    for (final metric in path.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final double nextDistance =
            distance + dashLength < metric.length
                ? distance + dashLength
                : metric.length;

        canvas.drawPath(
          metric.extractPath(
            distance,
            nextDistance,
          ),
          paint,
        );

        distance += dashLength + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius;
  }
}