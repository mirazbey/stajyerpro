import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/question_model.dart';
import '../data/admin_repository.dart';

class QuestionEditorScreen extends ConsumerStatefulWidget {
  final QuestionModel? question;

  const QuestionEditorScreen({super.key, this.question});

  @override
  ConsumerState<QuestionEditorScreen> createState() =>
      _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends ConsumerState<QuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _stemController;
  late List<TextEditingController> _optionControllers;
  late TextEditingController _subjectIdController;
  late TextEditingController _topicIdsController;
  late TextEditingController _lawArticleController;
  late TextEditingController _detailedExplanationController;
  late List<TextEditingController> _wrongReasonControllers;
  late TextEditingController _relatedCasesController;
  late TextEditingController _yearController;
  late TextEditingController _tagsController;

  int _correctIndex = 0;
  String _difficulty = 'medium';
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final q = widget.question;

    _stemController = TextEditingController(text: q?.stem ?? '');

    _optionControllers = List.generate(
      5,
      (i) => TextEditingController(
        text: q != null && i < q.options.length ? q.options[i] : '',
      ),
    );

    _subjectIdController = TextEditingController(text: q?.subjectId ?? '');
    _topicIdsController = TextEditingController(
      text: q?.topicIds.join(', ') ?? '',
    );

    _lawArticleController = TextEditingController(text: q?.lawArticle ?? '');
    _detailedExplanationController = TextEditingController(
      text: q?.detailedExplanation ?? '',
    );

    _wrongReasonControllers = List.generate(
      5,
      (i) => TextEditingController(text: q?.wrongReasons?[i] ?? ''),
    );

    _relatedCasesController = TextEditingController(
      text: q?.relatedCases?.join(', ') ?? '',
    );
    _yearController = TextEditingController(text: q?.year?.toString() ?? '');
    _tagsController = TextEditingController(text: q?.tags?.join(', ') ?? '');

    _correctIndex = q?.correctIndex ?? 0;
    _difficulty = q?.difficulty ?? 'medium';
  }

  @override
  void dispose() {
    _stemController.dispose();
    for (var c in _optionControllers) c.dispose();
    _subjectIdController.dispose();
    _topicIdsController.dispose();
    _lawArticleController.dispose();
    _detailedExplanationController.dispose();
    for (var c in _wrongReasonControllers) c.dispose();
    _relatedCasesController.dispose();
    _yearController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);

    try {
      final options = _optionControllers.map((c) => c.text.trim()).toList();

      final wrongReasons = <int, String>{};
      for (int i = 0; i < 5; i++) {
        if (_wrongReasonControllers[i].text.isNotEmpty) {
          wrongReasons[i] = _wrongReasonControllers[i].text.trim();
        }
      }

      final relatedCases = _relatedCasesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final topicIds = _topicIdsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final year = int.tryParse(_yearController.text.trim());

      final newQuestion = QuestionModel(
        id: widget.question?.id ?? '',
        stem: _stemController.text.trim(),
        options: options,
        correctIndex: _correctIndex,
        subjectId: _subjectIdController.text.trim(),
        topicIds: topicIds,
        difficulty: _difficulty,
        lawArticle: _lawArticleController.text.trim().isEmpty
            ? null
            : _lawArticleController.text.trim(),
        detailedExplanation: _detailedExplanationController.text.trim().isEmpty
            ? null
            : _detailedExplanationController.text.trim(),
        wrongReasons: wrongReasons.isEmpty ? null : wrongReasons,
        relatedCases: relatedCases.isEmpty ? null : relatedCases,
        year: year,
        tags: tags.isEmpty ? null : tags,
        createdAt: widget.question?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(adminRepositoryProvider);
      if (widget.question == null) {
        await repo.addQuestion(newQuestion);
      } else {
        await repo.updateQuestion(newQuestion);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Soru kaydedildi')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.question == null ? 'Yeni Soru' : 'Soruyu Düzenle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isBusy ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Temel Bilgiler
            const Text(
              'Temel Bilgiler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stemController,
              decoration: const InputDecoration(
                labelText: 'Soru Metni',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (v) => v?.isEmpty == true ? 'Zorunlu' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _subjectIdController,
                    decoration: const InputDecoration(
                      labelText: 'Ders ID (örn: medeni)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Zorunlu' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _topicIdsController,
                    decoration: const InputDecoration(
                      labelText: 'Konu IDleri (Virgülle ayırın)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: const InputDecoration(
                labelText: 'Zorluk',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'easy', child: Text('Kolay')),
                DropdownMenuItem(value: 'medium', child: Text('Orta')),
                DropdownMenuItem(value: 'hard', child: Text('Zor')),
              ],
              onChanged: (v) => setState(() => _difficulty = v!),
            ),

            const SizedBox(height: 24),
            const Text(
              'Şıklar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: _correctIndex,
                      onChanged: (v) => setState(() => _correctIndex = v!),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Şık ${String.fromCharCode(65 + index)}',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => v?.isEmpty == true ? 'Zorunlu' : null,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            const Text(
              'Detaylı Açıklama & Çözüm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lawArticleController,
              decoration: const InputDecoration(
                labelText: 'Kanun Maddesi (örn: TMK m. 123)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailedExplanationController,
              decoration: const InputDecoration(
                labelText: 'Detaylı Çözüm Açıklaması',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            const Text(
              'Yanlış Şık Açıklamaları (Opsiyonel)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...List.generate(5, (index) {
              if (index == _correctIndex) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextFormField(
                  controller: _wrongReasonControllers[index],
                  decoration: InputDecoration(
                    labelText:
                        'Şık ${String.fromCharCode(65 + index)} Neden Yanlış?',
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
            const Text(
              'Ek Bilgiler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _relatedCasesController,
              decoration: const InputDecoration(
                labelText: 'Emsal Kararlar (Virgülle ayırın)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: 'Yıl',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Etiketler (Virgülle ayırın)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isBusy ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Kaydet'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
