import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PlanType { free, pro }

class SubscriptionLimits {
  final int quizPerDay;
  final int aiPerDay;
  final int examPerMonth;
  final bool adsEnabled;

  const SubscriptionLimits({
    required this.quizPerDay,
    required this.aiPerDay,
    required this.examPerMonth,
    required this.adsEnabled,
  });
}

const SubscriptionLimits freeLimits = SubscriptionLimits(
  quizPerDay: 40,
  aiPerDay: 5,
  examPerMonth: 1,
  adsEnabled: true,
);

const SubscriptionLimits proLimits = SubscriptionLimits(
  quizPerDay: 1000000,
  aiPerDay: 1000000,
  examPerMonth: 1000000,
  adsEnabled: false,
);

class SubscriptionState {
  final PlanType plan;
  final SubscriptionLimits limits;

  const SubscriptionState({
    required this.plan,
    required this.limits,
  });
}

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class SubscriptionService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  SubscriptionService({
    required this.firestore,
    required this.auth,
  });

  Future<SubscriptionState> getState() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return const SubscriptionState(plan: PlanType.free, limits: freeLimits);
    }

    try {
      final userDoc = await firestore.collection('users').doc(uid).get();
      final data = userDoc.data() ?? {};
      final planType = (data['plan_type'] ?? data['planType'] ?? 'free') as String;
      final plan = planType.toLowerCase() == 'pro' ? PlanType.pro : PlanType.free;
      return SubscriptionState(plan: plan, limits: plan == PlanType.pro ? proLimits : freeLimits);
    } catch (_) {
      return const SubscriptionState(plan: PlanType.free, limits: freeLimits);
    }
  }

  String _dateKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _monthKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  DocumentReference<Map<String, dynamic>> _todayStatsRef(String uid) {
    final docId = '${uid}_${_dateKey()}';
    return firestore.collection('daily_stats').doc(docId);
  }

  Future<Map<String, dynamic>> _loadTodayStats(String uid) async {
    final doc = await _todayStatsRef(uid).get();
    return doc.data() ?? {};
  }

  Future<bool> canStartQuiz(int requestedQuestions) async {
    final uid = auth.currentUser?.uid;
    final state = await getState();
    if (state.plan == PlanType.pro) return true;
    if (uid == null) return requestedQuestions <= state.limits.quizPerDay;

    final stats = await _loadTodayStats(uid);
    final solved = (stats['questions_solved'] ?? 0) as int;
    return solved + requestedQuestions <= state.limits.quizPerDay;
  }

  Future<void> recordQuizUsage(int answeredCount) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _todayStatsRef(uid);
    await ref.set({
      'user_id': uid,
      'date': _dateKey(),
      'questions_solved': FieldValue.increment(answeredCount),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> canUseAi() async {
    final uid = auth.currentUser?.uid;
    final state = await getState();
    if (state.plan == PlanType.pro) return true;
    if (uid == null) return false;

    final stats = await _loadTodayStats(uid);
    final used = (stats['ai_requests'] ?? 0) as int;
    return used < state.limits.aiPerDay;
  }

  Future<void> recordAiUsage() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _todayStatsRef(uid);
    await ref.set({
          'user_id': uid,
          'date': _dateKey(),
          'ai_requests': FieldValue.increment(1),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
  }

  Future<bool> canStartExam() async {
    final uid = auth.currentUser?.uid;
    final state = await getState();
    if (state.plan == PlanType.pro) return true;
    if (uid == null) return false;

    final key = _monthKey();
    final doc = await firestore.collection('exam_usage').doc('${uid}_${key}').get();
    final used = (doc.data()?['count'] ?? 0) as int;
    return used < state.limits.examPerMonth;
  }

  Future<void> recordExamUsage() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    final key = _monthKey();
    await firestore.collection('exam_usage').doc('${uid}_${key}').set({
          'user_id': uid,
          'month': key,
          'count': FieldValue.increment(1),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
