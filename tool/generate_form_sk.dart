import 'dart:io';

void main() {
  const targetDirectory = 'lib/pages/kelola_data/form_sk';

  final forms = <String, FormData>{
    'form_sk_cpns_page.dart': const FormData(
      className: 'FormSkCpnsPage',
      title: 'Form SK CPNS',
    ),
    'form_sk_pns_page.dart': const FormData(
      className: 'FormSkPnsPage',
      title: 'Form SK PNS',
    ),
    'form_sk_pangkat_page.dart': const FormData(
      className: 'FormSkPangkatPage',
      title: 'Form SK Perubahan/Kenaikan Pangkat',
    ),
    'form_sk_jabatan_page.dart': const FormData(
      className: 'FormSkJabatanPage',
      title: 'Form SK Perubahan/Kenaikan Jabatan',
    ),
    'form_sk_pendidikan_page.dart': const FormData(
      className: 'FormSkPendidikanPage',
      title: 'Form SK Pendidikan',
    ),
    'form_sk_diklat_page.dart': const FormData(
      className: 'FormSkDiklatPage',
      title: 'Form SK Diklat',
    ),
    'form_sk_penghargaan_page.dart': const FormData(
      className: 'FormSkPenghargaanPage',
      title: 'Form SK Penghargaan/Tanda Jasa',
    ),
    'form_sk_kgb_page.dart': const FormData(
      className: 'FormSkKgbPage',
      title: 'Form SK Kenaikan Gaji Berkala',
    ),
    'form_sk_cuti_page.dart': const FormData(
      className: 'FormSkCutiPage',
      title: 'Form SK Cuti',
    ),
    'form_sk_angka_kredit_page.dart': const FormData(
      className: 'FormSkAngkaKreditPage',
      title: 'Form SK Angka Kredit',
    ),
    'form_sk_penugasan_tim_page.dart': const FormData(
      className: 'FormSkPenugasanTimPage',
      title: 'Form SK Penugasan Tim',
    ),
  };

  final directory = Directory(targetDirectory);

  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
    stdout.writeln('Folder dibuat: $targetDirectory');
  }

  var createdCount = 0;
  var skippedCount = 0;

  for (final entry in forms.entries) {
    final filePath = '$targetDirectory/${entry.key}';
    final file = File(filePath);

    if (file.existsSync()) {
      stdout.writeln('Dilewati karena sudah ada: ${entry.key}');
      skippedCount++;
      continue;
    }

    file.writeAsStringSync(
      _buildTemplate(
        className: entry.value.className,
        title: entry.value.title,
      ),
    );

    stdout.writeln('Berhasil dibuat: ${entry.key}');
    createdCount++;
  }

  stdout.writeln('');
  stdout.writeln('Selesai.');
  stdout.writeln('File baru: $createdCount');
  stdout.writeln('File dilewati: $skippedCount');
}

String _buildTemplate({
  required String className,
  required String title,
}) {
  return '''
import 'package:flutter/material.dart';

class $className extends StatefulWidget {
  const $className({super.key});

  @override
  State<$className> createState() => _${className}State();
}

class _${className}State extends State<$className> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  Future<void> _simpanData() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Tambahkan proses upload PDF dan penyimpanan Firestore.
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: \$error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$title'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                '$title',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // TODO: Tambahkan field khusus halaman ini.

              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _simpanData,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''';
}

class FormData {
  final String className;
  final String title;

  const FormData({
    required this.className,
    required this.title,
  });
}