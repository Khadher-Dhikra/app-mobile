import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawsila/core/utils/validators.dart';
import 'package:tawsila/core/utils/currency_formatter.dart';
import 'package:tawsila/core/widgets/app_logo.dart';
import 'package:tawsila/core/widgets/custom_button.dart';
import 'package:tawsila/features/rides/domain/ride.dart';
import 'package:tawsila/features/bookings/domain/booking.dart';
import 'package:tawsila/features/bookings/domain/trip_session.dart';

void main() {
  group('Validators Tests', () {
    test('Email validator accepts valid emails and rejects invalid ones', () {
      expect(Validators.validateEmail('user@test.tn'), isNull);
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
    });

    test('Password validator checks minimum 6 characters', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('Phone validator verifies 8 digits tunisian format', () {
      expect(Validators.validatePhone('98123456'), isNull);
      expect(Validators.validatePhone('20123456'), isNull);
      expect(Validators.validatePhone('+21698123456'), isNull);
      expect(Validators.validatePhone('1234'), isNotNull);
    });

    test('Seats validator accepts 1 to 8 seats only', () {
      expect(Validators.validateSeats('1'), isNull);
      expect(Validators.validateSeats('4'), isNull);
      expect(Validators.validateSeats('8'), isNull);
      expect(Validators.validateSeats('0'), isNotNull);
      expect(Validators.validateSeats('9'), isNotNull);
      expect(Validators.validateSeats('-2'), isNotNull);
    });

    test('Price validator rejects negative or zero amounts', () {
      expect(Validators.validatePrice('15'), isNull);
      expect(Validators.validatePrice('20.5'), isNull);
      expect(Validators.validatePrice('0'), isNotNull);
      expect(Validators.validatePrice('-10'), isNotNull);
      expect(Validators.validatePrice('abc'), isNotNull);
    });

    test('Cities validator rejects identical departure and arrival', () {
      expect(Validators.validateCities('Tunis', 'Sousse'), isNull);
      expect(Validators.validateCities('Tunis', 'tunis'), isNotNull);
      expect(Validators.validateCities('', 'Sousse'), isNotNull);
    });
  });

  group('CurrencyFormatter Tests', () {
    test('formats whole and decimal dinars properly', () {
      expect(CurrencyFormatter.format(15), '15 TND');
      expect(CurrencyFormatter.format(15.5), '15.5 TND');
    });
  });

  group('Domain Logic Tests', () {
    test('Ride full and past calculations', () {
      final activeRide = Ride(
        id: 'r1',
        driverId: 'd1',
        driverName: 'Sami',
        driverPhone: '98123456',
        departureCity: 'Tunis',
        arrivalCity: 'Sousse',
        departureDateTime: DateTime.now().add(const Duration(days: 1)),
        meetingPoint: 'Passage',
        totalSeats: 4,
        availableSeats: 2,
        pricePerSeat: 15,
        carModel: 'Clio',
        createdAt: DateTime.now(),
      );

      expect(activeRide.isFull, isFalse);
      expect(activeRide.isActive, isTrue);
      expect(activeRide.isPast, isFalse);

      final fullRide = activeRide.copyWith(availableSeats: 0);
      expect(fullRide.isFull, isTrue);
    });

    test('Booking status helpers', () {
      final booking = Booking(
        id: 'b1',
        rideId: 'r1',
        driverId: 'd1',
        passengerId: 'p1',
        passengerName: 'Yassine',
        passengerPhone: '20123456',
        seatsCount: 2,
        totalPrice: 30,
        departureCity: 'Tunis',
        arrivalCity: 'Sousse',
        departureDateTime: DateTime.now(),
        meetingPoint: 'Passage',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      expect(booking.isPending, isTrue);
      expect(booking.statusDisplay, 'En attente');

      final accepted = booking.copyWith(status: 'accepted');
      expect(accepted.isAccepted, isTrue);
      expect(accepted.statusDisplay, 'Acceptée');
    });

    test('TripSession rate limiting and validation check', () {
      final session = TripSession(
        id: 's1',
        bookingId: 'b1',
        rideId: 'r1',
        driverId: 'd1',
        passengerId: 'p1',
        code: '123456',
        isUsed: false,
        attemptCount: 0,
        maxAttempts: 3,
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now(),
      );

      expect(session.isValid, isTrue);
      expect(session.isExpired, isFalse);
      expect(session.hasReachedMaxAttempts, isFalse);
    });
  });

  group('Widget Tests', () {
    testWidgets('AppLogo renders app title and tagline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppLogo())),
      );

      expect(find.text('tawsila'), findsOneWidget);
    });

    testWidgets('CustomButton renders text and triggers callback', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Confirmer',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Confirmer'), findsOneWidget);
      await tester.tap(find.text('Confirmer'));
      expect(tapped, isTrue);
    });
  });
}
