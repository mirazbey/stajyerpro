import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/question_model.dart';
import '../data/admin_repository.dart';

class QuestionListScreen extends ConsumerStatefulWidget {
  const QuestionListScreen({super.key});

  @override
  ConsumerState<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends ConsumerState<QuestionListScreen> {
  final List<QuestionModel> _questions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  // ignore: unused_field

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _questions.clear();
      _hasMore = true;
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(adminRepositoryProvider);
      // Not: Pagination için DocumentSnapshot gerekiyor ama şimdilik basit tutalım
      // Repository'yi biraz güncelleyip startAfterDocument yerine startAfter (value) kullanabiliriz
      // veya doğrudan repo metodunu çağırabiliriz.
      // Şimdilik pagination'ı basitleştirip sadece ilk 50 soruyu çekelim.
      // Gerçek pagination için repository metodunu güncellemek gerekebilir.

      final newQuestions = await repo.getQuestions(limit: 50);

      setState(() {
        _questions.addAll(newQuestions);
        if (newQuestions.length < 50) {
          _hasMore = false;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soruyu Sil'),
        content: const Text('Bu soruyu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminRepositoryProvider).deleteQuestion(questionId);
        setState(() {
          _questions.removeWhere((q) => q.id == questionId);
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Soru silindi')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soru Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadQuestions(refresh: true),
          ),
        ],
      ),
      body: _questions.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _questions.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _questions.length) {
                  return _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : TextButton(
                          onPressed: _loadQuestions,
                          child: const Text('Daha Fazla Yükle'),
                        );
                }

                final question = _questions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(
                      question.stem,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${question.subjectId} - ${question.difficulty}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            context.push(
                              '/admin/questions/edit',
                              extra: question,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteQuestion(question.id),
                        ),
                      ],
                    ),
                    onTap: () {
                      context.push('/admin/questions/edit', extra: question);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/admin/questions/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
