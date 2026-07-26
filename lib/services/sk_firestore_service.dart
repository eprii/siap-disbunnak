
import 'package:cloud_firestore/cloud_firestore.dart';

class SKFirestoreService {
  static final SKFirestoreService instance =
      SKFirestoreService._internal();

  factory SKFirestoreService() {
    return instance;
  }

  SKFirestoreService._internal();

  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(
    String uid,
    String jenisSK,
  ) {
    return _db
        .collection('sk')
        .doc(uid)
        .collection(jenisSK);
  }

  Future<void> saveSK({
    required String uid,
    required String jenisSK,
    required Map<String, dynamic> data,
  }) async {
    await _collection(uid, jenisSK).add({
      ...data,
      'owner_id': uid,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSKList({
    required String uid,
    required String jenisSK,
  }) {
    return _collection(uid, jenisSK)
        .orderBy(
          'created_at',
          descending: true,
        )
        .snapshots();
  }

  Future<void> deleteSK({
    required String uid,
    required String jenisSK,
    required String documentId,
  }) async {
    await _collection(uid, jenisSK)
        .doc(documentId)
        .delete();
  }
}
