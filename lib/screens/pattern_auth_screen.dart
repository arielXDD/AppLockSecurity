import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_style.dart';
import '../providers/auth_provider.dart';
import 'vault_screen.dart';

class PatternAuthScreen extends StatefulWidget {
  const PatternAuthScreen({super.key});

  @override
  State<PatternAuthScreen> createState() => _PatternAuthScreenState();
}

class _PatternAuthScreenState extends State<PatternAuthScreen> {
  final List<int> _selected = [];
  bool _failed = false;

  Future<void> _submit() async {
    if (_selected.length < 4) return;
    final ok = await context.read<AuthProvider>().tryPattern(_selected);
    if (!mounted) return;
    if (ok) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const VaultScreen()));
    } else {
      setState(() {
        _failed = true;
        _selected.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: AppStyle.text),
              ),
            ),
            const SizedBox(height: 28),
            const Icon(Icons.lock_outline, color: AppStyle.primary, size: 48),
            const SizedBox(height: 16),
            Text(
              'Dibuja tu patrón',
              style: GoogleFonts.inter(
                color: AppStyle.text,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _failed ? 'Patrón incorrecto' : 'Une al menos 4 puntos',
              style: GoogleFonts.inter(
                color: _failed ? AppStyle.danger : AppStyle.muted,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 280,
              height: 280,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 34,
                  crossAxisSpacing: 34,
                ),
                itemCount: 9,
                itemBuilder: (_, index) {
                  final selected = _selected.contains(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _failed = false;
                        if (selected) {
                          _selected.remove(index);
                        } else {
                          _selected.add(index);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? AppStyle.primary : Colors.white,
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF9B8FFF)
                              : AppStyle.line,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: ElevatedButton(
                onPressed: _selected.length >= 4 ? _submit : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppStyle.primary,
                  disabledBackgroundColor: AppStyle.line,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Entrar',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
