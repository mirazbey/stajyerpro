import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/study_plan_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../analytics/data/analytics_repository.dart';

class CreateStudyPlanScreen extends ConsumerStatefulWidget {
  const CreateStudyPlanScreen({super.key});

  @override
  ConsumerState<CreateStudyPlanScreen> createState() =>
      _CreateStudyPlanScreenState();
}

class _CreateStudyPlanScreenState extends ConsumerState<CreateStudyPlanScreen> {
  int _currentStep = 0;
  bool _isGenerating = false;

  // Step 1: Hedef Tarih
  DateTime? _targetDate;

  // Step 2: Çalışma Yoğunluğu
  String _studyIntensity = 'medium';

  // Step 3: Odak Dersler (opsiyonel)
  final List<String> _selectedSubjects = [];

  final _subjects = [
    'Anayasa Hukuku',
    'Medeni Hukuk',
    'Borçlar Hukuku',
    'Ticaret Hukuku',
    'Ceza Hukuku',
    'Ceza Muhakemesi',
    'İdare Hukuku',
    'İdari Yargı',
    'Vergi Hukuku',
    'İcra ve İflas Hukuku',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),

              // Progress Indicator
              _buildProgressIndicator(),

              // Content
              Expanded(
                child: _isGenerating
                    ? _buildGeneratingState()
                    : _buildStepContent(),
              ),

              // Bottom Buttons
              if (!_isGenerating) _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Çalışma Planı Oluştur',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF3B82F6)
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              color: isActive ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: isCompleted
                          ? const Color(0xFF3B82F6)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDateStep();
      case 1:
        return _buildIntensityStep();
      case 2:
        return _buildSubjectsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDateStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sınav Tarihin Ne Zaman?',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hedef tarihine göre kişiselleştirilmiş bir plan oluşturacağız.',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Date Picker Card
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _targetDate != null
                      ? const Color(0xFF3B82F6)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF3B82F6),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _targetDate != null
                              ? DateFormat('d MMMM yyyy', 'tr_TR')
                                  .format(_targetDate!)
                              : 'Tarih Seç',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_targetDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_targetDate!.difference(DateTime.now()).inDays} gün kaldı',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Select Options
          Text(
            'Hızlı Seçim',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickDateChip('30 Gün', 30),
              _buildQuickDateChip('60 Gün', 60),
              _buildQuickDateChip('90 Gün', 90),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateChip(String label, int days) {
    final date = DateTime.now().add(Duration(days: days));
    final isSelected = _targetDate != null &&
        _targetDate!.difference(DateTime.now()).inDays == days;

    return GestureDetector(
      onTap: () {
        setState(() {
          _targetDate = date;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildIntensityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Günde Kaç Saat Çalışabilirsin?',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Gerçekçi bir hedef koyarak planına sadık kalman kolaylaşır.',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildIntensityOption(
            'light',
            'Hafif',
            '1-2 saat/gün',
            'Yoğun bir programın varsa ideal',
            Icons.wb_sunny_outlined,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          _buildIntensityOption(
            'medium',
            'Orta',
            '2-4 saat/gün',
            'Dengeli ve sürdürülebilir tempo',
            Icons.wb_twilight,
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 16),
          _buildIntensityOption(
            'intense',
            'Yoğun',
            '4-6 saat/gün',
            'Sınav yakınsa tam gaz!',
            Icons.local_fire_department,
            const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityOption(
    String value,
    String title,
    String subtitle,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _studyIntensity == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _studyIntensity = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsStep() {
    final weakTopicsAsync = ref.watch(weakTopicsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hangi Derslere Odaklanmak İstiyorsun?',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Seçmezsen tüm dersler dengeli şekilde planlanır.',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Weak Topics Suggestion
          weakTopicsAsync.when(
            data: (weakTopics) {
              if (weakTopics.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Zayıf olduğun ${weakTopics.length} konu tespit edildi. Bu konuları da dahil edebilirsin.',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Subject Grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _subjects.map((subject) {
              final isSelected = _selectedSubjects.contains(subject);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSubjects.remove(subject);
                    } else {
                      _selectedSubjects.add(subject);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        subject,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF3B82F6),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Planın Hazırlanıyor...',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'AI koçun senin için kişiselleştirilmiş\nbir çalışma planı oluşturuyor.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Geri',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceed() ? _handleNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withOpacity(0.1),
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == 2 ? 'Plan Oluştur' : 'Devam Et',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _targetDate != null;
      case 1:
        return _studyIntensity.isNotEmpty;
      case 2:
        return true; // Opsiyonel
      default:
        return false;
    }
  }

  void _handleNext() async {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Generate plan
      await _generatePlan();
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              surface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _targetDate = date;
      });
    }
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final profile = await ref.read(userProfileProvider.future);
      if (profile == null) throw Exception('Profil bulunamadı');

      final repository = ref.read(studyPlanRepositoryProvider);
      final durationDays = _targetDate!.difference(DateTime.now()).inDays;

      final weakTopics = await ref.read(weakTopicsProvider.future);
      final weakTopicNames = weakTopics.map((t) => t.topicName).toList();

      await repository.generatePersonalizedPlan(
        profile: profile,
        durationDays: durationDays,
        targetDate: _targetDate!,
        studyIntensity: _studyIntensity,
        focusSubjects: _selectedSubjects.isNotEmpty ? _selectedSubjects : null,
        weakTopics: weakTopicNames.isNotEmpty ? weakTopicNames : null,
      );

      if (mounted) {
        context.go('/study-plan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan oluşturulurken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}
