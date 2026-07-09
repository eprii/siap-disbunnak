import 'package:flutter/material.dart';

class SavedSKPage extends StatelessWidget {
  const SavedSKPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'SK Tersimpan',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}