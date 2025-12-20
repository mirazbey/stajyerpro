import 'package:cloud_firestore/cloud_firestore.dart';

class UserBadgeModel {
  final String userId;
  final String badgeId;
  final DateTime earnedAt;

  UserBadgeModel({
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'badgeId': badgeId,
      'earnedAt': Timestamp.fromDate(earnedAt),
    };
  }

  factory UserBadgeModel.fromMap(Map<String, dynamic> map) {
    return UserBadgeModel(
      userId: map['userId'] ?? '',
      badgeId: map['badgeId'] ?? '',
      earnedAt: (map['earnedAt'] as Timestamp).toDate(),
    );
  }
}
