import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/domain/user_profile.dart';
import '../domain/review.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reviewsRef =>
      _firestore.collection(AppConstants.reviewsCollection);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  Future<void> submitReview(Review review) async {
    // Check if review already exists for this ride and author
    final existing = await _reviewsRef
        .where('rideId', isEqualTo: review.rideId)
        .where('authorId', isEqualTo: review.authorId)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Vous avez déjà déposé un avis pour ce trajet.');
    }

    return _firestore.runTransaction((transaction) async {
      final userDocRef = _usersRef.doc(review.targetUserId);
      final userSnapshot = await transaction.get(userDocRef);

      if (!userSnapshot.exists) {
        throw Exception('Utilisateur cible introuvable.');
      }

      final profile = UserProfile.fromFirestore(userSnapshot);
      final currentTotalRating = profile.rating * profile.reviewCount;
      final newReviewCount = profile.reviewCount + 1;
      final newAverage = (currentTotalRating + review.rating) / newReviewCount;

      final reviewDocRef = _reviewsRef.doc();
      transaction.set(reviewDocRef, review.toFirestore());

      transaction.update(userDocRef, {
        'rating': double.parse(newAverage.toStringAsFixed(1)),
        'reviewCount': newReviewCount,
      });
    });
  }

  Stream<List<Review>> streamReviewsForUser(String targetUserId) {
    return _reviewsRef
        .where('targetUserId', isEqualTo: targetUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList(),
        );
  }

  Future<bool> hasReviewed({
    required String rideId,
    required String authorId,
  }) async {
    final snapshot = await _reviewsRef
        .where('rideId', isEqualTo: rideId)
        .where('authorId', isEqualTo: authorId)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
