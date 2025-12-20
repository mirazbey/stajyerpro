import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final List<String> targetRoles;
  final DateTime? examTargetDate;
  final String studyIntensity;
  final String planType; // 'free' | 'pro'
  final bool isAdmin;
  final int targetScore; // Hedef puan (Varsayılan 70)
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.targetRoles,
    this.examTargetDate,
    required this.studyIntensity,
    required this.planType,
    required this.isAdmin,
    this.targetScore = 70,
    required this.createdAt,
    required this.updatedAt,
  });

  // Firestore'dan map'e dönüştür
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'target_roles': targetRoles,
      'exam_target_date': examTargetDate?.toIso8601String(),
      'study_intensity': studyIntensity,
      'plan_type': planType,
      'is_admin': isAdmin,
      'target_score': targetScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Map'ten model oluştur
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      targetRoles: List<String>.from(map['target_roles'] ?? []),
      examTargetDate: map['exam_target_date'] != null
          ? DateTime.parse(map['exam_target_date'])
          : null,
      studyIntensity: map['study_intensity'] ?? 'medium',
      planType: map['plan_type'] ?? 'free',
      isAdmin: map['is_admin'] ?? false,
      targetScore: map['target_score'] ?? 70,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Firestore DocumentSnapshot'tan model oluştur
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    List<String>? targetRoles,
    DateTime? examTargetDate,
    String? studyIntensity,
    String? planType,
    bool? isAdmin,
    int? targetScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      targetRoles: targetRoles ?? this.targetRoles,
      examTargetDate: examTargetDate ?? this.examTargetDate,
      studyIntensity: studyIntensity ?? this.studyIntensity,
      planType: planType ?? this.planType,
      isAdmin: isAdmin ?? this.isAdmin,
      targetScore: targetScore ?? this.targetScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
