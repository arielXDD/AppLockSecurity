import 'package:flutter/services.dart';
import '../models/app_info.dart';
import '../models/intruder_log.dart';

class AppHiderBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.boveda.app_hider/native',
  );

  // Obtiene todas las apps instaladas
  static Future<List<AppInfo>> getInstalledApps() async {
    try {
      final List result = await _channel.invokeMethod('getInstalledApps');
      return result.map((m) => AppInfo.fromMap(m as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  // Oculta/suspende un paquete
  static Future<bool> hideApp(String packageName) async {
    try {
      final result = await _channel.invokeMethod('hideApp', {
        'package': packageName,
      });
      return result as bool;
    } catch (_) {
      return false;
    }
  }

  // Restaura un paquete oculto
  static Future<bool> showApp(String packageName) async {
    try {
      final result = await _channel.invokeMethod('showApp', {
        'package': packageName,
      });
      return result as bool;
    } catch (_) {
      return false;
    }
  }

  // Restaura TODAS las apps ocultas
  static Future<bool> showAllApps() async {
    try {
      final result = await _channel.invokeMethod('showAllApps');
      return result as bool;
    } catch (_) {
      return false;
    }
  }

  // Verifica si la app es Device Admin
  static Future<bool> isDeviceAdmin() async {
    try {
      final result = await _channel.invokeMethod('isDeviceAdmin');
      return result as bool;
    } catch (_) {
      return false;
    }
  }

  // Lanza el flujo para pedir permiso de Device Admin
  static Future<void> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod('requestDeviceAdmin');
    } catch (_) {}
  }

  // Verifica si la biometría está disponible
  static Future<bool> isBiometricAvailable() async {
    try {
      final result = await _channel.invokeMethod('isBiometricAvailable');
      return result as bool;
    } catch (_) {
      return false;
    }
  }

  // Cambia el ícono de la app en el launcher
  static Future<void> setLauncherAlias(String alias) async {
    try {
      await _channel.invokeMethod('setLauncherAlias', {'alias': alias});
    } catch (_) {}
  }

  // Guarda log de intruso desde nativo
  static Future<void> saveIntruderLog(String? photoPath) async {
    try {
      await _channel.invokeMethod('saveIntruderLog', {'photoPath': photoPath});
    } catch (_) {}
  }

  // Obtiene logs de intrusos
  static Future<List<IntruderLog>> getIntruderLogs() async {
    try {
      final List result = await _channel.invokeMethod('getIntruderLogs');
      return result
          .map((m) => IntruderLog.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Registra el código de marcación secreto en nativo
  static Future<void> setDialCode(String code) async {
    try {
      await _channel.invokeMethod('setDialCode', {'code': code});
    } catch (_) {}
  }

  static Future<void> setAccessMethod(String method, bool enabled) async {
    try {
      await _channel.invokeMethod('setAccessMethod', {
        'method': method,
        'enabled': enabled,
      });
    } catch (_) {}
  }

  static Future<void> requestQuickTile() async {
    try {
      await _channel.invokeMethod('requestQuickTile');
    } catch (_) {}
  }
}
