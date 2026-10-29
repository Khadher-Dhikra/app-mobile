import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String reporterId;
  final String reporterName;
  final String? reportedUserId;
  final String? reportedRideId;
  final String category;
  final String description;
  final String status; // pending, reviewed, resolved
  final String? adminDecision;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    this.reportedUserId,
    this.reportedRideId,
    required this.category,
    required this.description,
    this.status = 'pending',
    this.adminDecision,
    required this.createdAt,
  });

  factory Report.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Report(
      id: doc.id,
      reporterId: data['reporterId'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? 'Utilisateur',
      reportedUserId: data['reportedUserId'] as String?,
      reportedRideId: data['reportedRideId'] as String?,
      category: data['category'] as String? ?? 'Autre',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      adminDecision: data['adminDecision'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      if (reportedUserId != null) 'reportedUserId': reportedUserId,
      if (reportedRideId != null) 'reportedRideId': reportedRideId,
      'category': category,
      'description': description,
      'status': status,
      if (adminDecision != null) 'adminDecision': adminDecision,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
