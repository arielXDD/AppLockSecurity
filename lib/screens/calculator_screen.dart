import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../app_style.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'vault_screen.dart';
import 'panic_vault_screen.dart';
import 'setup_pin_screen.dart';
import 'pattern_auth_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  String _display = '0';
  String _expression = '';
  String _input = '';
  bool _newNumber = true;
  double? _firstOperand;
  String? _operator;
  bool _justCalculated = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _checkDeepLink();
  }

  void _checkDeepLink() async {
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final nav = Navigator.of(context);
    await auth.initialize();
    await settings.initialize();
    await Permission.notification.request();
    if (!auth.isSetupDone && mounted) {
      nav.pushReplacement(
        MaterialPageRoute(builder: (_) => const SetupPinScreen()),
      );
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onButton(String label) {
    HapticFeedback.lightImpact();
    setState(() {
      if (label == 'AC') {
        _display = '0';
        _expression = '';
        _input = '';
        _firstOperand = null;
        _operator = null;
        _newNumber = true;
        _justCalculated = false;
      } else if (label == '+/-') {
        final val = double.tryParse(_display);
        if (val != null) {
          _display = _formatNumber(-val);
          _input = _display;
        }
      } else if (label == '%') {
        final val = double.tryParse(_display);
        if (val != null) {
          _display = _formatNumber(val / 100);
          _input = _display;
        }
      } else if (['+', '−', '×', '÷'].contains(label)) {
        _firstOperand = double.tryParse(_display);
        _operator = label;
        _expression = '$_display $label';
        _newNumber = true;
        _justCalculated = false;
      } else if (label == '=') {
        final rawInput = _input;
        if (_looksLikeSecretInput(rawInput)) {
          _trySecretPin(rawInput);
        } else {
          _calculate();
        }
      } else if (label == '.' || label == ',') {
        if (!_display.contains('.')) {
          if (_newNumber) {
            _display = '0.';
            _input = '0.';
            _newNumber = false;
          } else {
            _display = '$_display.';
            _input = '$_input.';
          }
        }
      } else {
        // Dígito
        if (_newNumber || _justCalculated) {
          _display = label;
          _input = _justCalculated ? '$_input$label' : label;
          _newNumber = false;
          _justCalculated = false;
        } else {
          if (_display == '0') {
            _display = label;
          } else {
            _display = '$_display$label';
          }
          _input = '$_input$label';
        }
      }
    });
  }

  bool _looksLikeSecretInput(String value) {
    return RegExp(r'^\d{4,}$').hasMatch(value);
  }

  Future<void> _tryBiometric() async {
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    if (!settings.accessBiometric) {
      _shakeController
        ..reset()
        ..forward();
      return;
    }
    final ok = await auth.tryBiometric();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).push(_slideRoute(const VaultScreen()));
    } else {
      _shakeController
        ..reset()
        ..forward();
    }
  }

  void _onEqualLongPress() {
    HapticFeedback.mediumImpact();
    if (_input == '1984') {
      _trySecretPin(_input);
    } else {
      _tryBiometric();
    }
  }

  void _trySecretPin(String rawInput) async {
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    if (!settings.accessPin && rawInput != '1984') {
      _shakeController
        ..reset()
        ..forward();
      _calculate();
      return;
    }
    final nav = Navigator.of(context);
    final result = await auth.tryPin(rawInput);

    if (result == 'vault') {
      if (!mounted) return;
      nav.push(_slideRoute(const VaultScreen()));
      setState(() {
        _display = '0';
        _expression = '';
        _input = '';
        _newNumber = true;
        _justCalculated = false;
      });
    } else if (result == 'panic') {
      if (!mounted) return;
      nav.push(_slideRoute(const PanicVaultScreen()));
      setState(() {
        _display = '0';
        _expression = '';
        _input = '';
        _newNumber = true;
      });
    } else {
      _shakeController
        ..reset()
        ..forward();
      _calculate();
    }
  }

  void _calculate() {
    if (_operator == null || _firstOperand == null) {
      _justCalculated = true;
      return;
    }
    final second = double.tryParse(_display);
    if (second == null) return;
    double result;
    switch (_operator) {
      case '+':
        result = _firstOperand! + second;
        break;
      case '−':
        result = _firstOperand! - second;
        break;
      case '×':
        result = _firstOperand! * second;
        break;
      case '÷':
        result = second != 0 ? _firstOperand! / second : double.nan;
        break;
      default:
        return;
    }
    setState(() {
      _display = result.isNaN ? 'Error' : _formatNumber(result);
      _expression = '';
      _input = _display;
      _operator = null;
      _firstOperand = null;
      _justCalculated = true;
      _newNumber = true;
    });
  }

  String _formatNumber(double n) {
    if (n == n.truncateToDouble()) {
      return n.toInt().toString();
    }
    // Máximo 8 decimales
    final str = n.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '');
    return str.endsWith('.') ? str.substring(0, str.length - 1) : str;
  }

  PageRoute _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, a, __) => page,
      transitionsBuilder: (_, a, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Display
            Expanded(flex: 3, child: _buildDisplay()),
            // Botones
            Expanded(flex: 5, child: _buildButtons()),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay() {
    final fontSize = _display.length > 9
        ? 44.0
        : _display.length > 6
        ? 56.0
        : 72.0;

    return Container(
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_expression.isNotEmpty)
            Text(
              _expression,
              style: GoogleFonts.inter(
                fontSize: 22,
                color: AppStyle.muted,
                fontWeight: FontWeight.w300,
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Consumer<SettingsProvider>(
                builder: (_, settings, __) => Row(
                  children: [
                    if (settings.accessPattern)
                      IconButton(
                        tooltip: 'Patrón',
                        onPressed: () => Navigator.of(
                          context,
                        ).push(_slideRoute(const PatternAuthScreen())),
                        icon: const Icon(Icons.gesture, color: AppStyle.muted),
                      ),
                    if (settings.accessBiometric)
                      IconButton(
                        tooltip: 'Huella',
                        onPressed: _tryBiometric,
                        icon: const Icon(
                          Icons.fingerprint,
                          color: AppStyle.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (_, child) {
              final offset = sin(_shakeAnimation.value * pi * 8) * 8;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Text(
              _display,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                color: AppStyle.text,
                fontWeight: FontWeight.w300,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    final rows = [
      ['AC', '+/-', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: rows.map((row) {
          return Expanded(
            child: Row(
              children: row.map((label) {
                final isZero = label == '0' && row.length == 3;
                return Expanded(
                  flex: isZero ? 2 : 1,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: _CalcButton(
                      label: label,
                      onTap: () => _onButton(label),
                      onLongPress: label == '=' ? _onEqualLongPress : null,
                      style: _buttonStyle(label),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  _ButtonStyle _buttonStyle(String label) {
    if (['+', '−', '×', '÷', '='].contains(label)) {
      return _ButtonStyle.orange;
    }
    if (['AC', '+/-', '%'].contains(label)) {
      return _ButtonStyle.gray;
    }
    return _ButtonStyle.dark;
  }
}

enum _ButtonStyle { dark, gray, orange }

class _CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final _ButtonStyle style;

  const _CalcButton({
    required this.label,
    required this.onTap,
    this.onLongPress,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (style) {
      case _ButtonStyle.orange:
        bg = const Color(0xFFEDEBFF);
        fg = AppStyle.primary;
        break;
      case _ButtonStyle.gray:
        bg = const Color(0xFFF1F2F7);
        fg = AppStyle.text;
        break;
      case _ButtonStyle.dark:
        bg = Colors.white;
        fg = AppStyle.text;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: const Color(0x12000000),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
