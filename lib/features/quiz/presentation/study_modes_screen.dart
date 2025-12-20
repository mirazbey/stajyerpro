import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudyModesScreen extends StatelessWidget {
  const StudyModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Çalışma Modları')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ModeCard(
            title: '⚡ Hızlı Test',
            description: '20 soru, 25 dakika\nRastgele karma konular',
            color: Colors.orange,
            onTap: () {
              context.push(
                '/quiz/start',
                extra: {
                  'mode': 'fast',
                  'questionCount': 20,
                  'timeLimit': 25 * 60, // 25 dakika (saniye cinsinden)
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _ModeCard(
            title: '🏃 Maraton Modu',
            description: 'Sınırsız soru\nNe kadar dayanabilirsin?',
            color: Colors.purple,
            onTap: () {
              context.push(
                '/quiz/start',
                extra: {
                  'mode': 'marathon',
                  'questionCount': 999, // Sınırsız için büyük sayı
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _ModeCard(
            title: '📚 Konu Bazlı Test',
            description: 'Konuları seç ve çalış\nKlasik mod',
            color: Colors.blue,
            onTap: () {
              context.push('/quiz/setup');
            },
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
