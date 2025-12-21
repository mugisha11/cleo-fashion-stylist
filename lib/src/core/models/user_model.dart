import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final OnboardingData? onboardingData;
  final String? avatarUrl;
  final String? avatarModelUrl; // GLB/GLTF URL

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.onboardingData,
    this.avatarUrl,
    this.avatarModelUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      onboardingData: data['onboardingData'] != null
          ? OnboardingData.fromMap(data['onboardingData'] as Map<String, dynamic>)
          : null,
      avatarUrl: data['avatarUrl'] as String?,
      avatarModelUrl: data['avatarModelUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'onboardingData': onboardingData?.toMap(),
      'avatarUrl': avatarUrl,
      'avatarModelUrl': avatarModelUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    OnboardingData? onboardingData,
    String? avatarUrl,
    String? avatarModelUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      onboardingData: onboardingData ?? this.onboardingData,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarModelUrl: avatarModelUrl ?? this.avatarModelUrl,
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, createdAt, onboardingData, avatarUrl, avatarModelUrl];
}

class OnboardingData extends Equatable {
  final String fashionStyle;
  final String favoriteColors;
  final String occasion;
  final String budget;
  final String shoppingFrequency;
  final String styleInspiration;
  final BodyInputs bodyInputs;

  const OnboardingData({
    required this.fashionStyle,
    required this.favoriteColors,
    required this.occasion,
    required this.budget,
    required this.shoppingFrequency,
    required this.styleInspiration,
    required this.bodyInputs,
  });

  factory OnboardingData.fromMap(Map<String, dynamic> map) {
    return OnboardingData(
      fashionStyle: map['fashionStyle'] as String,
      favoriteColors: map['favoriteColors'] as String,
      occasion: map['occasion'] as String,
      budget: map['budget'] as String,
      shoppingFrequency: map['shoppingFrequency'] as String,
      styleInspiration: map['styleInspiration'] as String,
      bodyInputs: BodyInputs.fromMap(map['bodyInputs'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fashionStyle': fashionStyle,
      'favoriteColors': favoriteColors,
      'occasion': occasion,
      'budget': budget,
      'shoppingFrequency': shoppingFrequency,
      'styleInspiration': styleInspiration,
      'bodyInputs': bodyInputs.toMap(),
    };
  }

  @override
  List<Object?> get props => [
        fashionStyle,
        favoriteColors,
        occasion,
        budget,
        shoppingFrequency,
        styleInspiration,
        bodyInputs,
      ];
}

class BodyInputs extends Equatable {
  final double height; // in cm
  final String gender;
  final String bodyType;

  const BodyInputs({
    required this.height,
    required this.gender,
    required this.bodyType,
  });

  factory BodyInputs.fromMap(Map<String, dynamic> map) {
    return BodyInputs(
      height: (map['height'] as num).toDouble(),
      gender: map['gender'] as String,
      bodyType: map['bodyType'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'height': height,
      'gender': gender,
      'bodyType': bodyType,
    };
  }

  @override
  List<Object?> get props => [height, gender, bodyType];
}

