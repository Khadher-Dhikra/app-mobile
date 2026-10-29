import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String city;
  final String role;
  final double rating;
  final int reviewCount;
  final String? photoUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.city,
    this.role = 'user',
    this.rating = 5.0,
    this.reviewCount = 0,
    this.photoUrl,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isAdmin => role == 'admin';

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      city: data['city'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'city': city,
      'role': role,
      'rating': rating,
      'reviewCount': reviewCount,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? city,
    String? role,
    double? rating,
    int? reviewCount,
    String? photoUrl,
  }) {
    return UserProfile(
      uid: uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      city: city ?? this.city,
      role: role ?? this.role,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }
}
