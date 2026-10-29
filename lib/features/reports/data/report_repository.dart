import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/report.dart';

class ReportRepository {
  final FirebaseFirestore _firestore;

  ReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _firestore.collection(AppConstants.reportsCollection);

  Future<String> createReport(Report report) async {
    final docRef = await _reportsRef.add(report.toFirestore());
    return docRef.id;
  }

  Stream<List<Report>> streamAllReports() {
    return _reportsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList(),
        );
  }

  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    required String adminDecision,
  }) async {
    await _reportsRef.doc(reportId).update({
      'status': status,
      'adminDecision': adminDecision,
    });
  }
}
