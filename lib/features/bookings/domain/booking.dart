import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String rideId;
  final String driverId;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;
  final String? passengerPhotoUrl;
  final int seatsCount;
  final double totalPrice;
  final String departureCity;
  final String arrivalCity;
  final DateTime departureDateTime;
  final String meetingPoint;
  final String status;
  final String? departureCode;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.rideId,
    required this.driverId,
    required this.passengerId,
    required this.passengerName,
    required this.passengerPhone,
    this.passengerPhotoUrl,
    required this.seatsCount,
    required this.totalPrice,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureDateTime,
    required this.meetingPoint,
    this.status = 'pending',
    this.departureCode,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Refusée';
      case 'cancelled':
        return 'Annulée';
      case 'completed':
        return 'Terminée';
      default:
        return status;
    }
  }

  factory Booking.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Booking(
      id: doc.id,
      rideId: data['rideId'] as String? ?? '',
      driverId: data['driverId'] as String? ?? '',
      passengerId: data['passengerId'] as String? ?? '',
      passengerName: data['passengerName'] as String? ?? 'Passager',
      passengerPhone: data['passengerPhone'] as String? ?? '',
      passengerPhotoUrl: data['passengerPhotoUrl'] as String?,
      seatsCount: (data['seatsCount'] as num?)?.toInt() ?? 1,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      departureCity: data['departureCity'] as String? ?? '',
      arrivalCity: data['arrivalCity'] as String? ?? '',
      departureDateTime:
          (data['departureDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      meetingPoint: data['meetingPoint'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      departureCode: data['departureCode'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rideId': rideId,
      'driverId': driverId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      if (passengerPhotoUrl != null) 'passengerPhotoUrl': passengerPhotoUrl,
      'seatsCount': seatsCount,
      'totalPrice': totalPrice,
      'departureCity': departureCity,
      'arrivalCity': arrivalCity,
      'departureDateTime': Timestamp.fromDate(departureDateTime),
      'meetingPoint': meetingPoint,
      'status': status,
      if (departureCode != null) 'departureCode': departureCode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Booking copyWith({
    String? status,
    String? departureCode,
    int? seatsCount,
    double? totalPrice,
  }) {
    return Booking(
      id: id,
      rideId: rideId,
      driverId: driverId,
      passengerId: passengerId,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      passengerPhotoUrl: passengerPhotoUrl,
      seatsCount: seatsCount ?? this.seatsCount,
      totalPrice: totalPrice ?? this.totalPrice,
      departureCity: departureCity,
      arrivalCity: arrivalCity,
      departureDateTime: departureDateTime,
      meetingPoint: meetingPoint,
      status: status ?? this.status,
      departureCode: departureCode ?? this.departureCode,
      createdAt: createdAt,
    );
  }
}
