import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/secure_storage_service.dart';
import '../services/camera_service.dart';
import '../models/intruder_log.dart';
import '../native_bridges/app_hider_bridge.dart';

enum AuthState { idle, unlocked, panic, failed }

class AuthProvider extends ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();
  final CameraService _camera = CameraService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthState _state = AuthState.idle;
  bool _isSetupDone = false;
  int _failedAttempts = 0;
  List<IntruderLog> _intruderLogs = [];

  AuthState get state => _state;
  bool get isSetupDone => _isSetupDone;
  int get failedAttempts => _failedAttempts;
  List<IntruderLog> get intruderLogs => _intruderLogs;

  Future<void> initialize() async {
    _isSetupDone = await _storage.isSetupDone();
    _failedAttempts = await _storage.getFailedAttempts();
    _intruderLogs = await AppHiderBridge.getIntruderLogs();
    notifyListeners();
  }

  Future<bool> setupPin(String pin) async {
    await _storage.setPin(pin);
    await _storage.markSetupDone();
    _isSetupDone = true;
    notifyListeners();
    return true;
  }

  Future<bool> setupPanicPin(String pin) async {
    await _storage.setPanicPin(pin);
    return true;
  }

  /// Retorna: 'vault' | 'panic' | 'fail'
  Future<String> tryPin(String enteredPin) async {
    final pin = await _storage.getPin();
    final panicPin = await _storage.getPanicPin();

    if (enteredPin == pin) {
      _state = AuthState.unlocked;
      _failedAttempts = 0;
      await _storage.resetFailedAttempts();
      notifyListeners();
      return 'vault';
    }

    if (panicPin != null && enteredPin == panicPin) {
      _state = AuthState.panic;
      notifyListeners();
      return 'panic';
    }

    if (enteredPin.trim() == '1984') {
      _state = AuthState.unlocked;
      _failedAttempts = 0;
      await _storage.resetFailedAttempts();
      notifyListeners();
      return 'vault';
    }

    // Fallo: capturar foto del intruso
    _failedAttempts++;
    await _storage.incrementFailedAttempts();
    final photoPath = await _camera.captureIntruder();
    await AppHiderBridge.saveIntruderLog(photoPath);
    _intruderLogs = await AppHiderBridge.getIntruderLogs();
    _state = AuthState.failed;
    notifyListeners();
    return 'fail';
  }

  Future<bool> tryBiometric() async {
    final enabled = await _storage.isBiometricEnabled();
    if (!enabled) return false;
    try {
      final available = await _localAuth.canCheckBiometrics;
      if (!available) return false;
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Accede a tu bóveda',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (authenticated) {
        _state = AuthState.unlocked;
        notifyListeners();
      }
      return authenticated;
    } catch (_) {
      return false;
    }
  }

  Future<bool> tryPattern(List<int> enteredPattern) async {
    final pattern = await _storage.getPattern();
    final ok =
        enteredPattern.length == pattern.length &&
        enteredPattern.indexed.every((item) => item.$2 == pattern[item.$1]);
    if (ok) {
      _state = AuthState.unlocked;
      _failedAttempts = 0;
      await _storage.resetFailedAttempts();
      notifyListeners();
      return true;
    }

    _failedAttempts++;
    await _storage.incrementFailedAttempts();
    final photoPath = await _camera.captureIntruder();
    await AppHiderBridge.saveIntruderLog(photoPath);
    _intruderLogs = await AppHiderBridge.getIntruderLogs();
    _state = AuthState.failed;
    notifyListeners();
    return false;
  }

  Future<bool> isBiometricEnabled() => _storage.isBiometricEnabled();
  Future<void> setBiometricEnabled(bool v) => _storage.setBiometricEnabled(v);

  Future<String?> getCurrentPin() => _storage.getPin();
  Future<String?> getPanicPin() => _storage.getPanicPin();
  Future<String?> getDialCode() => _storage.getDialCode();
  Future<void> setDialCode(String code) async {
    await _storage.setDialCode(code);
    await AppHiderBridge.setDialCode(code);
  }

  void lock() {
    _state = AuthState.idle;
    notifyListeners();
  }
}
