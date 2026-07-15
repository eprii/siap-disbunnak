import 'package:flutter/material.dart';

class FormSkAngkaKreditPage extends StatefulWidget {
  const FormSkAngkaKreditPage({super.key});

  @override
  State<FormSkAngkaKreditPage> createState() => _FormSkAngkaKreditPageState();
}

class _FormSkAngkaKreditPageState extends State<FormSkAngkaKreditPage> {
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
          content: Text('Terjadi kesalahan: $error'),
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
        title: const Text('Form SK Angka Kredit'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Form SK Angka Kredit',
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
