import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/background_wrapper.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: BackgroundWrapper(
        imagePath: 'assets/images/yenigorseller/Paywall.png',
        opacity: 0.22,
        child: Container(
          decoration: const BoxDecoration(
            gradient: DesignTokens.primaryGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(DesignTokens.s16),
                    child: Column(
                      children: [
                        _buildHeroSection(context),
                        const SizedBox(height: DesignTokens.s32),
                        _buildPricingSection(context),
                        const SizedBox(height: DesignTokens.s32),
                        _buildFeaturesList(context),
                        const SizedBox(height: DesignTokens.s32),
                        _buildComparisonTable(context),
                        const SizedBox(height: DesignTokens.s32),
                        _buildFooter(context),
                        const SizedBox(height: DesignTokens.s24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Satın almalar geri yükleniyor...'),
                ),
              );
            },
            child: Text(
              'Geri Yükle',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accent.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/paywall_hero.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: DesignTokens.s24),
        Text(
          'StajyerPro Premium',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.s8),
        Text(
          'Sınırları kaldır, hedefine daha hızlı ulaş.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.8)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPricingSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PricingCard(
            title: 'Haftalık',
            price: '129',
            period: 'hafta',
            isPopular: false,
            onTap: () => _showPurchaseDialog(context, 'Haftalık', '129'),
          ),
        ),
        const SizedBox(width: DesignTokens.s16),
        Expanded(
          child: _PricingCard(
            title: 'Yıllık',
            price: '999',
            period: 'yıl',
            isPopular: true,
            savings: '%35 Tasarruf',
            onTap: () => _showPurchaseDialog(context, 'Yıllık', '999'),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    return GlassContainer(
      color: Colors.white,
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Text(
              'Premium Avantajları',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _BenefitItem(
            icon: Icons.all_inclusive,
            title: 'Sınırsız Soru Çözümü',
            description: 'Günlük limitlere takılmadan çalış.',
          ),
          _BenefitItem(
            icon: Icons.psychology,
            title: 'Gelişmiş AI Koç',
            description: 'Detaylı konu anlatımı ve soru analizi.',
          ),
          _BenefitItem(
            icon: Icons.assignment,
            title: 'Sınırsız Deneme',
            description: 'Gerçek sınav deneyimini istediğin kadar yaşa.',
          ),
          _BenefitItem(
            icon: Icons.block,
            title: 'Reklamsız',
            description: 'Sadece dersine odaklan.',
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
          child: Text(
            'Karşılaştırma',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        GlassContainer(
          color: Colors.white,
          opacity: 0.95,
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade200),
            ),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: const [
              TableRow(
                children: [
                  _TableCell('Özellik', isHeader: true),
                  _TableCell('Free', isHeader: true),
                  _TableCell('Pro', isHeader: true, isHighlighted: true),
                ],
              ),
              TableRow(
                children: [
                  _TableCell('Günlük Soru'),
                  _TableCell('40'),
                  _TableCell('Sınırsız', isHighlighted: true),
                ],
              ),
              TableRow(
                children: [
                  _TableCell('AI Hakkı'),
                  _TableCell('5/gün'),
                  _TableCell('200/gün', isHighlighted: true),
                ],
              ),
              TableRow(
                children: [
                  _TableCell('Deneme'),
                  _TableCell('1/ay'),
                  _TableCell('30/ay', isHighlighted: true),
                ],
              ),
              TableRow(
                children: [
                  _TableCell('Reklam'),
                  _TableCell('Var'),
                  _TableCell('Yok', isHighlighted: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          'İstediğiniz zaman iptal edebilirsiniz.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: DesignTokens.s8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: Text(
                'Kullanım Koşulları',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ),
            Text('|', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            TextButton(
              onPressed: () {},
              child: Text(
                'Gizlilik Politikası',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPurchaseDialog(BuildContext context, String plan, String price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.r16),
        ),
        title: Text('$plan Paket'),
        content: Text('Sanal satın alma işlemi: $price TL\nOnaylıyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Satın alma başarılı! (Simülasyon)'),
                  backgroundColor: DesignTokens.success,
                ),
              );
            },
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final bool isPopular;
  final String? savings;
  final VoidCallback onTap;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    required this.isPopular,
    this.savings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppCard(
          onTap: onTap,
          backgroundColor: Colors.white,
          border: isPopular
              ? Border.all(color: DesignTokens.accent, width: 2)
              : null,
          child: Column(
            children: [
              if (isPopular) const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.textSecondary,
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '₺',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '/$period',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.textTertiary,
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              CustomButton(
                text: 'Seç',
                onPressed: onTap,
                variant: isPopular
                    ? ButtonVariant.primary
                    : ButtonVariant.ghost,
                isFullWidth: true,
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.accent,
                  borderRadius: BorderRadius.circular(DesignTokens.rFull),
                  boxShadow: DesignTokens.shadowSm,
                ),
                child: const Text(
                  'En Popüler',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        if (savings != null)
          Positioned(
            bottom: -8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.success,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  savings!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: DesignTokens.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
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

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isHighlighted;

  const _TableCell(
    this.text, {
    this.isHeader = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader || isHighlighted
              ? FontWeight.bold
              : FontWeight.normal,
          color: isHighlighted
              ? DesignTokens.primary
              : DesignTokens.textPrimary,
          fontSize: isHeader ? 14 : 13,
        ),
      ),
    );
  }
}
