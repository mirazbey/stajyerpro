import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/premium_glass_container.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = false;
  String _status = "Hazır";
  double _progress = 0.0;

  Future<void> _uploadRagData() async {
    setState(() {
      _isLoading = true;
      _status = "JSON dosyası okunuyor...";
      _progress = 0.0;
    });

    try {
      // 1. Read JSON
      final jsonString = await rootBundle.loadString('assets/rag_data.json');
      final List<dynamic> data = json.decode(jsonString);

      setState(() {
        _status = "${data.length} chunk bulundu. Yükleme başlıyor...";
      });

      // 2. Batch Upload
      final firestore = FirebaseFirestore.instance;
      final collection = firestore.collection('knowledge_base');

      // Delete existing data first? Maybe too dangerous/slow.
      // Let's just add/overwrite.

      int total = data.length;
      int batchSize = 400; // Firestore limit is 500

      for (int i = 0; i < total; i += batchSize) {
        final batch = firestore.batch();
        final end = (i + batchSize < total) ? i + batchSize : total;
        final chunkList = data.sublist(i, end);

        for (var item in chunkList) {
          final docRef = collection.doc(); // Auto-ID
          batch.set(docRef, item);
        }

        await batch.commit();

        setState(() {
          _progress = end / total;
          _status = "$end / $total yüklendi...";
        });

        // Small delay to be nice to Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        _status = "✅ Başarıyla tamamlandı! ($total chunk)";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = "❌ Hata: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        title: Text("Admin Paneli", style: GoogleFonts.spaceGrotesk()),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PremiumGlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      "RAG Veri Yükleme",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "assets/rag_data.json dosyasını Firestore 'knowledge_base' koleksiyonuna yükler.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    if (_isLoading) ...[
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white10,
                        color: DesignTokens.accent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _status,
                        style: GoogleFonts.inter(color: DesignTokens.accent),
                      ),
                    ] else ...[
                      Text(
                        _status,
                        style: GoogleFonts.inter(
                          color: _status.startsWith("✅")
                              ? Colors.green
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _uploadRagData,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text("Verileri Yükle"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
