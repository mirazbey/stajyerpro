import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stajyerpro_app/core/theme/design_tokens.dart';
import 'package:stajyerpro_app/shared/widgets/premium_glass_container.dart';
import 'settings_controller.dart';
import 'notification_settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final notificationSettingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Ayarlar',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'KİŞİSELLEŞTİRME'),
            const SizedBox(height: 16),
            settingsAsync.when(
              data: (settings) => _SettingsCard(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Performans Modu',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Animasyonları azaltarak pil ömrünü uzatır',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    value: settings.performanceMode,
                    activeColor: DesignTokens.accent,
                    onChanged: (value) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .togglePerformanceMode(value);
                    },
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),
            _SectionHeader(title: 'BİLDİRİMLER'),
            const SizedBox(height: 16),
            notificationSettingsAsync.when(
              data: (settings) => _SettingsCard(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Günlük Hatırlatıcı',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      settings.isEnabled
                          ? 'Her gün ${settings.reminderTime.format(context)}'
                          : 'Kapalı',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    value: settings.isEnabled,
                    activeColor: DesignTokens.accent,
                    onChanged: (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleNotifications(value);
                    },
                  ),
                  if (settings.isEnabled)
                    ListTile(
                      title: const Text(
                        'Hatırlatma Saati',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          settings.reminderTime.format(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () async {
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
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),
            _SectionHeader(title: 'UYGULAMA'),
            const SizedBox(height: 16),
            _SettingsCard(
              children: [
                ListTile(
                  title: const Text(
                    'Hakkında',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
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
                const Divider(color: Colors.white10),
                ListTile(
                  title: const Text(
                    'Yardım ve Destek',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Destek sayfası yakında eklenecek...'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: DesignTokens.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return PremiumGlassContainer(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}
