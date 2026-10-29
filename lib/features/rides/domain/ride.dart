import 'package:cloud_firestore/cloud_firestore.dart';

class Ride {
  final String id;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final double driverRating;
  final String? driverPhotoUrl;
  final String departureCity;
  final String arrivalCity;
  final DateTime departureDateTime;
  final String meetingPoint;
  final int totalSeats;
  final int availableSeats;
  final double pricePerSeat;
  final String carModel;
  final String? notes;
  final String status;
  final DateTime createdAt;

  const Ride({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    this.driverRating = 5.0,
    this.driverPhotoUrl,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureDateTime,
    required this.meetingPoint,
    required this.totalSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.carModel,
    this.notes,
    this.status = 'active',
    required this.createdAt,
  });

  bool get isFull => availableSeats <= 0;
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get isActive => status == 'active';
  bool get isPast => departureDateTime.isBefore(DateTime.now());

  bool canBeEditedOrCancelled(String currentUserId) {
    return driverId == currentUserId && isActive && !isPast;
  }

  factory Ride.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Ride(
      id: doc.id,
      driverId: data['driverId'] as String? ?? '',
      driverName: data['driverName'] as String? ?? 'Conducteur',
      driverPhone: data['driverPhone'] as String? ?? '',
      driverRating: (data['driverRating'] as num?)?.toDouble() ?? 5.0,
      driverPhotoUrl: data['driverPhotoUrl'] as String?,
      departureCity: data['departureCity'] as String? ?? '',
      arrivalCity: data['arrivalCity'] as String? ?? '',
      departureDateTime:
          (data['departureDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      meetingPoint: data['meetingPoint'] as String? ?? '',
      totalSeats: (data['totalSeats'] as num?)?.toInt() ?? 1,
      availableSeats: (data['availableSeats'] as num?)?.toInt() ?? 0,
      pricePerSeat: (data['pricePerSeat'] as num?)?.toDouble() ?? 0.0,
      carModel: data['carModel'] as String? ?? '',
      notes: data['notes'] as String?,
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverRating': driverRating,
      if (driverPhotoUrl != null) 'driverPhotoUrl': driverPhotoUrl,
      'departureCity': departureCity,
      'arrivalCity': arrivalCity,
      'departureDateTime': Timestamp.fromDate(departureDateTime),
      'meetingPoint': meetingPoint,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'pricePerSeat': pricePerSeat,
      'carModel': carModel,
      if (notes != null) 'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Ride copyWith({
    String? driverName,
    String? driverPhone,
    double? driverRating,
    String? driverPhotoUrl,
    String? departureCity,
    String? arrivalCity,
    DateTime? departureDateTime,
    String? meetingPoint,
    int? totalSeats,
    int? availableSeats,
    double? pricePerSeat,
    String? carModel,
    String? notes,
    String? status,
  }) {
    return Ride(
      id: id,
      driverId: driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverRating: driverRating ?? this.driverRating,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      departureCity: departureCity ?? this.departureCity,
      arrivalCity: arrivalCity ?? this.arrivalCity,
      departureDateTime: departureDateTime ?? this.departureDateTime,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      carModel: carModel ?? this.carModel,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
