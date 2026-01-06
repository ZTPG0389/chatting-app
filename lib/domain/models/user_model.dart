import 'dart:core';

class UserModel {
  final String uid;
  final String phone;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.createdAt,
  });

  /// Firestore → Model
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      createdAt: map['createdAt']?.toDate(),
    );
  }

  /// Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'createdAt': createdAt,
    };
  }
}
