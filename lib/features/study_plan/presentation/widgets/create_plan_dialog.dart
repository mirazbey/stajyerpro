import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CreatePlanDialog extends StatefulWidget {
  const CreatePlanDialog({super.key});

  @override
  State<CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends State<CreatePlanDialog> {
  static const List<String> _predefinedPlanNames = [
    "Hızlandırılmış Kamp",
    "Genel Tekrar",
    "90 Gün Yoğun",
    "Son 30 Gün",
  ];

  final _formKey = GlobalKey<FormState>();
  final _customNameController = TextEditingController();
  final _customDurationController = TextEditingController();
  DateTime _startDate = DateTime.now();

  String? _selectedPlanName;
  int? _selectedDuration = 30;
  bool _isCustomPlanName = false;
  bool _isCustomDuration = false;

  @override
  void dispose() {
    _customNameController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  void _selectPlanName(String name) {
    setState(() {
      _selectedPlanName = name;
      _isCustomPlanName = false;
      _customNameController.clear();
    });
  }

  void _openCustomPlanName() {
    setState(() {
      _isCustomPlanName = true;
      _selectedPlanName = null;
    });
  }

  void _selectDuration(int days) {
    setState(() {
      _selectedDuration = days;
      _isCustomDuration = false;
      _customDurationController.clear();
    });
  }

  void _openCustomDuration() {
    setState(() {
      _isCustomDuration = true;
      _selectedDuration = null;
    });
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Yeni Çalışma Planı",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Plan Name Label
                    Text(
                      "Plan Adı",
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Plan Name Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._predefinedPlanNames.map(
                          (name) => _buildPlanNameChip(name),
                        ),
                        _buildCustomPlanNameChip(),
                      ],
                    ),

                    // Custom Plan Name Input
                    if (_isCustomPlanName) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customNameController,
                        autofocus: true,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: _buildInputDecoration("Özel Plan Adı"),
                        validator: (value) {
                          if (_isCustomPlanName &&
                              (value == null || value.isEmpty)) {
                            return 'Lütfen bir isim girin';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Start Date
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                          });
                        }
                      },
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
                            Text(
                              "Başlangıç Tarihi",
                              style: GoogleFonts.inter(color: Colors.white70),
                            ),
                            Text(
                              DateFormat(
                                'd MMM yyyy',
                                'tr_TR',
                              ).format(_startDate),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Duration Label
                    Text(
                      "Süre",
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Duration Chips
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildDurationChip(30),
                        _buildDurationChip(60),
                        _buildDurationChip(90),
                        _buildCustomDurationChip(),
                      ],
                    ),

                    // Custom Duration Input
                    if (_isCustomDuration) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customDurationController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: _buildInputDecoration("Özel Süre (Gün)"),
                        validator: (value) {
                          if (_isCustomDuration) {
                            if (value == null || value.isEmpty) {
                              return 'Süre girin';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Geçerli bir sayı girin';
                            }
                          }
                          return null;
                        },
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
                            if (_formKey.currentState!.validate()) {
                              // Validate plan name selection
                              if (!_isCustomPlanName &&
                                  _selectedPlanName == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Lütfen bir plan adı seçin',
                                      style: GoogleFonts.inter(),
                                    ),
                                  ),
                                );
                                return;
                              }

                              final planName = _isCustomPlanName
                                  ? _customNameController.text
                                  : _selectedPlanName!;

                              final duration = _isCustomDuration
                                  ? int.parse(_customDurationController.text)
                                  : _selectedDuration!;

                              Navigator.pop(context, {
                                'name': planName,
                                'startDate': _startDate,
                                'duration': duration,
                              });
                            }
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
                            "Oluştur",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }

  Widget _buildPlanNameChip(String name) {
    final isSelected = _selectedPlanName == name && !_isCustomPlanName;
    return GestureDetector(
      onTap: () => _selectPlanName(name),
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
          name,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPlanNameChip() {
    final isSelected = _isCustomPlanName;
    return GestureDetector(
      onTap: _openCustomPlanName,
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
              "Ekle",
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

  Widget _buildDurationChip(int days) {
    final isSelected = _selectedDuration == days && !_isCustomDuration;
    return GestureDetector(
      onTap: () => _selectDuration(days),
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
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          "$days Gün",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDurationChip() {
    final isSelected = _isCustomDuration;
    return GestureDetector(
      onTap: _openCustomDuration,
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
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              "Özel",
              style: GoogleFonts.inter(
                color: Colors.white,
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
