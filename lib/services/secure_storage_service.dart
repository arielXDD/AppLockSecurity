import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _pinKey = 'vault_pin';
  static const _panicPinKey = 'panic_pin';
  static const _dialCodeKey = 'dial_code';
  static const _biometricKey = 'biometric_enabled';
  static const _patternKey = 'unlock_pattern';
  static const _hiddenAppsKey = 'hidden_apps';
  static const _failedAttemptsKey = 'failed_attempts';
  static const _setupDoneKey = 'setup_done';

  // PIN principal
  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  // PIN de pánico
  Future<void> setPanicPin(String pin) async {
    await _storage.write(key: _panicPinKey, value: pin);
  }

  Future<String?> getPanicPin() async {
    return await _storage.read(key: _panicPinKey);
  }

  // Código de llamada
  Future<void> setDialCode(String code) async {
    await _storage.write(key: _dialCodeKey, value: code);
  }

  Future<String?> getDialCode() async {
    return await _storage.read(key: _dialCodeKey) ?? '*#*#0000#*#*';
  }

  // Biometría
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricKey, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricKey);
    return val == 'true';
  }

  Future<void> setPattern(List<int> pattern) async {
    await _storage.write(key: _patternKey, value: pattern.join(','));
  }

  Future<List<int>> getPattern() async {
    final val = await _storage.read(key: _patternKey);
    if (val == null || val.isEmpty) return const [0, 1, 2, 4, 6];
    return val.split(',').map(int.tryParse).whereType<int>().toList();
  }

  // Apps ocultas (lista de packageNames separados por coma)
  Future<void> saveHiddenApps(List<String> packages) async {
    await _storage.write(key: _hiddenAppsKey, value: packages.join(','));
  }

  Future<List<String>> getHiddenApps() async {
    final val = await _storage.read(key: _hiddenAppsKey);
    if (val == null || val.isEmpty) return [];
    return val.split(',').where((s) => s.isNotEmpty).toList();
  }

  // Intentos fallidos
  Future<int> getFailedAttempts() async {
    final val = await _storage.read(key: _failedAttemptsKey);
    return int.tryParse(val ?? '0') ?? 0;
  }

  Future<void> incrementFailedAttempts() async {
    final current = await getFailedAttempts();
    await _storage.write(
      key: _failedAttemptsKey,
      value: (current + 1).toString(),
    );
  }

  Future<void> resetFailedAttempts() async {
    await _storage.write(key: _failedAttemptsKey, value: '0');
  }

  // Setup completado
  Future<bool> isSetupDone() async {
    final val = await _storage.read(key: _setupDoneKey);
    return val == 'true';
  }

  Future<void> markSetupDone() async {
    await _storage.write(key: _setupDoneKey, value: 'true');
  }

  // Borrar todo (autodestrucción)
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
