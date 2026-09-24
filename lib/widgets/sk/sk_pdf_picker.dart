import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SkPdfPicker extends StatelessWidget {
  final PlatformFile? file;
  final VoidCallback onPressed;

  const SkPdfPicker({
    super.key,
    required this.file,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String? fileName = file?.name.trim().isEmpty == true
        ? null
        : file?.name.trim();

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F3E7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x2A6A5527)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.picture_as_pdf_outlined,
              color: Color(0xFF9B3B2C),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName ?? 'Pilih file PDF SK',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.upload_file_rounded),
          ],
        ),
      ),
    );
  }
}
