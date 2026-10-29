import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.value?.uid;
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value(null);
  }
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.streamUserProfile(uid);
});

final userProfileByIdProvider = FutureProvider.family<UserProfile?, String>((
  ref,
  uid,
) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getUserProfile(uid);
});
