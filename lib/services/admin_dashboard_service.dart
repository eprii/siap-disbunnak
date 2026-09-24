import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/sk_definitions.dart';

class AdminDashboardSummary {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int totalSk;
  final int pendingSk;
  final int approvedSk;
  final int rejectedSk;
  final Map<String, int> skCountsByCollection;

  const AdminDashboardSummary({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.totalSk,
    required this.pendingSk,
    required this.approvedSk,
    required this.rejectedSk,
    required this.skCountsByCollection,
  });

  int countFor(String collection) {
    return skCountsByCollection[collection] ?? 0;
  }
}

class AdminDashboardService {
  AdminDashboardService._();

  static final AdminDashboardService instance =
      AdminDashboardService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ValueNotifier<int> changeVersion = ValueNotifier<int>(0);

  void notifyDataChanged() {
    changeVersion.value++;
  }

  Future<AdminDashboardSummary> getSummary() async {
    final Future<QuerySnapshot<Map<String, dynamic>>> usersFuture =
        _db.collection('users').get();

    final List<Future<QuerySnapshot<Map<String, dynamic>>>> skFutures =
        siapSkDefinitions
            .map(
              (SkDefinition definition) =>
                  _db.collection(definition.collection).get(),
            )
            .toList(growable: false);

    final List<dynamic> results = await Future.wait<dynamic>(
      <Future<dynamic>>[
        usersFuture,
        ...skFutures,
      ],
    );

    final QuerySnapshot<Map<String, dynamic>> usersSnapshot =
        results.first as QuerySnapshot<Map<String, dynamic>>;

    int totalUsers = 0;
    int activeUsers = 0;
    int inactiveUsers = 0;

    for (final QueryDocumentSnapshot<Map<String, dynamic>> document
        in usersSnapshot.docs) {
      final Map<String, dynamic> data = document.data();
      final String role = _readString(data['role']).toLowerCase();

      if (role != 'user') {
        continue;
      }

      totalUsers++;

      final String status =
          _readString(data['status_akun']).toLowerCase();
      final bool active = status.isEmpty || status == 'aktif';

      if (active) {
        activeUsers++;
      } else {
        inactiveUsers++;
      }
    }

    int totalSk = 0;
    int pendingSk = 0;
    int approvedSk = 0;
    int rejectedSk = 0;
    final Map<String, int> counts = <String, int>{};

    for (int index = 0; index < siapSkDefinitions.length; index++) {
      final SkDefinition definition = siapSkDefinitions[index];
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          results[index + 1]
              as QuerySnapshot<Map<String, dynamic>>;

      counts[definition.collection] = snapshot.docs.length;
      totalSk += snapshot.docs.length;

      for (final QueryDocumentSnapshot<Map<String, dynamic>> document
          in snapshot.docs) {
        switch (normalizeSiapSkStatus(document.data()['status'])) {
          case SiapSkReviewStatus.approved:
            approvedSk++;
            break;
          case SiapSkReviewStatus.rejected:
            rejectedSk++;
            break;
          case SiapSkReviewStatus.pending:
            pendingSk++;
            break;
        }
      }
    }

    return AdminDashboardSummary(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      inactiveUsers: inactiveUsers,
      totalSk: totalSk,
      pendingSk: pendingSk,
      approvedSk: approvedSk,
      rejectedSk: rejectedSk,
      skCountsByCollection:
          Map<String, int>.unmodifiable(counts),
    );
  }

  static String _readString(dynamic value) {
    return value?.toString().trim() ?? '';
  }
}
