import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../domain/study_plan_model.dart';
import 'widgets/edit_session_dialog.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/premium_glass_container.dart';

class StudyPlanScreen extends ConsumerStatefulWidget {
  final StudyPlan plan;

  const StudyPlanScreen({super.key, required this.plan});

  @override
  ConsumerState<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends ConsumerState<StudyPlanScreen> {
  late PageController _pageController;
  DateTime _selectedDate = DateTime.now();
  bool _isLocaleInitialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
    _selectedDate = widget.plan.startDate;
    initializeDateFormatting('tr_TR', null).then((_) {
      if (mounted) {
        setState(() {
          _isLocaleInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSessionTap(StudySession session) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditSessionDialog(session: session),
    );

    if (result != null) {
      setState(() {
        session.subject = result['subject'];
        session.duration = result['duration'];
        session.isNotificationOn = result['isNotificationOn'];
        session.notificationTime = result['notificationTime'];
      });

      // Schedule notification if enabled
      if (session.isNotificationOn) {
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.init();
        await notificationService.requestPermissions();

        // Create notification at specified date and time
        final scheduledDateTime = DateTime(
          session.date.year,
          session.date.month,
          session.date.day,
          session.notificationTime.hour,
          session.notificationTime.minute,
        );

        // Only schedule if in the future
        if (scheduledDateTime.isAfter(DateTime.now())) {
          await notificationService.scheduleDailyReminder(
            id: session.id.hashCode,
            title: "📚 Çalışma Zamanı!",
            body: "${session.subject} - ${session.duration}",
            time: session.notificationTime,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Bildirim ${session.notificationTime.format(context)} için ayarlandı",
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: DesignTokens.primary,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleInitialized) {
      return const Scaffold(
        backgroundColor: DesignTokens.background,
        body: Center(
          child: CircularProgressIndicator(color: DesignTokens.accent),
        ),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.plan.name,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Slate 900
                  Color(0xFF1E293B), // Slate 800
                  Color(0xFF0F172A), // Slate 900
                ],
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Notification Banner
                _buildNotificationBanner(),

                const SizedBox(height: 24),
                // Date Picker Strip
                _buildDatePicker(),

                const SizedBox(height: 24),
                // Study Plan Carousel
                Expanded(child: _buildCarousel()),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBanner() {
    return PremiumGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      borderRadius: 30,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_active,
            color: DesignTokens.accent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            "Bildirim saatini gösteren banner: 08:00",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.plan.sessions.length,
        itemBuilder: (context, index) {
          final session = widget.plan.sessions[index];
          final isSelected = DateUtils.isSameDay(session.date, _selectedDate);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = session.date;
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? DesignTokens.primary.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? DesignTokens.primary
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'tr_TR').format(session.date),
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? DesignTokens.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      session.date.day.toString(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarousel() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _selectedDate = widget.plan.sessions[index].date;
        });
      },
      itemCount: widget.plan.sessions.length,
      itemBuilder: (context, index) {
        final session = widget.plan.sessions[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GestureDetector(
            onTap: () => _onSessionTap(session),
            child: _buildGlassCard(session),
          ),
        );
      },
    );
  }

  Widget _buildGlassCard(StudySession session) {
    return PremiumGlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Column(
            children: [
              Text(
                DateFormat('EEEE, d MMMM', 'tr_TR').format(session.date),
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                session.subject,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                "(Düzenlemek için dokun)",
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),

          // Center: Circular Progress
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 12.0,
            percent: session.progress,
            center: Text(
              "%${(session.progress * 100).toInt()}",
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            progressColor: DesignTokens.primary,
            backgroundColor: Colors.white10,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animateFromLastPercent: true,
          ),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hedef Süre",
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.duration,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: session.isNotificationOn
                      ? DesignTokens.primary
                      : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: session.isNotificationOn
                      ? [
                          BoxShadow(
                            color: DesignTokens.primary.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.notifications,
                  color: session.isNotificationOn
                      ? Colors.white
                      : Colors.white54,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
