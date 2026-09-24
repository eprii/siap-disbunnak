import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/sk_definitions.dart';
import 'pegawai_directory_service.dart';
import 'sk_comment_service.dart';

class AdminSkExplorerRecord {
  final EmployeeSkItem sk;
  final PegawaiDirectoryItem? employee;

  const AdminSkExplorerRecord({
    required this.sk,
    required this.employee,
  });
}

class AdminSkExplorerService {
  AdminSkExplorerService._();

  static final AdminSkExplorerService instance =
      AdminSkExplorerService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<AdminSkExplorerRecord>> loadRecords({
    String collection = '',
    SiapSkReviewStatus? status,
  }) async {
    final String cleanCollection = collection.trim();
    final List<SkDefinition> definitions = cleanCollection.isEmpty
        ? siapSkDefinitions
        : siapSkDefinitions
            .where(
              (SkDefinition definition) =>
                  definition.collection == cleanCollection,
            )
            .toList(growable: false);

    if (definitions.isEmpty) {
      return <AdminSkExplorerRecord>[];
    }

    final Future<List<PegawaiDirectoryItem>> employeesFuture =
        PegawaiDirectoryService.instance
            .watchEmployees(includeInactive: true)
            .first;

    final List<QuerySnapshot<Map<String, dynamic>>> snapshots =
        await Future.wait<QuerySnapshot<Map<String, dynamic>>>(
      definitions.map(
        (SkDefinition definition) =>
            _db.collection(definition.collection).get(),
      ),
    );

    final List<PegawaiDirectoryItem> employees = await employeesFuture;
    final Map<String, PegawaiDirectoryItem> employeesByUid =
        <String, PegawaiDirectoryItem>{
      for (final PegawaiDirectoryItem employee in employees)
        employee.uid: employee,
    };

    final List<AdminSkExplorerRecord> result =
        <AdminSkExplorerRecord>[];

    for (int index = 0; index < definitions.length; index++) {
      final SkDefinition definition = definitions[index];
      final QuerySnapshot<Map<String, dynamic>> snapshot = snapshots[index];

      for (final QueryDocumentSnapshot<Map<String, dynamic>> document
          in snapshot.docs) {
        final Map<String, dynamic> data = document.data();
        final String ownerId = _readString(data['owner_id']);
        final EmployeeSkItem item = _mapSk(
          definition: definition,
          documentId: document.id,
          data: data,
        );

        if (status != null && normalizeSiapSkStatus(item.status) != status) {
          continue;
        }

        result.add(
          AdminSkExplorerRecord(
            sk: item,
            employee: employeesByUid[ownerId],
          ),
        );
      }
    }

    result.sort(
      (AdminSkExplorerRecord a, AdminSkExplorerRecord b) {
        final DateTime aDate = a.sk.tanggal ??
            a.sk.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate = b.sk.tanggal ??
            b.sk.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      },
    );

    return result;
  }

  EmployeeSkItem _mapSk({
    required SkDefinition definition,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    final String filePath = _firstString(
      data,
      const <String>['file_pdf', 'file_path', 'file_sk'],
    );
    final String storedFileName = _firstString(
      data,
      const <String>['file_name', 'nama_file', 'nama_dokumen'],
    );

    return EmployeeSkItem(
      collection: definition.collection,
      documentId: documentId,
      ownerId: _readString(data['owner_id']),
      jenisLabel: definition.label,
      nomor: _firstString(
        data,
        const <String>[
          'nomor_sk_cpns',
          'nomor_sk_pns',
          'nomor_sk_pangkat',
          'nomor_pak',
          'nomor_sertifikat',
          'nomor_ijazah',
          'nomor_sk',
          'nomor_dokumen',
        ],
      ),
      tanggal: _firstDate(
        data,
        const <String>[
          'tanggal_sk_cpns',
          'tanggal_sk_pns',
          'tanggal_sk_pangkat',
          'tanggal_pak',
          'tanggal_sertifikat',
          'tanggal_ijazah',
          'tanggal_sk',
          'tanggal_dokumen',
          'tanggal_mulai',
        ],
      ),
      filePath: filePath,
      fileName: storedFileName.isEmpty
          ? _fileName(filePath)
          : storedFileName,
      status: _firstString(
        data,
        const <String>[
          'status',
          'status_sk',
          'status_verifikasi',
        ],
      ),
      createdAt: _readDateTime(data['created_at']),
      rawData: data,
    );
  }

  static String _firstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final String value = _readString(data[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static DateTime? _firstDate(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final DateTime? value = _readDateTime(data[key]);
      if (value != null) return value;
    }
    return null;
  }

  static String _fileName(String path) {
    final String clean = path.trim();
    if (clean.isEmpty) return '';
    return clean.split('/').last;
  }

  static String _readString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value.trim());
    return null;
  }
}
