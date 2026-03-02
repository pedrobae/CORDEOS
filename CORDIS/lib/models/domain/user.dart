import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordis/models/dtos/user_dto.dart';

class User {
  final int? id;
  final String? firebaseId;
  final String username;
  final String email;
  final String? profilePhoto;
  final String? language;
  final String? timeZone;
  final String? country;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const User({
    this.id,
    required this.firebaseId,
    required this.username,
    required this.email,
    this.profilePhoto,
    this.language,
    this.timeZone,
    this.country,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory User.fromSqlite(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      firebaseId: json['firebase_id'] as String?,
      username: json['username'] as String,
      email: json['email'] as String,
      profilePhoto: json['profile_photo'] as String?,
      language: json['language'] as String?,
      timeZone: json['time_zone'] as String?,
      country: json['country'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int)
          : null,
      isActive: (json['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toSQLite() {
    return {
      'username': username,
      'email': email,
      'profile_photo': profilePhoto,
      'firebase_id': firebaseId,
      'language': language,
      'time_zone': timeZone,
      'country': country,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  UserDto toDto() {
    return UserDto(
      firebaseId: firebaseId,
      username: username,
      email: email,
      profilePhoto: profilePhoto,
      language: language,
      timeZone: timeZone,
      country: country,
      createdAt: Timestamp.fromDate(createdAt ?? DateTime.now()),
      updatedAt: Timestamp.fromDate(updatedAt ?? DateTime.now()),
      isActive: isActive,
    );
  }

  User mergeWith(User other) {
    return User(
      id: id,
      firebaseId: firebaseId ?? other.firebaseId,
      username: username.isNotEmpty ? username : other.username,
      email: email.isNotEmpty ? email : other.email,
      profilePhoto: profilePhoto ?? other.profilePhoto,
      language: language ?? other.language,
      timeZone: timeZone ?? other.timeZone,
      country: country ?? other.country,
      createdAt: createdAt ?? other.createdAt,
      updatedAt: updatedAt ?? other.updatedAt,
      isActive: isActive,
    );
  }

  User copyWith({
    int? id,
    String? firebaseId,
    String? username,
    String? email,
    String? profilePhoto,
    String? language,
    String? timeZone,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      language: language ?? this.language,
      timeZone: timeZone ?? this.timeZone,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
