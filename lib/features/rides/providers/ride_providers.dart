import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/ride_repository.dart';
import '../domain/ride.dart';

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepository();
});

class RideSearchFilter {
  final String? departureCity;
  final String? arrivalCity;
  final DateTime? date;

  const RideSearchFilter({this.departureCity, this.arrivalCity, this.date});

  RideSearchFilter copyWith({
    String? departureCity,
    String? arrivalCity,
    DateTime? date,
    bool clearDate = false,
  }) {
    return RideSearchFilter(
      departureCity: departureCity ?? this.departureCity,
      arrivalCity: arrivalCity ?? this.arrivalCity,
      date: clearDate ? null : (date ?? this.date),
    );
  }
}

class RideSearchFilterNotifier extends Notifier<RideSearchFilter> {
  @override
  RideSearchFilter build() => const RideSearchFilter();

  void update(RideSearchFilter newFilter) {
    state = newFilter;
  }

  void reset() {
    state = const RideSearchFilter();
  }
}

final rideSearchFilterProvider =
    NotifierProvider<RideSearchFilterNotifier, RideSearchFilter>(
      RideSearchFilterNotifier.new,
    );

final availableRidesStreamProvider = StreamProvider<List<Ride>>((ref) {
  final repository = ref.watch(rideRepositoryProvider);
  final filter = ref.watch(rideSearchFilterProvider);

  return repository.searchRides(
    departureCity: filter.departureCity,
    arrivalCity: filter.arrivalCity,
    date: filter.date,
  );
});

final myPublishedRidesProvider = StreamProvider<List<Ride>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(rideRepositoryProvider);
  return repository.streamRidesByDriver(uid);
});

final rideDetailsProvider = StreamProvider.family<Ride?, String>((ref, rideId) {
  final repository = ref.watch(rideRepositoryProvider);
  return repository.streamRide(rideId);
});
