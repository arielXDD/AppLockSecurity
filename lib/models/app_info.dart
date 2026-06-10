class AppInfo {
  final String packageName;
  final String appName;
  final String? iconBase64;
  bool isHidden;

  AppInfo({
    required this.packageName,
    required this.appName,
    this.iconBase64,
    this.isHidden = false,
  });

  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      iconBase64: map['iconBase64'] as String?,
      isHidden: (map['isHidden'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'iconBase64': iconBase64,
      'isHidden': isHidden,
    };
  }
}
