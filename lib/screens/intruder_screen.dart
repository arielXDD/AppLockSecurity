import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_style.dart';
import '../models/intruder_log.dart';
import '../providers/auth_provider.dart';

class IntruderScreen extends StatelessWidget {
  const IntruderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bg,
      appBar: AppBar(
        backgroundColor: AppStyle.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppStyle.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Alerta de Intrusos',
          style: GoogleFonts.inter(
            color: AppStyle.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          final logs = auth.intruderLogs;
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAFBF1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sin intentos fallidos',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: AppStyle.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu bóveda está segura',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppStyle.muted,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (_, i) => _IntruderCard(log: logs[i]),
          );
        },
      ),
    );
  }
}

class _IntruderCard extends StatelessWidget {
  final IntruderLog log;
  const _IntruderCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD6D6)),
        boxShadow: AppStyle.shadow,
      ),
      child: Column(
        children: [
          // Foto del intruso
          if (log.photoPath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.file(
                File(log.photoPath!),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 120,
                  color: const Color(0xFFFFEEEE),
                  child: const Icon(Icons.person, color: Colors.red, size: 48),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.redAccent,
                size: 48,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Acceso fallido',
                    style: GoogleFonts.inter(
                      color: AppStyle.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      log.formattedDate,
                      style: GoogleFonts.inter(
                        color: AppStyle.muted,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Intento #${log.attemptNumber}',
                      style: GoogleFonts.inter(
                        color: AppStyle.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
