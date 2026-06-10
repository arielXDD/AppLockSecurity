import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_style.dart';
import '../providers/auth_provider.dart';
import 'calculator_screen.dart';

class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  int _step = 0; // 0: set PIN, 1: confirm PIN, 2: set panic PIN
  String _pin = '';
  String _current = '';
  String _error = '';

  final List<int> _keys = [1, 2, 3, 4, 5, 6, 7, 8, 9, -1, 0, -2];

  void _onKey(int key) {
    setState(() {
      _error = '';
      if (key == -2) {
        // Borrar
        if (_current.isNotEmpty) {
          _current = _current.substring(0, _current.length - 1);
        }
      } else if (key == -1) {
        // OK
        _submit();
      } else {
        if (_current.length < 6) {
          _current += key.toString();
          if (_current.length == 6) _submit();
        }
      }
    });
  }

  void _submit() {
    if (_current.length < 4) {
      setState(() => _error = 'Mínimo 4 dígitos');
      return;
    }

    if (_step == 0) {
      _pin = _current;
      _current = '';
      _step = 1;
    } else if (_step == 1) {
      if (_current != _pin) {
        setState(() {
          _error = 'Los PINs no coinciden';
          _current = '';
        });
        return;
      }
      _current = '';
      _step = 2;
    } else if (_step == 2) {
      // PIN de pánico
      _setupComplete();
    }
  }

  Future<void> _setupComplete() async {
    final auth = context.read<AuthProvider>();
    await auth.setupPin(_pin);
    if (_current.isNotEmpty) {
      await auth.setupPanicPin(_current);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CalculatorScreen()),
    );
  }

  String get _title {
    switch (_step) {
      case 0:
        return 'Crea tu PIN secreto';
      case 1:
        return 'Confirma tu PIN';
      case 2:
        return 'PIN de Pánico (opcional)';
      default:
        return '';
    }
  }

  String get _subtitle {
    switch (_step) {
      case 0:
        return 'Este PIN abre tu bóveda real';
      case 1:
        return 'Escribe el mismo PIN de nuevo';
      case 2:
        return 'Este PIN muestra una bóveda vacía\n(Presiona ✓ para omitir)';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Hero(
              tag: 'app-logo',
              child: Image.asset(
                'logo_app.png',
                width: 84,
                height: 84,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppStyle.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppStyle.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppStyle.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            // Puntos PIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < _current.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: filled ? 18 : 14,
                  height: filled ? 18 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppStyle.primary : AppStyle.line,
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color: const Color(0x335D55F6),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _error,
                style: GoogleFonts.inter(fontSize: 13, color: AppStyle.danger),
              ),
            ],
            const Spacer(),
            // Teclado numérico
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _keys.length,
                itemBuilder: (_, i) {
                  final key = _keys[i];
                  if (key == -1) {
                    return _PinKey(
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 28,
                      ),
                      color: AppStyle.primary,
                      onTap: () => _onKey(-1),
                    );
                  }
                  if (key == -2) {
                    return _PinKey(
                      child: const Icon(
                        Icons.backspace_outlined,
                        color: AppStyle.muted,
                        size: 24,
                      ),
                      color: Colors.white,
                      onTap: () => _onKey(-2),
                    );
                  }
                  return _PinKey(
                    child: Text(
                      key.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: AppStyle.text,
                      ),
                    ),
                    color: Colors.white,
                    onTap: () => _onKey(key),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback onTap;

  const _PinKey({
    required this.child,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(child: child),
      ),
    );
  }
}
