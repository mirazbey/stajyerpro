import 'package:flutter/material.dart';

enum BadgeConditionType {
  examCount, // Toplam deneme sayısı
  streak, // Günlük seri
  score, // Belirli bir puanın üstü
  topicMastery, // Bir konuyu bitirme
  firstWin, // İlk başarı
}

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconPath; // Asset path for the badge icon
  final BadgeConditionType conditionType;
  final int conditionValue;
  final Color color;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.conditionType,
    required this.conditionValue,
    this.color = Colors.amber,
  });

  // Predefined Badges
  static const List<BadgeModel> allBadges = [
    BadgeModel(
      id: 'first_exam',
      name: 'İlk Adım',
      description: 'İlk deneme sınavını tamamla',
      iconPath: 'assets/badges/first_exam.png',
      conditionType: BadgeConditionType.examCount,
      conditionValue: 1,
      color: Colors.blue,
    ),
    BadgeModel(
      id: 'exam_master_10',
      name: 'Çırak',
      description: '10 deneme sınavı tamamla',
      iconPath: 'assets/badges/exam_master_10.png',
      conditionType: BadgeConditionType.examCount,
      conditionValue: 10,
      color: Colors.indigo,
    ),
    BadgeModel(
      id: 'score_80',
      name: 'Yüksek Başarı',
      description: 'Bir denemede 80+ puan al',
      iconPath: 'assets/badges/score_80.png',
      conditionType: BadgeConditionType.score,
      conditionValue: 80,
      color: Colors.orange,
    ),
    BadgeModel(
      id: 'streak_7',
      name: 'İstikrarlı',
      description: '7 gün üst üste çalış',
      iconPath: 'assets/badges/streak_7.png',
      conditionType: BadgeConditionType.streak,
      conditionValue: 7,
      color: Colors.purple,
    ),
    BadgeModel(
      id: 'streak_30',
      name: 'Azimli',
      description: '30 gün üst üste çalış',
      iconPath: 'assets/badges/streak_30.png',
      conditionType: BadgeConditionType.streak,
      conditionValue: 30,
      color: Colors.red,
    ),
  ];
}
