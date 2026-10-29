import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/booking_repository.dart';
import '../domain/booking.dart';
import '../domain/trip_session.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

final myBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.streamBookingsForPassenger(uid);
});

final driverReceivedBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.streamBookingsForDriver(uid);
});

final bookingDetailsProvider = StreamProvider.family<Booking?, String>((
  ref,
  bookingId,
) {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.streamBooking(bookingId);
});

final tripSessionProvider = StreamProvider.family<TripSession?, String>((
  ref,
  bookingId,
) {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.streamTripSession(bookingId);
});
