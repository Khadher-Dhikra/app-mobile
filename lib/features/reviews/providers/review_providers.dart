import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/review_repository.dart';
import '../domain/review.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

final userReviewsProvider = StreamProvider.family<List<Review>, String>((
  ref,
  userId,
) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.streamReviewsForUser(userId);
});
