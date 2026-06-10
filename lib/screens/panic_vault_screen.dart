import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_style.dart';

class PanicVaultScreen extends StatelessWidget {
  const PanicVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header falso idéntico al vault real
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppStyle.primary, Color(0xFF9B8FFF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bóveda',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppStyle.text,
                        ),
                      ),
                      Text(
                        'Panel seguro',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppStyle.muted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.lock_outlined,
                      color: AppStyle.muted,
                    ),
                  ),
                ],
              ),
            ),
            // Tabs falsos
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppStyle.shadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppStyle.primary, Color(0xFF9B8FFF)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Apps Ocultas',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Mis Archivos',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppStyle.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Contenido vacío — bóveda de pánico
            const Expanded(child: _EmptyPanicContent()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: AppStyle.primary,
        unselectedItemColor: AppStyle.muted,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Ajustes',
          ),
        ],
        onTap: (_) {}, // No hace nada en modo pánico
      ),
    );
  }
}

class _EmptyPanicContent extends StatelessWidget {
  const _EmptyPanicContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppStyle.shadow,
            ),
            child: const Icon(
              Icons.apps_outlined,
              color: AppStyle.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No hay apps ocultas',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppStyle.text,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca "Agregar apps" para ocultar\nlas apps que quieras',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppStyle.muted),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppStyle.primary, Color(0xFF9B8FFF)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Agregar apps',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
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
