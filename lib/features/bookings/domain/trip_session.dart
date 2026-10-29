import 'package:cloud_firestore/cloud_firestore.dart';

class TripSession {
  final String id;
  final String bookingId;
  final String rideId;
  final String driverId;
  final String passengerId;
  final String code;
  final bool isUsed;
  final int attemptCount;
  final int maxAttempts;
  final DateTime expiresAt;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  const TripSession({
    required this.id,
    required this.bookingId,
    required this.rideId,
    required this.driverId,
    required this.passengerId,
    required this.code,
    this.isUsed = false,
    this.attemptCount = 0,
    this.maxAttempts = 3,
    required this.expiresAt,
    this.verifiedAt,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get hasReachedMaxAttempts => attemptCount >= maxAttempts;
  bool get isValid => !isUsed && !isExpired && !hasReachedMaxAttempts;

  factory TripSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return TripSession(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      rideId: data['rideId'] as String? ?? '',
      driverId: data['driverId'] as String? ?? '',
      passengerId: data['passengerId'] as String? ?? '',
      code: data['code'] as String? ?? '',
      isUsed: data['isUsed'] as bool? ?? false,
      attemptCount: (data['attemptCount'] as num?)?.toInt() ?? 0,
      maxAttempts: (data['maxAttempts'] as num?)?.toInt() ?? 3,
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 24)),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'rideId': rideId,
      'driverId': driverId,
      'passengerId': passengerId,
      'code': code,
      'isUsed': isUsed,
      'attemptCount': attemptCount,
      'maxAttempts': maxAttempts,
      'expiresAt': Timestamp.fromDate(expiresAt),
      if (verifiedAt != null) 'verifiedAt': Timestamp.fromDate(verifiedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
