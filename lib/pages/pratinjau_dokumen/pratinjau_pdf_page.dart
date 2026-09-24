import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

class PratinjauPdfDetail {
  final String label;
  final String value;

  const PratinjauPdfDetail({
    required this.label,
    required this.value,
  });

  factory PratinjauPdfDetail.text({
    required String label,
    String? value,
  }) {
    return PratinjauPdfDetail(
      label: label,
      value: _normalizePreviewValue(value),
    );
  }

  factory PratinjauPdfDetail.date({
    required String label,
    DateTime? value,
  }) {
    return PratinjauPdfDetail(
      label: label,
      value: _formatPreviewDate(value),
    );
  }

  factory PratinjauPdfDetail.yesNo({
    required String label,
    required bool value,
  }) {
    return PratinjauPdfDetail(
      label: label,
      value: value ? 'Ya' : 'Tidak',
    );
  }
}

class PratinjauPdfPage extends StatefulWidget {
  final String? filePath;
  final Uint8List? fileBytes;
  final String fileName;
  final String jenisSk;
  final String nomorDokumen;
  final DateTime? tanggalDokumen;
  final String pemilik;
  final String jabatan;
  final List<PratinjauPdfDetail> details;

  const PratinjauPdfPage({
    super.key,
    this.filePath,
    this.fileBytes,
    required this.fileName,
    required this.jenisSk,
    required this.nomorDokumen,
    required this.tanggalDokumen,
    required this.pemilik,
    required this.jabatan,
    required this.details,
  }) : assert(
         fileBytes != null ||
             (filePath != null && filePath != ''),
         'Pratinjau PDF membutuhkan fileBytes atau filePath.',
       );

  @override
  State<PratinjauPdfPage> createState() => _PratinjauPdfPageState();
}

class _PratinjauPdfPageState extends State<PratinjauPdfPage> {
  final Set<int> _activePdfPointers = <int>{};

  bool get _isInteractingWithPdf => _activePdfPointers.isNotEmpty;

  String? get filePath => widget.filePath;
  Uint8List? get fileBytes => widget.fileBytes;
  String get fileName => widget.fileName;
  String get jenisSk => widget.jenisSk;
  String get nomorDokumen => widget.nomorDokumen;
  DateTime? get tanggalDokumen => widget.tanggalDokumen;
  String get pemilik => widget.pemilik;
  String get jabatan => widget.jabatan;
  List<PratinjauPdfDetail> get details => widget.details;

  void _registerPdfPointer(PointerDownEvent event) {
    if (!mounted || _activePdfPointers.contains(event.pointer)) return;

    setState(() {
      _activePdfPointers.add(event.pointer);
    });
  }

  void _unregisterPdfPointer(PointerEvent event) {
    if (!mounted || !_activePdfPointers.contains(event.pointer)) return;

    setState(() {
      _activePdfPointers.remove(event.pointer);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight =
        MediaQuery.viewPaddingOf(context).top;
    final double pdfViewerHeight =
        (MediaQuery.sizeOf(context).height * 0.40).clamp(640.0, 810.0);

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
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              'assets/images/background/background_image.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            Column(
              children: <Widget>[
                SizedBox(
                  height: statusBarHeight + 68,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      const DecoratedBox(
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
                      Padding(
                        padding: EdgeInsets.only(top: statusBarHeight),
                        child: Row(
                          children: <Widget>[
                            IconButton(
                              tooltip: 'Kembali',
                              onPressed: () =>
                                  Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Expanded(
                              child: Text(
                                'Pratinjau dokumen',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF191919),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: _isInteractingWithPdf
                        ? const NeverScrollableScrollPhysics()
                        : const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      4,
                      18,
                      18,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xCFFFF8E8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0x78FFFFFF),
                          width: 1,
                        ),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x36000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              12,
                              12,
                              12,
                              10,
                            ),
                            child: _SkPreviewDetailCard(
                              jenisSk: jenisSk,
                              nomorDokumen: nomorDokumen,
                              tanggalDokumen: tanggalDokumen,
                              pemilik: pemilik,
                              jabatan: jabatan,
                              details: details,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              12,
                              0,
                              12,
                              8,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xDFFFFFFF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0x66FFFFFF),
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 18,
                                    color: Color(0xFFB56B00),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4E4E4E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: pdfViewerHeight,
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(
                                12,
                                0,
                                12,
                                12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F0E6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFD8CEBC),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Listener(
                                behavior: HitTestBehavior.opaque,
                                onPointerDown: _registerPdfPointer,
                                onPointerUp: _unregisterPdfPointer,
                                onPointerCancel: _unregisterPdfPointer,
                                child: fileBytes != null
                                    ? PdfViewer.data(
                                        fileBytes!,
                                        sourceName: fileName,
                                      )
                                    : PdfViewer.file(filePath!),
                              ),
                            ),
                          ),
                        ],
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

class _SkPreviewDetailCard extends StatelessWidget {
  final String jenisSk;
  final String nomorDokumen;
  final DateTime? tanggalDokumen;
  final String pemilik;
  final String jabatan;
  final List<PratinjauPdfDetail> details;

  const _SkPreviewDetailCard({
    required this.jenisSk,
    required this.nomorDokumen,
    required this.tanggalDokumen,
    required this.pemilik,
    required this.jabatan,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xEDFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x8AFFFFFF),
          width: 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF2D7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 24,
                  color: Color(0xFFE68600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      jenisSk,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF191919),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _normalizePreviewValue(nomorDokumen),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatPreviewDate(tanggalDokumen),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Divider(
            height: 1,
            color: Color(0xFFE8E1D5),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 174,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: LayoutBuilder(
                builder: (
                  BuildContext context,
                  BoxConstraints constraints,
                ) {
                  final bool singleColumn =
                      constraints.maxWidth < 300;
                  final double itemWidth = singleColumn
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 9,
                    children: details.map((PratinjauPdfDetail detail) {
                      return SizedBox(
                        width: itemWidth,
                        child: _PreviewDetailItem(detail: detail),
                      );
                    }).toList(growable: false),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Divider(
            height: 1,
            color: Color(0xFFE8E1D5),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _PreviewIdentityItem(
                  label: 'Pemilik',
                  value: pemilik,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _PreviewIdentityItem(
                  label: 'Jabatan',
                  value: jabatan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewDetailItem extends StatelessWidget {
  final PratinjauPdfDetail detail;

  const _PreviewDetailItem({
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          detail.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8.5,
            height: 1.15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8A795F),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _normalizePreviewValue(detail.value),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            height: 1.2,
            color: Color(0xFF4F4F4F),
          ),
        ),
      ],
    );
  }
}

class _PreviewIdentityItem extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewIdentityItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 9.5,
          color: Color(0xFF777777),
        ),
        children: <InlineSpan>[
          TextSpan(text: '$label : '),
          TextSpan(
            text: _normalizePreviewValue(value),
            style: const TextStyle(
              color: Color(0xFF555555),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

String _normalizePreviewValue(String? value) {
  final String normalized = value?.trim() ?? '';
  return normalized.isEmpty ? '-' : normalized;
}

String _formatPreviewDate(DateTime? date) {
  if (date == null) return '-';

  const List<String> months = <String>[
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
