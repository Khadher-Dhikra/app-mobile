import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/ride.dart';

class RideRepository {
  final FirebaseFirestore _firestore;

  RideRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ridesCollection =>
      _firestore.collection(AppConstants.ridesCollection);

  Future<String> createRide(Ride ride) async {
    final docRef = await _ridesCollection.add(ride.toFirestore());
    return docRef.id;
  }

  Future<void> updateRide(Ride ride) async {
    await _ridesCollection.doc(ride.id).update(ride.toFirestore());
  }

  Future<void> cancelRide({
    required String rideId,
    required String driverId,
  }) async {
    final doc = await _ridesCollection.doc(rideId).get();
    if (!doc.exists) {
      throw Exception('Trajet introuvable.');
    }
    final ride = Ride.fromFirestore(doc);
    if (ride.driverId != driverId) {
      throw Exception('Vous n\'êtes pas autorisé à annuler ce trajet.');
    }
    if (ride.isCancelled) {
      throw Exception('Ce trajet est déjà annulé.');
    }

    await _ridesCollection.doc(rideId).update({
      'status': AppConstants.rideStatusCancelled,
    });
  }

  Stream<Ride?> streamRide(String rideId) {
    return _ridesCollection.doc(rideId).snapshots().map((doc) {
      return doc.exists ? Ride.fromFirestore(doc) : null;
    });
  }

  Future<Ride?> getRide(String rideId) async {
    final doc = await _ridesCollection.doc(rideId).get();
    return doc.exists ? Ride.fromFirestore(doc) : null;
  }

  Stream<List<Ride>> streamRidesByDriver(String driverId) {
    return _ridesCollection
        .where('driverId', isEqualTo: driverId)
        .orderBy('departureDateTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Ride.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Ride>> searchRides({
    String? departureCity,
    String? arrivalCity,
    DateTime? date,
  }) {
    Query<Map<String, dynamic>> query = _ridesCollection.where(
      'status',
      isEqualTo: AppConstants.rideStatusActive,
    );

    if (departureCity != null && departureCity.isNotEmpty) {
      query = query.where('departureCity', isEqualTo: departureCity);
    }
    if (arrivalCity != null && arrivalCity.isNotEmpty) {
      query = query.where('arrivalCity', isEqualTo: arrivalCity);
    }

    // Filter and sort in memory if needed to allow flexible querying without composite index blocks
    return query.snapshots().map((snapshot) {
      final rides = snapshot.docs
          .map((doc) => Ride.fromFirestore(doc))
          .toList();

      return rides.where((ride) {
          // Only active rides with available seats and in the future
          if (ride.availableSeats <= 0 || ride.isPast) return false;

          // If date filter is provided, match calendar day
          if (date != null) {
            final isSameDay =
                ride.departureDateTime.year == date.year &&
                ride.departureDateTime.month == date.month &&
                ride.departureDateTime.day == date.day;
            if (!isSameDay) return false;
          }

          return true;
        }).toList()
        ..sort((a, b) => a.departureDateTime.compareTo(b.departureDateTime));
    });
  }
}
