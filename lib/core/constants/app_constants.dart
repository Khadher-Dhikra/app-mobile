class AppConstants {
  static const String appName = 'TAWSILA';
  static const String appTagline = 'Covoiturage interurbain en Tunisie';
  static const String currency = 'TND';

  // Team
  static const List<String> authors = ['Dhikra Khadher', 'Eya Boukadida'];
  static const String supervisor = 'Sabrine Brahmi';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String ridesCollection = 'rides';
  static const String bookingsCollection = 'bookings';
  static const String tripSessionsCollection = 'trip_sessions';
  static const String reportsCollection = 'reports';
  static const String reviewsCollection = 'reviews';

  // Booking Statuses
  static const String bookingStatusPending = 'pending';
  static const String bookingStatusAccepted = 'accepted';
  static const String bookingStatusRejected = 'rejected';
  static const String bookingStatusCancelled = 'cancelled';
  static const String bookingStatusCompleted = 'completed';

  // Ride Statuses
  static const String rideStatusActive = 'active';
  static const String rideStatusCompleted = 'completed';
  static const String rideStatusCancelled = 'cancelled';
}
