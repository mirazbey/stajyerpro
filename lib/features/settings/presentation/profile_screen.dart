import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import 'notification_settings_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final profileAsync = ref.watch(userProfileStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil bulunamadı'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _ProfileHeader(
                  profileName: profile.name,
                  email: user?.email,
                  planType: profile.planType,
                ),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Profil Bilgileri'),
                _InfoCard(
                  icon: Icons.gavel,
                  label: 'Hedef Rol',
                  value: profile.targetRoles.isNotEmpty
                      ? _getRoleDisplay(profile.targetRoles[0])
                      : 'Belirtilmemiş',
                ),
                _InfoCard(
                  icon: Icons.calendar_today,
                  label: 'Sınav Tarihi',
                  value: profile.examTargetDate != null
                      ? '${profile.examTargetDate!.day}/${profile.examTargetDate!.month}/${profile.examTargetDate!.year}'
                      : 'Belirtilmemiş',
                  onTap: () =>
                      _showExamDatePicker(context, ref, profile.examTargetDate),
                ),
                _InfoCard(
                  icon: Icons.flag,
                  label: 'Hedef Puan',
                  value: '${profile.targetScore}',
                  onTap: () =>
                      _showTargetScoreDialog(context, ref, profile.targetScore),
                ),
                _InfoCard(
                  icon: Icons.fitness_center,
                  label: 'Çalışma Yoğunluğu',
                  value: _getIntensityDisplay(profile.studyIntensity),
                ),
                const SizedBox(height: 24),
                if (profile.planType != 'pro')
                  _SubscriptionCard(onPaywall: () => context.push('/paywall')),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Ayarlar'),
                Consumer(
                  builder: (context, ref, child) {
                    final settingsAsync = ref.watch(
                      notificationSettingsProvider,
                    );
                    return settingsAsync.when(
                      data: (settings) => _SettingsTile(
                        icon: Icons.notifications,
                        title: 'Bildirimler',
                        subtitle: settings.isEnabled
                            ? 'Her gün ${settings.reminderTime.format(context)}'
                            : 'Kapalı',
                        onTap: () =>
                            _showNotificationSettings(context, ref, settings),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox(),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.dark_mode,
                  title: 'Tema',
                  subtitle: 'Açık/Koyu mod',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tema ayarları yakında eklenecek...'),
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.help,
                  title: 'Yardım ve Destek',
                  subtitle: 'SSS ve iletişim',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Destek sayfası yakında eklenecek...'),
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.info,
                  title: 'Hakkında',
                  subtitle: 'Sürüm ve bilgiler',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'StajyerPro',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'Bu uygulama hukuki danışmanlık vermez.\n\n(c) 2024 StajyerPro',
                    );
                  },
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(Icons.logout),
                    label: const Text('Çıkış Yap'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
      ),
    );
  }

  void _showExamDatePicker(
    BuildContext context,
    WidgetRef ref,
    DateTime? currentDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'HMGS Sınav Tarihini Seçin',
      cancelText: 'İptal',
      confirmText: 'Kaydet',
    );

    if (picked != null && context.mounted) {
      try {
        await ref.read(profileRepositoryProvider).updateProfile({
          'exam_target_date': picked.toIso8601String(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sınav tarihi ${picked.day}/${picked.month}/${picked.year} olarak güncellendi',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tarih güncellenirken hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showTargetScoreDialog(
    BuildContext context,
    WidgetRef ref,
    int currentScore,
  ) {
    int selectedScore = currentScore;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Hedef Puan Belirle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$selectedScore',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: selectedScore.toDouble(),
                min: 50,
                max: 100,
                divisions: 50,
                label: selectedScore.toString(),
                onChanged: (value) {
                  setState(() {
                    selectedScore = value.round();
                  });
                },
              ),
              const Text(
                'HMGS Baraj Puanı: 70',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await ref.read(profileRepositoryProvider).updateProfile({
                    'target_score': selectedScore,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Hedef puan $selectedScore olarak güncellendi',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hedef puan güncellenirken hata oluştu'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings(
    BuildContext context,
    WidgetRef ref,
    NotificationSettingsState settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirim Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bildirimleri Etkinleştir'),
              value: settings.isEnabled,
              onChanged: (value) {
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleNotifications(value);
              },
            ),
            if (settings.isEnabled) ...[
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hatırlatıcı Saati'),
                trailing: Text(
                  settings.reminderTime.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final TimeOfDay? newTime = await showTimePicker(
                    context: context,
                    initialTime: settings.reminderTime,
                  );
                  if (newTime != null) {
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .updateTime(newTime);
                  }
                },
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                context.go('/splash');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String profileName;
  final String? email;
  final String planType;

  const _ProfileHeader({
    required this.profileName,
    required this.email,
    required this.planType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade700,
            ),
            child: const Icon(Icons.person, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            profileName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email ?? '',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: planType == 'pro'
                  ? Colors.amber
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  planType == 'pro' ? Icons.workspace_premium : Icons.person,
                  size: 16,
                  color: planType == 'pro' ? Colors.black : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  planType == 'pro' ? 'Pro üye' : 'Free üye',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: planType == 'pro' ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final VoidCallback onPaywall;

  const _SubscriptionCard({required this.onPaywall});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Pro'ya geçin",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Limitsiz özelliklerle HMGS'ye hazırlanın",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPaywall,
                  style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                  child: const Text('Pro özellikleri gör'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.edit, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

String _getRoleDisplay(String role) {
  switch (role) {
    case 'lawyer':
      return 'Avukat';
    case 'judge':
      return 'Hakim';
    case 'prosecutor':
      return 'Savcı';
    case 'notary':
      return 'Noter';
    default:
      return role;
  }
}

String _getIntensityDisplay(String intensity) {
  switch (intensity) {
    case 'light':
      return 'Hafif (1-2 saat/gün)';
    case 'moderate':
      return 'Orta (2-4 saat/gün)';
    case 'intense':
      return 'Yoğun (4+ saat/gün)';
    default:
      return intensity;
  }
}
