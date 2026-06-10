class IntruderLog {
  final DateTime timestamp;
  final String? photoPath;
  final int attemptNumber;

  IntruderLog({
    required this.timestamp,
    this.photoPath,
    required this.attemptNumber,
  });

  factory IntruderLog.fromMap(Map<String, dynamic> map) {
    return IntruderLog(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      photoPath: map['photoPath'] as String?,
      attemptNumber: map['attemptNumber'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'photoPath': photoPath,
      'attemptNumber': attemptNumber,
    };
  }

  String get formattedDate {
    final d = timestamp;
    return '${d.day} ${_monthName(d.month)} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String _monthName(int month) {
    const names = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return names[month];
  }
}
