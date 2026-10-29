import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/domain/user_profile.dart';
import '../../rides/domain/ride.dart';
import '../domain/booking.dart';
import '../domain/trip_session.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookingsRef =>
      _firestore.collection(AppConstants.bookingsCollection);

  CollectionReference<Map<String, dynamic>> get _ridesRef =>
      _firestore.collection(AppConstants.ridesCollection);

  CollectionReference<Map<String, dynamic>> get _tripSessionsRef =>
      _firestore.collection(AppConstants.tripSessionsCollection);

  /// Crée une demande de réservation avec validation transactionnelle
  Future<String> requestBooking({
    required Ride ride,
    required UserProfile passenger,
    required int seatsCount,
  }) async {
    // Règle: Interdiction de réserver son propre trajet
    if (ride.driverId == passenger.uid) {
      throw Exception('Vous ne pouvez pas réserver votre propre trajet.');
    }

    if (seatsCount < 1) {
      throw Exception('Le nombre de places doit être au moins 1.');
    }

    // Vérification de demande active en double (pending ou accepted)
    final existingQuery = await _bookingsRef
        .where('rideId', isEqualTo: ride.id)
        .where('passengerId', isEqualTo: passenger.uid)
        .get();

    for (var doc in existingQuery.docs) {
      final status = doc.data()['status'] as String?;
      if (status == AppConstants.bookingStatusPending ||
          status == AppConstants.bookingStatusAccepted) {
        throw Exception(
          'Vous avez déjà une demande en cours pour ce trajet ($status).',
        );
      }
    }

    // Transaction pour vérifier l'état du trajet en temps réel
    return _firestore.runTransaction<String>((transaction) async {
      final rideDocRef = _ridesRef.doc(ride.id);
      final rideSnapshot = await transaction.get(rideDocRef);

      if (!rideSnapshot.exists) {
        throw Exception('Le trajet n\'existe plus.');
      }

      final currentRide = Ride.fromFirestore(rideSnapshot);

      if (currentRide.isCancelled) {
        throw Exception('Ce trajet a été annulé par le conducteur.');
      }

      if (currentRide.isPast) {
        throw Exception('Ce trajet est déjà passé.');
      }

      if (currentRide.availableSeats < seatsCount) {
        throw Exception(
          'Places insuffisantes. Il ne reste que ${currentRide.availableSeats} place(s).',
        );
      }

      final bookingRef = _bookingsRef.doc();
      final totalPrice = currentRide.pricePerSeat * seatsCount;

      final booking = Booking(
        id: bookingRef.id,
        rideId: currentRide.id,
        driverId: currentRide.driverId,
        passengerId: passenger.uid,
        passengerName: passenger.fullName,
        passengerPhone: passenger.phoneNumber,
        passengerPhotoUrl: passenger.photoUrl,
        seatsCount: seatsCount,
        totalPrice: totalPrice,
        departureCity: currentRide.departureCity,
        arrivalCity: currentRide.arrivalCity,
        departureDateTime: currentRide.departureDateTime,
        meetingPoint: currentRide.meetingPoint,
        status: AppConstants.bookingStatusPending,
        createdAt: DateTime.now(),
      );

      transaction.set(bookingRef, booking.toFirestore());

      return bookingRef.id;
    });
  }

  /// Accepte ou refuse une réservation avec mise à jour atomique des places
  Future<void> respondToBooking({
    required String bookingId,
    required String driverId,
    required bool accept,
  }) async {
    return _firestore.runTransaction((transaction) async {
      final bookingDocRef = _bookingsRef.doc(bookingId);
      final bookingSnapshot = await transaction.get(bookingDocRef);

      if (!bookingSnapshot.exists) {
        throw Exception('Réservation introuvable.');
      }

      final booking = Booking.fromFirestore(bookingSnapshot);

      if (booking.driverId != driverId) {
        throw Exception('Vous n\'êtes pas le conducteur de ce trajet.');
      }

      if (booking.status != AppConstants.bookingStatusPending) {
        throw Exception('Cette réservation n\'est plus en attente.');
      }

      final rideDocRef = _ridesRef.doc(booking.rideId);
      final rideSnapshot = await transaction.get(rideDocRef);

      if (!rideSnapshot.exists) {
        throw Exception('Le trajet associé n\'existe plus.');
      }

      final currentRide = Ride.fromFirestore(rideSnapshot);

      if (!accept) {
        // Refus de la réservation
        transaction.update(bookingDocRef, {
          'status': AppConstants.bookingStatusRejected,
        });
        return;
      }

      // Acceptation : vérification des places disponibles
      if (currentRide.isCancelled) {
        throw Exception('Impossible d\'accepter : le trajet a été annulé.');
      }

      if (currentRide.availableSeats < booking.seatsCount) {
        throw Exception(
          'Places insuffisantes (${currentRide.availableSeats} disponibles pour ${booking.seatsCount} demandée(s)).',
        );
      }

      // Décrémentation atomique des places
      final newAvailableSeats = currentRide.availableSeats - booking.seatsCount;
      if (newAvailableSeats < 0) {
        throw Exception('Erreur de cohérence : places négatives.');
      }

      // Génération d'un code OTP sécurisé à 6 chiffres
      final random = Random.secure();
      final codeInt = 100000 + random.nextInt(900000);
      final departureCode = codeInt.toString();

      final tripSessionRef = _tripSessionsRef.doc(bookingId);
      final tripSession = TripSession(
        id: tripSessionRef.id,
        bookingId: bookingId,
        rideId: currentRide.id,
        driverId: driverId,
        passengerId: booking.passengerId,
        code: departureCode,
        isUsed: false,
        attemptCount: 0,
        maxAttempts: 3,
        // Expire 24 heures après l'heure de départ prévue
        expiresAt: currentRide.departureDateTime.add(const Duration(hours: 24)),
        createdAt: DateTime.now(),
      );

      transaction.update(rideDocRef, {'availableSeats': newAvailableSeats});

      transaction.set(tripSessionRef, tripSession.toFirestore());

      transaction.update(bookingDocRef, {
        'status': AppConstants.bookingStatusAccepted,
        'departureCode': departureCode,
      });
    });
  }

  /// Annulation d'une réservation avec restitution atomique des places si nécessaire
  Future<void> cancelBooking({
    required String bookingId,
    required String currentUserId,
  }) async {
    return _firestore.runTransaction((transaction) async {
      final bookingDocRef = _bookingsRef.doc(bookingId);
      final bookingSnapshot = await transaction.get(bookingDocRef);

      if (!bookingSnapshot.exists) {
        throw Exception('Réservation introuvable.');
      }

      final booking = Booking.fromFirestore(bookingSnapshot);

      // Seul le passager ou le conducteur concerné peut annuler
      if (booking.passengerId != currentUserId &&
          booking.driverId != currentUserId) {
        throw Exception('Action non autorisée.');
      }

      // Règle : une annulation répétée ne libère pas plusieurs places
      if (booking.status == AppConstants.bookingStatusCancelled) {
        throw Exception('Cette réservation est déjà annulée.');
      }

      if (booking.status == AppConstants.bookingStatusCompleted) {
        throw Exception('Impossible d\'annuler une réservation déjà terminée.');
      }

      final rideDocRef = _ridesRef.doc(booking.rideId);
      final rideSnapshot = await transaction.get(rideDocRef);

      // Si la réservation était acceptée, restituer les places sans dépasser totalSeats
      if (booking.status == AppConstants.bookingStatusAccepted &&
          rideSnapshot.exists) {
        final currentRide = Ride.fromFirestore(rideSnapshot);
        final restoredSeats = min(
          currentRide.availableSeats + booking.seatsCount,
          currentRide.totalSeats,
        );

        transaction.update(rideDocRef, {'availableSeats': restoredSeats});
      }

      transaction.update(bookingDocRef, {
        'status': AppConstants.bookingStatusCancelled,
      });
    });
  }

  /// Validation du code de départ par le conducteur
  Future<void> verifyDepartureCode({
    required String bookingId,
    required String driverId,
    required String enteredCode,
  }) async {
    return _firestore.runTransaction((transaction) async {
      final tripSessionRef = _tripSessionsRef.doc(bookingId);
      final sessionSnapshot = await transaction.get(tripSessionRef);

      if (!sessionSnapshot.exists) {
        throw Exception(
          'Session de départ introuvable pour cette réservation.',
        );
      }

      final session = TripSession.fromFirestore(sessionSnapshot);

      if (session.driverId != driverId) {
        throw Exception('Seul le conducteur peut valider ce code.');
      }

      if (session.isUsed) {
        throw Exception('Ce code a déjà été validé et utilisé.');
      }

      if (session.isExpired) {
        throw Exception('Ce code de départ a expiré.');
      }

      if (session.hasReachedMaxAttempts) {
        throw Exception(
          'Nombre maximal de tentatives (${session.maxAttempts}) atteint pour cette réservation.',
        );
      }

      final newAttemptCount = session.attemptCount + 1;

      if (session.code.trim() != enteredCode.trim()) {
        // Enregistrer l'échec de la tentative
        transaction.update(tripSessionRef, {'attemptCount': newAttemptCount});

        final remaining = session.maxAttempts - newAttemptCount;
        throw Exception('Code incorrect. Tentatives restantes : $remaining.');
      }

      // Code valide ! Confirmation du départ
      transaction.update(tripSessionRef, {
        'isUsed': true,
        'attemptCount': newAttemptCount,
        'verifiedAt': Timestamp.fromDate(DateTime.now()),
      });

      final bookingDocRef = _bookingsRef.doc(bookingId);
      transaction.update(bookingDocRef, {
        'status': AppConstants.bookingStatusCompleted,
      });
    });
  }

  Stream<List<Booking>> streamBookingsForPassenger(String passengerId) {
    return _bookingsRef
        .where('passengerId', isEqualTo: passengerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Booking>> streamBookingsForDriver(String driverId) {
    return _bookingsRef
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList(),
        );
  }

  Stream<Booking?> streamBooking(String bookingId) {
    return _bookingsRef.doc(bookingId).snapshots().map((doc) {
      return doc.exists ? Booking.fromFirestore(doc) : null;
    });
  }

  Stream<TripSession?> streamTripSession(String bookingId) {
    return _tripSessionsRef.doc(bookingId).snapshots().map((doc) {
      return doc.exists ? TripSession.fromFirestore(doc) : null;
    });
  }
}
