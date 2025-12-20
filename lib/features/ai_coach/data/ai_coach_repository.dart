import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;
import 'dart:math' as math;
import 'dart:convert';
import '../../../shared/models/chat_model.dart';
import '../../../shared/models/question_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/lesson_step_model.dart';

final aiCoachRepositoryProvider = Provider<AICoachRepository>((ref) {
  return AICoachRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class AICoachRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  genai.GenerativeModel? _model;
  genai.GenerativeModel? _embeddingModel;

  AICoachRepository({required this.firestore, required this.auth}) {
    _initGemini();
  }

  void _initGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = genai.GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
      _embeddingModel = genai.GenerativeModel(
        model: 'embedding-001',
        apiKey: apiKey,
      );
    }
  }

  String? get currentUserId => auth.currentUser?.uid;

  /// Yeni chat session oluştur
  Future<String> createChatSession() async {
    if (currentUserId == null) throw Exception('User not logged in');

    final session = ChatSession(
      id: '',
      userId: currentUserId!,
      title: 'Yeni Sohbet',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chat_sessions')
        .add(session.toFirestore());

    return docRef.id;
  }

  /// Kullanıcının chat sessions'ını getir
  Stream<List<ChatSession>> getChatSessions() {
    if (currentUserId == null) return Stream.value([]);

    return firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chat_sessions')
        .orderBy('updatedAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatSession.fromFirestore(doc))
              .toList(),
        );
  }

  /// Belirli bir session'ın mesajlarını getir
  Stream<List<ChatMessage>> getMessages(String sessionId) {
    if (currentUserId == null) return Stream.value([]);

    return firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  /// Mesaj gönder ve AI yanıtı al
  Future<void> sendMessage({
    required String sessionId,
    required String content,
    QuestionModel? question,
    int? userAnswer,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in');
    if (_model == null) throw Exception('Gemini API Key not found');

    // Check daily AI request limit
    final hasLimit = await _checkAndIncrementAILimit();
    if (!hasLimit) {
      throw Exception(
        'Günlük AI sorgu limitine ulaştınız. Pro üyelik alarak limiti artırabilirsiniz.',
      );
    }

    // Save user message
    final userMessage = ChatMessage(
      id: '',
      userId: currentUserId!,
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
      questionId: question?.id,
    );

    await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .add(userMessage.toFirestore());

    try {
      // 1. RAG: Retrieve relevant context
      String context = '';
      if (question == null) {
        context = await _findRelevantContext(content);
      }

      // 2. Build Prompt
      final prompt = _buildPrompt(
        userMessage: content,
        question: question,
        userAnswer: userAnswer,
        context: context,
      );

      // 3. Generate Response
      final contentResponse = await _model!.generateContent([
        genai.Content.text(prompt),
      ]);
      final aiResponseText = contentResponse.text ?? 'Yanıt alınamadı.';

      // Save AI message
      final aiMessage = ChatMessage(
        id: '',
        userId: currentUserId!,
        role: 'assistant',
        content: aiResponseText,
        createdAt: DateTime.now(),
        questionId: question?.id,
      );

      await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .add(aiMessage.toFirestore());

      // Update session title if first message
      final messages = await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .get();

      if (messages.docs.length == 2) {
        // First exchange
        await firestore
            .collection('users')
            .doc(currentUserId)
            .collection('chat_sessions')
            .doc(sessionId)
            .update({
              'title': content.length > 50
                  ? '${content.substring(0, 50)}...'
                  : content,
              'updatedAt': DateTime.now(),
            });
      } else {
        // Update timestamp
        await firestore
            .collection('users')
            .doc(currentUserId)
            .collection('chat_sessions')
            .doc(sessionId)
            .update({'updatedAt': DateTime.now()});
      }
    } catch (e) {
      print('AI error: $e');
      // Save error message
      final errorMessage = ChatMessage(
        id: '',
        userId: currentUserId!,
        role: 'assistant',
        content: 'Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin. ($e)',
        createdAt: DateTime.now(),
      );

      await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .add(errorMessage.toFirestore());

      rethrow;
    }
  }

  /// RAG: Find relevant context from Firestore
  Future<String> _findRelevantContext(String query) async {
    if (_embeddingModel == null) return '';

    try {
      // 1. Generate embedding for query
      final embeddingResponse = await _embeddingModel!.embedContent(
        genai.Content.text(query),
        taskType: genai.TaskType.retrievalQuery,
      );
      final queryVector = embeddingResponse.embedding.values;

      if (queryVector.isEmpty) return '';

      // 2. Fetch all knowledge base documents
      final snapshot = await firestore.collection('knowledge_base').get();

      if (snapshot.docs.isEmpty) return '';

      // 3. Calculate Cosine Similarity
      final scoredDocs = snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure embedding is List<double>
        final rawEmbedding = data['embedding'];
        if (rawEmbedding == null) return MapEntry(doc, -1.0);

        final embedding = (rawEmbedding as List)
            .map((e) => (e as num).toDouble())
            .toList();

        final similarity = _cosineSimilarity(queryVector, embedding);
        return MapEntry(doc, similarity);
      }).toList();

      // 4. Sort by similarity (descending)
      scoredDocs.sort((a, b) => b.value.compareTo(a.value));

      // 5. Take top 3
      final topDocs = scoredDocs.take(3).toList();

      // 6. Construct Context String
      final contextBuffer = StringBuffer();
      contextBuffer.writeln('İLGİLİ HUKUKİ KAYNAKLAR:');
      for (var entry in topDocs) {
        if (entry.value > 0.6) {
          // Threshold for relevance
          final content = entry.key.data()['content'] as String;
          contextBuffer.writeln('- $content\n');
        }
      }

      return contextBuffer.toString();
    } catch (e) {
      print('RAG Error: $e');
      return ''; // Fail gracefully without context
    }
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0.0;

    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Soru açıklama talebi için özel method
  Future<String> getQuestionExplanation({
    required QuestionModel question,
    required int userAnswer,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in');
    if (_model == null) throw Exception('Gemini API Key not found');

    // Check daily AI request limit
    final hasLimit = await _checkAndIncrementAILimit();
    if (!hasLimit) {
      throw Exception('Günlük AI sorgu limitine ulaştınız.');
    }

    final prompt = _buildQuestionExplanationPrompt(
      question: question,
      userAnswer: userAnswer,
    );

    try {
      final contentResponse = await _model!.generateContent([
        genai.Content.text(prompt),
      ]);
      final response = contentResponse.text ?? 'Yanıt alınamadı.';

      // Log to ai_sessions
      await firestore.collection('ai_sessions').add({
        'userId': currentUserId,
        'type': 'question_explanation',
        'questionId': question.id,
        'userAnswer': userAnswer,
        'correctAnswer': question.correctIndex,
        'response': response,
        'createdAt': DateTime.now(),
      });

      return response;
    } catch (e) {
      print('AI error: $e');
      rethrow;
    }
  }

  /// Kısa AI ipucu üretir ve cache'ler
  Future<String?> getQuestionTip({required QuestionModel question}) async {
    if (currentUserId == null) throw Exception('User not logged in');
    if (_model == null) throw Exception('Gemini API Key not found');

    if (question.aiTip != null && question.aiTip!.isNotEmpty) {
      return question.aiTip;
    }

    final hasLimit = await _checkAndIncrementAILimit();
    if (!hasLimit) {
      throw Exception('Günlük AI sorgu limitine ulaştınız.');
    }

    final prompt = _buildQuestionTipPrompt(question);

    try {
      final contentResponse = await _model!.generateContent([
        genai.Content.text(prompt),
      ]);
      final tip = contentResponse.text?.trim();

      if (tip != null && tip.isNotEmpty) {
        try {
          await firestore.collection('questions').doc(question.id).update({
            'aiTip': tip,
            'updatedAt': DateTime.now(),
          });
        } catch (_) {
          // Cache yazılamasa bile ipucunu döndür
        }
      }

      return tip;
    } catch (e) {
      print('AI tip error: $e');
      rethrow;
    }
  }

  /// Çalışma planı oluştur
  Future<String> generateStudyPlan({
    required UserModel profile,
    required int durationDays,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in');
    if (_model == null) throw Exception('Gemini API Key not found');

    final prompt = _buildStudyPlanPrompt(profile, durationDays);

    try {
      final contentResponse = await _model!.generateContent([
        genai.Content.text(prompt),
      ]);
      final response = contentResponse.text ?? 'Yanıt alınamadı.';

      // Save plan to Firestore
      await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('study_plans')
          .add({
            'durationDays': durationDays,
            'planContent': response,
            'createdAt': DateTime.now(),
            'targetDate': profile.examTargetDate != null
                ? Timestamp.fromDate(profile.examTargetDate!)
                : null,
          });

      return response;
    } catch (e) {
      print('AI error: $e');
      rethrow;
    }
  }

  /// Build prompt for study plan
  String _buildStudyPlanPrompt(UserModel profile, int durationDays) {
    return '''
Sen HMGS (Hukuk Mesleklerine Giriş Sınavı) için uzman bir sınav koçusun.
Aşağıdaki öğrenci profiline göre $durationDays günlük detaylı bir çalışma planı oluştur.

ÖĞRENCİ PROFİLİ:
- Hedef: ${profile.targetRoles.join(', ')}
- Sınav Tarihi: ${profile.examTargetDate != null ? profile.examTargetDate.toString().split(' ')[0] : 'Belirtilmemiş'}
- Çalışma Yoğunluğu: ${profile.studyIntensity} (light: 1-2 saat, moderate: 2-4 saat, intense: 4+ saat)

GÖREV:
HMGS müfredatındaki dersleri (Medeni, Borçlar, Ceza, Anayasa, İdare vb.) kapsayan, dengeli ve gerçekçi bir plan hazırla.
Plan şunları içermeli:
1. Genel Strateji (kısa özet)
2. Haftalık Odak Konuları (Hafta 1, Hafta 2...)
3. Günlük Rutin Önerisi (Sabah/Akşam ne çalışmalı)
4. Tekrar ve Deneme Sınavı günleri

ÇIKTI FORMATI:
Markdown formatında, okunaklı ve motive edici bir dille yaz.
''';
  }

  /// Generate curriculum JSON
  Future<List<Map<String, dynamic>>> generateCurriculumJson({
    required String subjectName,
    String? contextText,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in');
    if (_model == null) throw Exception('Gemini API Key not found');

    final prompt =
        '''
Sen HMGS (Hakim ve Savcı Meslek Sınavı) için uzman bir müfredat planlayıcısısın.
GÖREV: "$subjectName" dersi için hiyerarşik bir konu ağacı oluştur.

${contextText != null ? 'KAYNAK METİN:\n$contextText\n\n' : ''}

KURALLAR:
1. Çıktı SADECE geçerli bir JSON array olmalıdır.
2. Markdown, açıklama veya kod bloğu (```json) EKLEME. Sadece raw JSON.
3. Hiyerarşi yapısı:
   - name: Konu Adı
   - description: Kısa açıklama
   - subtopics: [Alt Konular listesi (aynı yapıda)]

ÖRNEK ÇIKTI:
[
  {
    "name": "Başlangıç Hükümleri",
    "description": "Temel ilkeler",
    "subtopics": [
      {
        "name": "Dürüstlük Kuralı",
        "description": "MK m.2 kapsamı",
        "subtopics": []
      }
    ]
  }
]
''';

    try {
      final contentResponse = await _model!.generateContent([
        genai.Content.text(prompt),
      ]);

      String responseText = contentResponse.text ?? '[]';

      // Clean up markdown if present
      responseText = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final List<dynamic> jsonList = jsonDecode(responseText);
      return List<Map<String, dynamic>>.from(jsonList);
    } catch (e) {
      print('AI Curriculum Error: $e');
      rethrow;
    }
  }

  /// Generate topic content (Summary + Questions)
  Future<Map<String, dynamic>> generateTopicContentJson({
    required String topicName,
    required String subjectName,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in');
    if (_model == null) throw Exception('Gemini API Key not found');

    final prompt =
        '''
Sen HMGS (Hakim ve Savcı Meslek Sınavı) için uzman bir hukuk eğitmenisin.
GÖREV: "$subjectName" dersinin "$topicName" konusu için detaylı bir ders içeriği ve pekiştirme soruları hazırla.

ÇIKTI FORMATI (JSON):
{
  "summary": "MARKDOWN FORMATINDA KONU ÖZETİ. En az 500 kelime. Başlıklar (#), maddeler (-), kalın (**), italik (*) kullan. Önemli uyarılar için > [!WARNING] veya > [!NOTE] kullan.",
  "questions": [
    {
      "text": "Soru metni",
      "options": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı", "E şıkkı"],
      "correctAnswerIndex": 0,
      "explanation": "Detaylı çözüm açıklaması",
      "lawArticle": "İlgili kanun maddesi (örn. MK m.2)"
    }
  ]
}

KURALLAR:
1. "questions" dizisinde TAM OLARAK 10 adet soru olmalı.
2. Sorular zorluk derecesine göre (Kolay -> Zor) sıralanmalı.
3. Çıktı SADECE geçerli bir JSON olmalı. Markdown code block (```json) kullanma.
''';

    try {
      final contentResponse = await _model!.generateContent([
        genai.Content.text(prompt),
      ]);

      String responseText = contentResponse.text ?? '{}';
      responseText = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(responseText) as Map<String, dynamic>;
    } catch (e) {
      print('AI Content Error: $e');
      rethrow;
    }
  }

  /// Generate summary for a topic
  Future<String> generateTopicSummary({
    required String topicName,
    required String subjectName,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in');
    if (_model == null) throw Exception('Gemini API Key not found');

    // Check daily AI request limit
    final hasLimit = await _checkAndIncrementAILimit();
    if (!hasLimit) {
      throw Exception('Günlük AI sorgu limitine ulaştınız.');
    }

    final prompt = _buildTopicSummaryPrompt(topicName, subjectName);

    try {
      final contentResponse = await _model!.generateContent([
        genai.Content.text(prompt),
      ]);
      final response = contentResponse.text ?? 'Özet oluşturulamadı.';

      // Log to ai_sessions
      await firestore.collection('ai_sessions').add({
        'userId': currentUserId,
        'type': 'topic_summary',
        'topicName': topicName,
        'subjectName': subjectName,
        'response': response,
        'createdAt': DateTime.now(),
      });

      return response;
    } catch (e) {
      print('AI error: $e');
      rethrow;
    }
  }

  String _buildTopicSummaryPrompt(String topicName, String subjectName) {
    return '''
Sen HMGS (Hakim ve Savcı Meslek Sınavı) için uzman bir eğitmensin.
Aşağıdaki konu için sınav odaklı, kısa ve öz bir çalışma kartı hazırla.

DERS: $subjectName
KONU: $topicName

İSTENEN FORMAT (Markdown):
# $topicName

## 📌 Tanım ve Kapsam
(Konunun kısa, net tanımı. 2-3 cümle.)

## ⚖️ Kritik Kanun Maddeleri
- **Madde X:** ...
- **Madde Y:** ...

## 🎯 Sınavda Dikkat Edilmesi Gerekenler
- (ÖSYM'nin sık sorduğu noktalar)
- (Karıştırılan kavramlar)

## 💡 Örnek Olay / Pratik Bilgi
(Kısa bir örnek veya akılda kalıcı bir ipucu)

NOT: Sadece sınavda çıkabilecek önemli noktalara odaklan. Gereksiz detaylardan kaçın.
''';
  }

  /// Build prompt for general chat
  String _buildPrompt({
    required String userMessage,
    QuestionModel? question,
    int? userAnswer,
    String context = '',
  }) {
    if (question != null && userAnswer != null) {
      return _buildQuestionExplanationPrompt(
        question: question,
        userAnswer: userAnswer,
      );
    }

    return '''
Sen HMGS (Hakim ve Savcı Meslek Sınavı) hazırlık yapan adaylara yardımcı olan bir AI koçusun. 
Görevin, sınav odaklı açıklamalar yapmak ve öğrencilere rehberlik etmektir.

$context

ÖNEMLİ UYARILAR:
- Kesinlikle hukuki danışmanlık verme.
- Sadece sınav hazırlığı için öğretici açıklamalar yap.
- Madde numaraları ve hukuk kavramlarını doğru kullan.
- Eğer yukarıda "İLGİLİ HUKUKİ KAYNAKLAR" verilmişse, cevabını öncelikle bu kaynaklara dayandır.
- Kısa ve net ol.

KULLANICI SORUSU:
$userMessage

CEVAP:
''';
  }

  /// Build prompt for question explanation
  String _buildQuestionExplanationPrompt({
    required QuestionModel question,
    required int userAnswer,
  }) {
    final optionLabels = ['A', 'B', 'C', 'D', 'E'];
    final userAnswerLabel = optionLabels[userAnswer];
    final correctAnswerLabel = optionLabels[question.correctIndex];

    return '''
Sen HMGS (Hakim ve Savcı Meslek Sınavı) soruları hakkında açıklama yapan bir AI koçusun.

SORU:
${question.stem}

ŞIKlar:
${question.options.asMap().entries.map((e) => '${optionLabels[e.key]}) ${e.value}').join('\n')}

KULLANICININ CEVABI: $userAnswerLabel
DOĞRU CEVAP: $correctAnswerLabel

GÖREV:
1. Doğru cevabı açıkla (hangi madde, hangi mantık).
2. ${userAnswer != question.correctIndex ? 'Kullanıcının yanlış cevabını neden yanlış olduğunu açıkla.' : 'Kullanıcının doğru cevabını teyit et.'}
3. Konu ile ilgili tipik tuzakları belirt.
4. Kısa ve net ol (maksimum 200 kelime).

ÖNEMLİ: Bu açıklama sınav hazırlığı amaçlıdır, hukuki danışmanlık değildir.

AÇIKLAMA:
''';
  }

  String _buildQuestionTipPrompt(QuestionModel question) {
    final buffer = StringBuffer();
    buffer.writeln('Sen HMGS için deneyimli bir sınav koçusun.');
    buffer.writeln('Görev: 1-2 cümlede, hafızada kalıcı ve pratik bir ipucu üret.');
    buffer.writeln('Asla doğru cevabı veya şık harfini söyleme.');
    buffer.writeln('Soruyu ve şıkları oku, öğrencinin dikkat etmesi gereken kavramı vurgula.');
    buffer.writeln('Türkçe ve sade yaz.');
    buffer.writeln('Soru: ${question.stem}');
    for (int i = 0; i < question.options.length; i++) {
      buffer.writeln('Seçenek ${String.fromCharCode(65 + i)}: ${question.options[i]}');
    }
    return buffer.toString();
  }

  /// Check and increment daily AI limit
  Future<bool> _checkAndIncrementAILimit() async {
    if (currentUserId == null) return false;

    final userDoc = await firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    final planType = userDoc.data()?['plan_type'] ?? 'free';

    // Pro users have high limit
    if (planType == 'pro') {
      return true;
    }

    // Free users: check daily limit
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final dailyStatsDoc = await firestore
        .collection('daily_stats')
        .doc('${currentUserId}_$todayKey')
        .get();

    final aiRequests = dailyStatsDoc.data()?['ai_requests'] ?? 0;
    const freeLimit = 5; // Free: 5 AI requests per day

    if (aiRequests >= freeLimit) {
      return false;
    }

    // Increment counter
    await firestore
        .collection('daily_stats')
        .doc('${currentUserId}_$todayKey')
        .set({
          'ai_requests': FieldValue.increment(1),
          'date': todayKey,
          'updatedAt': DateTime.now(),
        }, SetOptions(merge: true));

    return true;
  }

  /// Get today's AI request count
  Future<int> getTodayAIRequestCount() async {
    if (currentUserId == null) return 0;

    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final doc = await firestore
        .collection('daily_stats')
        .doc('${currentUserId}_$todayKey')
        .get();

    return doc.data()?['ai_requests'] ?? 0;
  }

  /// Mikro-öğrenme adımları oluştur (5 Hap Bilgi + 2'şer Soru)
  Future<List<LessonStepModel>> generateLessonSteps({
    required String topicName,
    required String subjectName,
    int stepCount = 5,
    int questionsPerStep = 2,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in');
    if (_model == null) throw Exception('Gemini API Key not found');

    // Check daily AI request limit
    final hasLimit = await _checkAndIncrementAILimit();
    if (!hasLimit) {
      throw Exception('Günlük AI sorgu limitine ulaştınız.');
    }

    final prompt = _buildLessonStepsPrompt(
      topicName: topicName,
      subjectName: subjectName,
      stepCount: stepCount,
      questionsPerStep: questionsPerStep,
    );

    try {
      final contentResponse = await _model!.generateContent([
        genai.Content.text(prompt),
      ]);

      String responseText = contentResponse.text ?? '[]';
      
      // Clean up markdown if present
      responseText = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final List<dynamic> jsonList = jsonDecode(responseText);
      
      final steps = <LessonStepModel>[];
      for (int i = 0; i < jsonList.length; i++) {
        final stepData = jsonList[i] as Map<String, dynamic>;
        final questionsData = stepData['questions'] as List<dynamic>;
        
        final questions = questionsData.asMap().entries.map((entry) {
          final q = entry.value as Map<String, dynamic>;
          return StepQuestion(
            id: 'q_${i}_${entry.key}',
            questionText: q['text'] as String,
            options: List<String>.from(q['options'] as List),
            correctIndex: q['correctIndex'] as int,
            explanation: q['explanation'] as String?,
          );
        }).toList();

        steps.add(LessonStepModel(
          stepNumber: i + 1,
          title: stepData['title'] as String,
          content: stepData['content'] as String,
          questions: questions,
        ));
      }

      // Log to ai_sessions
      await firestore.collection('ai_sessions').add({
        'userId': currentUserId,
        'type': 'lesson_steps',
        'topicName': topicName,
        'subjectName': subjectName,
        'stepCount': steps.length,
        'createdAt': DateTime.now(),
      });

      return steps;
    } catch (e) {
      print('AI Lesson Steps Error: $e');
      rethrow;
    }
  }

  String _buildLessonStepsPrompt({
    required String topicName,
    required String subjectName,
    required int stepCount,
    required int questionsPerStep,
  }) {
    return '''
Sen HMGS (Hakim ve Savcı Meslek Sınavı) için uzman bir hukuk eğitmenisin.
"$subjectName" dersinin "$topicName" konusu için $stepCount aşamalı, ETKİLİ MİKRO-ÖĞRENME içeriği hazırla.

🎯 ÖĞRENME TASARIMI PRENSİPLERİ:
- Her adım GÖRSEL OLARAK ZENGİN olmalı (emoji, madde, tablo kullan)
- Kavramları MANTIKSAL İZAH ile açıkla (neden böyle? felsefesi ne?)
- AKILDA KALICI teknikler kullan (kısaltma, hikaye, benzetme)
- Kritik noktaları VURGULA (⚠️ DİKKAT, 💡 İPUCU, ⚖️ KANUN)

📋 HER ADIM ŞUNLARI İÇERMELİ:
1. Başlık (kısa, akılda kalıcı)
2. İçerik (Zengin Markdown formatında, 200-250 kelime)
3. $questionsPerStep pekiştirme sorusu

📝 İÇERİK FORMATI (her adım için):
## 📌 Ana Kavram
Kısa tanım (1-2 cümle)

## 🧠 Mantıksal İzah
> "Neden böyle?" sorusunun cevabı. Hukukun mantığını açıkla.

## ⚖️ Kritik Hükümler
| Madde | İçerik | Sınav İpucu |
|-------|--------|-------------|
| m.X | ... | Dikkat: ... |

## 🎯 Ezber Tekniği
**Kısaltma/Formül:** ...
*Örnek: "3T Kuralı = Tebliğ, Tefhim, Tescil"*

## ⚠️ Sık Yapılan Hatalar
- ❌ Yanlış: ...
- ✅ Doğru: ...

ÇIKTI FORMATI (SADECE JSON, markdown code block KULLANMA):
[
  {
    "title": "Akılda kalıcı başlık (emoji ile)",
    "content": "Yukarıdaki formatta zengin markdown içerik",
    "questions": [
      {
        "text": "Soru metni",
        "options": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı"],
        "correctIndex": 0,
        "explanation": "Detaylı açıklama + ilgili kanun maddesi + neden diğerleri yanlış"
      }
    ]
  }
]

ADIM YAPISI ($stepCount adım):
1️⃣ Temel Kavram: Tanım + Tarihçe/Felsefe
2️⃣ Hukuki Çerçeve: Kanun maddeleri + Şartlar
3️⃣ Uygulama: Örnekler + İstisnalar  
4️⃣ Karşılaştırma: Benzer kavramlarla fark
5️⃣ Sınav Stratejisi: Tuzaklar + İpuçları

KRİTİK KURALLAR:
1. Düz yazı YASAK, mutlaka madde/tablo/emoji kullan
2. Her kavramın NEDEN öyle olduğunu açıkla
3. Sorularda 4 şık olsun, açıklama detaylı olsun
4. ÇIKTI SADECE JSON OLMALI
''';
  }

}


