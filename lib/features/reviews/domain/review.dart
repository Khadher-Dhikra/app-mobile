import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String rideId;
  final String authorId;
  final String authorName;
  final String targetUserId;
  final int rating; // 1 to 5
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.rideId,
    required this.authorId,
    required this.authorName,
    required this.targetUserId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Review(
      id: doc.id,
      rideId: data['rideId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Passager',
      targetUserId: data['targetUserId'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 5,
      comment: data['comment'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rideId': rideId,
      'authorId': authorId,
      'authorName': authorName,
      'targetUserId': targetUserId,
      'rating': rating,
      if (comment != null) 'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
