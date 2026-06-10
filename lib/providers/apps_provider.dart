import 'package:flutter/material.dart';
import '../models/app_info.dart';
import '../native_bridges/app_hider_bridge.dart';
import '../services/secure_storage_service.dart';

class AppsProvider extends ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();

  List<AppInfo> _allApps = [];
  List<AppInfo> _hiddenApps = [];
  bool _loading = false;
  String _searchQuery = '';

  List<AppInfo> get allApps => _allApps
      .where(
        (a) => a.appName.toLowerCase().contains(_searchQuery.toLowerCase()),
      )
      .toList();

  List<AppInfo> get hiddenApps => _hiddenApps;
  bool get loading => _loading;

  Future<void> loadApps() async {
    _loading = true;
    notifyListeners();

    _allApps = await AppHiderBridge.getInstalledApps();
    final hiddenPkgs = await _storage.getHiddenApps();

    for (final app in _allApps) {
      app.isHidden = hiddenPkgs.contains(app.packageName);
    }
    _hiddenApps = _allApps.where((a) => a.isHidden).toList();

    _loading = false;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<bool> hideApp(AppInfo app) async {
    final success = await AppHiderBridge.hideApp(app.packageName);
    if (success) {
      app.isHidden = true;
      if (!_hiddenApps.any((a) => a.packageName == app.packageName)) {
        _hiddenApps.add(app);
      }
      await _saveHiddenApps();
      notifyListeners();
    }
    return success;
  }

  Future<bool> showApp(AppInfo app) async {
    final success = await AppHiderBridge.showApp(app.packageName);
    if (success) {
      app.isHidden = false;
      _hiddenApps.removeWhere((a) => a.packageName == app.packageName);
      await _saveHiddenApps();
      notifyListeners();
    }
    return success;
  }

  Future<void> hideMultiple(List<AppInfo> apps) async {
    for (final app in apps) {
      await hideApp(app);
    }
  }

  Future<void> showAll() async {
    await AppHiderBridge.showAllApps();
    for (final app in _allApps) {
      app.isHidden = false;
    }
    _hiddenApps.clear();
    await _storage.saveHiddenApps([]);
    notifyListeners();
  }

  Future<void> _saveHiddenApps() async {
    final packages = _hiddenApps.map((a) => a.packageName).toList();
    await _storage.saveHiddenApps(packages);
  }
}
