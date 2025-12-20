import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;

import '../domain/personalized_study_plan_model.dart';
import '../../../shared/models/user_model.dart';

final studyPlanRepositoryProvider = Provider<StudyPlanRepository>((ref) {
  return StudyPlanRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final activeStudyPlanProvider =
    StreamProvider<PersonalizedStudyPlan?>((ref) {
  final repository = ref.watch(studyPlanRepositoryProvider);
  return repository.getActiveStudyPlan();
});

final studyPlansHistoryProvider =
    StreamProvider<List<PersonalizedStudyPlan>>((ref) {
  final repository = ref.watch(studyPlanRepositoryProvider);
  return repository.getStudyPlansHistory();
});

class StudyPlanRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  genai.GenerativeModel? _model;

  StudyPlanRepository({required this.firestore, required this.auth}) {
    _initGemini();
  }

  void _initGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = genai.GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
    }
  }

  String? get currentUserId => auth.currentUser?.uid;

  /// Aktif çalışma planını getir
  Stream<PersonalizedStudyPlan?> getActiveStudyPlan() {
    if (currentUserId == null) return Stream.value(null);

    return firestore
        .collection('users')
        .doc(currentUserId)
        .collection('personalized_plans')
        .where('targetDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('targetDate', descending: false)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return PersonalizedStudyPlan.fromFirestore(snapshot.docs.first);
        });
  }

  /// Geçmiş planları getir
  Stream<List<PersonalizedStudyPlan>> getStudyPlansHistory() {
    if (currentUserId == null) return Stream.value([]);

    return firestore
        .collection('users')
        .doc(currentUserId)
        .collection('personalized_plans')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PersonalizedStudyPlan.fromFirestore(doc))
            .toList());
  }

  /// AI ile kişiselleştirilmiş plan oluştur
  Future<PersonalizedStudyPlan> generatePersonalizedPlan({
    required UserModel profile,
    required int durationDays,
    required DateTime targetDate,
    required String studyIntensity,
    List<String>? focusSubjects,
    List<String>? weakTopics,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in');
    if (_model == null) throw Exception('Gemini API Key not found');

    // AI'dan plan içeriği ve günlük görevler iste
    final prompt = _buildDetailedPlanPrompt(
      profile: profile,
      durationDays: durationDays,
      targetDate: targetDate,
      studyIntensity: studyIntensity,
      focusSubjects: focusSubjects,
      weakTopics: weakTopics,
    );

    try {
      final contentResponse = await _model!.generateContent([
        genai.Content.text(prompt),
      ]);

      final responseText = contentResponse.text ?? '';

      // Parse AI response
      final planData = _parseAIPlanResponse(responseText, durationDays);

      final plan = PersonalizedStudyPlan(
        id: '',
        userId: currentUserId!,
        durationDays: durationDays,
        startDate: DateTime.now(),
        targetDate: targetDate,
        planContent: planData['overview'] ?? '',
        dailyTasks: planData['dailyTasks'] ?? [],
        studyIntensity: studyIntensity,
        createdAt: DateTime.now(),
        completedDays: 0,
      );

      // Firestore'a kaydet
      final docRef = await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('personalized_plans')
          .add(plan.toFirestore());

      return PersonalizedStudyPlan(
        id: docRef.id,
        userId: plan.userId,
        durationDays: plan.durationDays,
        startDate: plan.startDate,
        targetDate: plan.targetDate,
        planContent: plan.planContent,
        dailyTasks: plan.dailyTasks,
        studyIntensity: plan.studyIntensity,
        createdAt: plan.createdAt,
        completedDays: plan.completedDays,
      );
    } catch (e) {
      print('AI plan generation error: $e');
      rethrow;
    }
  }

  /// Görev tamamlandığında güncelle
  Future<void> completeTaskItem({
    required String planId,
    required int dayIndex,
    required String itemId,
  }) async {
    if (currentUserId == null) return;

    final docRef = firestore
        .collection('users')
        .doc(currentUserId)
        .collection('personalized_plans')
        .doc(planId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final plan = PersonalizedStudyPlan.fromFirestore(doc);
    final updatedTasks = List<DailyTask>.from(plan.dailyTasks);

    if (dayIndex < updatedTasks.length) {
      final task = updatedTasks[dayIndex];
      final updatedItems = task.items.map((item) {
        if (item.id == itemId) {
          return TaskItem(
            id: item.id,
            title: item.title,
            type: item.type,
            estimatedMinutes: item.estimatedMinutes,
            isCompleted: true,
            topicId: item.topicId,
            subjectId: item.subjectId,
          );
        }
        return item;
      }).toList();

      // Tüm görevler tamamlandıysa günü tamamla
      final allCompleted = updatedItems.every((item) => item.isCompleted);

      updatedTasks[dayIndex] = DailyTask(
        dayNumber: task.dayNumber,
        title: task.title,
        description: task.description,
        items: updatedItems,
        isCompleted: allCompleted,
        focusSubject: task.focusSubject,
      );

      final completedDays =
          updatedTasks.where((t) => t.isCompleted).length;

      await docRef.update({
        'dailyTasks': updatedTasks.map((t) => t.toMap()).toList(),
        'completedDays': completedDays,
      });
    }
  }

  /// Günü tamamla
  Future<void> completeDay({
    required String planId,
    required int dayIndex,
  }) async {
    if (currentUserId == null) return;

    final docRef = firestore
        .collection('users')
        .doc(currentUserId)
        .collection('personalized_plans')
        .doc(planId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final plan = PersonalizedStudyPlan.fromFirestore(doc);
    final updatedTasks = List<DailyTask>.from(plan.dailyTasks);

    if (dayIndex < updatedTasks.length) {
      final task = updatedTasks[dayIndex];
      final updatedItems = task.items
          .map((item) => TaskItem(
                id: item.id,
                title: item.title,
                type: item.type,
                estimatedMinutes: item.estimatedMinutes,
                isCompleted: true,
                topicId: item.topicId,
                subjectId: item.subjectId,
              ))
          .toList();

      updatedTasks[dayIndex] = DailyTask(
        dayNumber: task.dayNumber,
        title: task.title,
        description: task.description,
        items: updatedItems,
        isCompleted: true,
        focusSubject: task.focusSubject,
      );

      final completedDays =
          updatedTasks.where((t) => t.isCompleted).length;

      await docRef.update({
        'dailyTasks': updatedTasks.map((t) => t.toMap()).toList(),
        'completedDays': completedDays,
      });
    }
  }

  String _buildDetailedPlanPrompt({
    required UserModel profile,
    required int durationDays,
    required DateTime targetDate,
    required String studyIntensity,
    List<String>? focusSubjects,
    List<String>? weakTopics,
  }) {
    final hoursPerDay = studyIntensity == 'light'
        ? '1-2'
        : studyIntensity == 'medium'
            ? '2-4'
            : '4-6';

    return '''
Sen HMGS (Hukuk Mesleklerine Giriş Sınavı) için uzman bir sınav koçusun.
Aşağıdaki öğrenci profiline göre $durationDays günlük detaylı ve kişiselleştirilmiş bir çalışma planı oluştur.

ÖĞRENCİ PROFİLİ:
- Hedef Meslek: ${profile.targetRoles.join(', ')}
- Sınav Tarihi: ${targetDate.toString().split(' ')[0]}
- Günlük Çalışma Süresi: $hoursPerDay saat
${focusSubjects != null && focusSubjects.isNotEmpty ? '- Odak Dersler: ${focusSubjects.join(', ')}' : ''}
${weakTopics != null && weakTopics.isNotEmpty ? '- Zayıf Konular: ${weakTopics.join(', ')}' : ''}

HMGS MÜFREDATI:
1. Anayasa Hukuku
2. Medeni Hukuk
3. Borçlar Hukuku
4. Ticaret Hukuku
5. Ceza Hukuku
6. Ceza Muhakemesi
7. İdare Hukuku
8. İdari Yargı
9. Vergi Hukuku
10. İcra ve İflas Hukuku

GÖREV:
Aşağıdaki JSON formatında bir çalışma planı oluştur.

ÇIKTI FORMATI (SADECE JSON, AÇIKLAMA YOK):
{
  "overview": "Genel strateji özeti (2-3 cümle)",
  "weeklyFocus": ["Hafta 1: ...", "Hafta 2: ...", ...],
  "dailyTasks": [
    {
      "dayNumber": 1,
      "title": "Gün 1: Anayasa - Temel Haklar",
      "description": "Bugün temel haklar ve özgürlükler konusuna odaklanıyoruz",
      "focusSubject": "Anayasa Hukuku",
      "items": [
        {"id": "1", "title": "Temel Haklar Ders Notu", "type": "lesson", "estimatedMinutes": 45},
        {"id": "2", "title": "10 Soru Quiz", "type": "quiz", "estimatedMinutes": 15},
        {"id": "3", "title": "Konu Tekrarı", "type": "review", "estimatedMinutes": 20}
      ]
    }
  ]
}

KURALLAR:
1. Her gün için 3-5 görev öğesi oluştur
2. Haftada en az 1 deneme sınavı günü olsun
3. Zayıf konulara daha fazla zaman ayır
4. Son hafta sadece tekrar ve deneme olsun
5. Görev türleri: "lesson", "quiz", "review", "exam"
6. Toplam süre günlük $hoursPerDay saat civarında olsun
''';
  }

  Map<String, dynamic> _parseAIPlanResponse(String response, int durationDays) {
    try {
      // JSON'u temizle
      String cleanJson = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final data = json.decode(cleanJson) as Map<String, dynamic>;

      final overview = data['overview'] as String? ?? '';
      final dailyTasksRaw = data['dailyTasks'] as List<dynamic>? ?? [];

      final dailyTasks = dailyTasksRaw.map((taskData) {
        final taskMap = taskData as Map<String, dynamic>;
        final itemsRaw = taskMap['items'] as List<dynamic>? ?? [];

        final items = itemsRaw.map((itemData) {
          final itemMap = itemData as Map<String, dynamic>;
          return TaskItem(
            id: itemMap['id']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            title: itemMap['title'] ?? '',
            type: itemMap['type'] ?? 'lesson',
            estimatedMinutes: itemMap['estimatedMinutes'] ?? 30,
            isCompleted: false,
          );
        }).toList();

        return DailyTask(
          dayNumber: taskMap['dayNumber'] ?? 0,
          title: taskMap['title'] ?? '',
          description: taskMap['description'] ?? '',
          items: items,
          isCompleted: false,
          focusSubject: taskMap['focusSubject'] ?? '',
        );
      }).toList();

      return {
        'overview': overview,
        'dailyTasks': dailyTasks,
      };
    } catch (e) {
      print('Parse error: $e');
      // Fallback: Basit plan oluştur
      return _generateFallbackPlan(durationDays);
    }
  }

  Map<String, dynamic> _generateFallbackPlan(int durationDays) {
    final subjects = [
      'Anayasa Hukuku',
      'Medeni Hukuk',
      'Borçlar Hukuku',
      'Ceza Hukuku',
      'Ticaret Hukuku',
      'İdare Hukuku',
    ];

    final dailyTasks = List.generate(durationDays, (index) {
      final subject = subjects[index % subjects.length];
      final isExamDay = (index + 1) % 7 == 0;

      return DailyTask(
        dayNumber: index + 1,
        title: isExamDay
            ? 'Gün ${index + 1}: Deneme Sınavı'
            : 'Gün ${index + 1}: $subject',
        description: isExamDay
            ? 'Bugün genel tekrar ve deneme sınavı günü'
            : 'Bugün $subject konularına odaklanıyoruz',
        focusSubject: subject,
        isCompleted: false,
        items: isExamDay
            ? [
                TaskItem(
                  id: '${index}_1',
                  title: 'Haftalık Tekrar',
                  type: 'review',
                  estimatedMinutes: 60,
                ),
                TaskItem(
                  id: '${index}_2',
                  title: 'Mini Deneme (30 Soru)',
                  type: 'exam',
                  estimatedMinutes: 45,
                ),
              ]
            : [
                TaskItem(
                  id: '${index}_1',
                  title: '$subject - Ders Çalışma',
                  type: 'lesson',
                  estimatedMinutes: 45,
                ),
                TaskItem(
                  id: '${index}_2',
                  title: '10 Soru Quiz',
                  type: 'quiz',
                  estimatedMinutes: 15,
                ),
                TaskItem(
                  id: '${index}_3',
                  title: 'Konu Özeti Tekrar',
                  type: 'review',
                  estimatedMinutes: 20,
                ),
              ],
      );
    });

    return {
      'overview':
          'Bu plan $durationDays gün boyunca HMGS müfredatını sistematik şekilde çalışmanızı sağlayacak. Her hafta deneme sınavı ile ilerlemenizi ölçün.',
      'dailyTasks': dailyTasks,
    };
  }
}
