class SkDefinition {
  final String collection;
  final String label;

  const SkDefinition({
    required this.collection,
    required this.label,
  });
}

enum SiapSkReviewStatus {
  pending,
  approved,
  rejected,
}

const List<SkDefinition> siapSkDefinitions = <SkDefinition>[
  SkDefinition(
    collection: 'sk_cpns',
    label: 'SK CPNS',
  ),
  SkDefinition(
    collection: 'sk_pns',
    label: 'SK PNS',
  ),
  SkDefinition(
    collection: 'sk_pangkat',
    label: 'SK Pangkat',
  ),
  SkDefinition(
    collection: 'sk_jabatan',
    label: 'SK Jabatan',
  ),
  SkDefinition(
    collection: 'sk_pendidikan',
    label: 'SK Pendidikan',
  ),
  SkDefinition(
    collection: 'sk_diklat',
    label: 'SK Diklat',
  ),
  SkDefinition(
    collection: 'sk_penghargaan',
    label: 'SK Penghargaan',
  ),
  SkDefinition(
    collection: 'sk_kgb',
    label: 'SK KGB',
  ),
  SkDefinition(
    collection: 'sk_cuti',
    label: 'SK Cuti',
  ),
  SkDefinition(
    collection: 'sk_angka_kredit',
    label: 'SK Angka Kredit',
  ),
  SkDefinition(
    collection: 'sk_penugasan_tim',
    label: 'SK Penugasan Tim',
  ),
];

const List<String> siapSkStatusValues = <String>[
  'Pending',
  'Disetujui',
  'Ditolak',
];

bool isSiapSkCollection(String collection) {
  final String clean = collection.trim();
  return siapSkDefinitions.any(
    (SkDefinition definition) => definition.collection == clean,
  );
}

SiapSkReviewStatus normalizeSiapSkStatus(dynamic value) {
  final String status = value?.toString().trim().toLowerCase() ?? '';

  if (status == 'disetujui' ||
      status == 'approved' ||
      status == 'approve') {
    return SiapSkReviewStatus.approved;
  }

  if (status == 'ditolak' ||
      status == 'rejected' ||
      status == 'reject') {
    return SiapSkReviewStatus.rejected;
  }

  return SiapSkReviewStatus.pending;
}

String siapSkStatusValue(SiapSkReviewStatus status) {
  switch (status) {
    case SiapSkReviewStatus.pending:
      return 'Pending';
    case SiapSkReviewStatus.approved:
      return 'Disetujui';
    case SiapSkReviewStatus.rejected:
      return 'Ditolak';
  }
}

String siapSkStatusLabel(dynamic value) {
  switch (normalizeSiapSkStatus(value)) {
    case SiapSkReviewStatus.pending:
      return 'Belum diperiksa';
    case SiapSkReviewStatus.approved:
      return 'Disetujui';
    case SiapSkReviewStatus.rejected:
      return 'Ditolak';
  }
}

SkDefinition? siapSkDefinitionForCollection(String collection) {
  final String clean = collection.trim();
  for (final SkDefinition definition in siapSkDefinitions) {
    if (definition.collection == clean) return definition;
  }
  return null;
}

String siapSkLabelForCollection(String collection) {
  return siapSkDefinitionForCollection(collection)?.label ?? 'Dokumen SK';
}
