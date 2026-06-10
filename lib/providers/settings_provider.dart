import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../native_bridges/app_hider_bridge.dart';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _deviceAdmin = false;
  bool _cameraIntruder = true;
  String _launcherAlias = 'calculator'; // 'calculator' | 'vault'
  bool _accessPin = true;
  bool _accessPattern = true;
  bool _accessBiometric = true;
  bool _accessPhone = true;
  bool _accessDeepLink = true;
  bool _accessWidget = true;
  bool _accessQuickTile = true;
  bool _accessNotification = true;

  bool get deviceAdmin => _deviceAdmin;
  bool get cameraIntruder => _cameraIntruder;
  String get launcherAlias => _launcherAlias;
  bool get accessPin => _accessPin;
  bool get accessPattern => _accessPattern;
  bool get accessBiometric => _accessBiometric;
  bool get accessPhone => _accessPhone;
  bool get accessDeepLink => _accessDeepLink;
  bool get accessWidget => _accessWidget;
  bool get accessQuickTile => _accessQuickTile;
  bool get accessNotification => _accessNotification;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _deviceAdmin = await AppHiderBridge.isDeviceAdmin();
    _cameraIntruder = _prefs.getBool('camera_intruder') ?? true;
    _launcherAlias = _prefs.getString('launcher_alias') ?? 'calculator';
    _accessPin = _prefs.getBool('access_pin') ?? true;
    _accessPattern = _prefs.getBool('access_pattern') ?? true;
    _accessBiometric = _prefs.getBool('access_biometric') ?? true;
    _accessPhone = _prefs.getBool('access_phone') ?? true;
    _accessDeepLink = _prefs.getBool('access_deep_link') ?? true;
    _accessWidget = _prefs.getBool('access_widget') ?? true;
    _accessQuickTile = _prefs.getBool('access_quick_tile') ?? true;
    _accessNotification = _prefs.getBool('access_notification') ?? true;
    await _syncNativeAccessMethods();
    notifyListeners();
  }

  Future<void> refreshDeviceAdmin() async {
    _deviceAdmin = await AppHiderBridge.isDeviceAdmin();
    notifyListeners();
  }

  Future<void> requestDeviceAdmin() async {
    await AppHiderBridge.requestDeviceAdmin();
    await Future.delayed(const Duration(seconds: 1));
    await refreshDeviceAdmin();
  }

  Future<void> setCameraIntruder(bool value) async {
    _cameraIntruder = value;
    await _prefs.setBool('camera_intruder', value);
    notifyListeners();
  }

  Future<void> setLauncherAlias(String alias) async {
    _launcherAlias = alias;
    await _prefs.setString('launcher_alias', alias);
    await AppHiderBridge.setLauncherAlias(alias);
    notifyListeners();
  }

  Future<void> setAccessMethod(String method, bool enabled) async {
    switch (method) {
      case 'pin':
        _accessPin = enabled;
        break;
      case 'pattern':
        _accessPattern = enabled;
        break;
      case 'biometric':
        _accessBiometric = enabled;
        break;
      case 'phone':
        _accessPhone = enabled;
        break;
      case 'deep_link':
        _accessDeepLink = enabled;
        break;
      case 'widget':
        _accessWidget = enabled;
        break;
      case 'quick_tile':
        _accessQuickTile = enabled;
        break;
      case 'notification':
        _accessNotification = enabled;
        break;
    }
    await _prefs.setBool('access_$method', enabled);
    await AppHiderBridge.setAccessMethod(method, enabled);
    notifyListeners();
  }

  Future<void> _syncNativeAccessMethods() async {
    await AppHiderBridge.setAccessMethod('phone', _accessPhone);
    await AppHiderBridge.setAccessMethod('widget', _accessWidget);
    await AppHiderBridge.setAccessMethod('quick_tile', _accessQuickTile);
    await AppHiderBridge.setAccessMethod('notification', _accessNotification);
  }
}
