import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/study_plan_model.dart';

class EditSessionDialog extends StatefulWidget {
  final StudySession session;

  const EditSessionDialog({super.key, required this.session});

  @override
  State<EditSessionDialog> createState() => _EditSessionDialogState();
}

class _EditSessionDialogState extends State<EditSessionDialog> {
  static const List<String> _predefinedSubjects = [
    "Anayasa Hukuku",
    "Medeni Hukuk",
    "Ceza Hukuku",
    "İdare Hukuku",
    "Borçlar Hukuku",
    "Ticaret Hukuku",
    "İcra ve İflas",
  ];

  late String _selectedSubject;
  late TextEditingController _customSubjectController;
  late TextEditingController _durationController;
  late bool _isNotificationOn;
  late TimeOfDay _notificationTime;
  bool _isCustomSubject = false;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.session.subject;
    _customSubjectController = TextEditingController();
    _durationController = TextEditingController(text: widget.session.duration);
    _isNotificationOn = widget.session.isNotificationOn;
    _notificationTime = widget.session.notificationTime;

    // Check if current subject is predefined or custom
    if (!_predefinedSubjects.contains(_selectedSubject) &&
        _selectedSubject != "Konu Belirlenmedi") {
      _isCustomSubject = true;
      _customSubjectController.text = _selectedSubject;
    }
  }

  @override
  void dispose() {
    _customSubjectController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _selectSubject(String subject) {
    setState(() {
      _selectedSubject = subject;
      _isCustomSubject = false;
      _customSubjectController.clear();
    });
  }

  void _openCustomSubject() {
    setState(() {
      _isCustomSubject = true;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Color(0xFF0F172A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0F172A),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _notificationTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dersi Düzenle",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subject Label
                  Text(
                    "Ders Konusu",
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subject Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._predefinedSubjects.map(
                        (subject) => _buildSubjectChip(subject),
                      ),
                      _buildCustomChip(),
                    ],
                  ),

                  // Custom Subject Input
                  if (_isCustomSubject) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customSubjectController,
                      autofocus: true,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: _buildInputDecoration("Özel Konu Adı"),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Duration
                  TextFormField(
                    controller: _durationController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: _buildInputDecoration("Süre (Örn: 2 saat)"),
                  ),
                  const SizedBox(height: 16),

                  // Notification Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Bildirim",
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        Switch(
                          value: _isNotificationOn,
                          onChanged: (value) {
                            setState(() {
                              _isNotificationOn = value;
                            });
                          },
                          activeColor: const Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                  ),

                  // Notification Time (only show if notification is on)
                  if (_isNotificationOn) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Color(0xFF3B82F6),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Bildirim Saati",
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _notificationTime.format(context),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "İptal",
                          style: GoogleFonts.inter(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          final subject = _isCustomSubject
                              ? _customSubjectController.text.isNotEmpty
                                    ? _customSubjectController.text
                                    : "Konu Belirlenmedi"
                              : _selectedSubject;
                          Navigator.pop(context, {
                            'subject': subject,
                            'duration': _durationController.text,
                            'isNotificationOn': _isNotificationOn,
                            'notificationTime': _notificationTime,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          "Kaydet",
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectChip(String subject) {
    final isSelected = _selectedSubject == subject && !_isCustomSubject;
    return GestureDetector(
      onTap: () => _selectSubject(subject),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          subject,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomChip() {
    final isSelected = _isCustomSubject;
    return GestureDetector(
      onTap: _openCustomSubject,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              "Diğer",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
      ),
    );
  }
}
