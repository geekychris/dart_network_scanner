import 'host.dart';

enum ScanStatus { idle, scanning, completed, error }

class ScanResult {
  final String networkRange;
  final List<Host> hosts;
  final ScanStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? error;
  final double progress; // 0.0 to 1.0

  ScanResult({
    required this.networkRange,
    required this.hosts,
    required this.status,
    this.startTime,
    this.endTime,
    this.error,
    required this.progress,
  });

  Duration? get scanDuration {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return null;
  }

  int get totalHosts => hosts.length;
  int get onlineHosts => hosts.where((h) => h.isOnline).length;
  int get offlineHosts => hosts.where((h) => !h.isOnline).length;

  @override
  String toString() {
    return 'ScanResult(network: $networkRange, hosts: ${hosts.length}, status: $status, progress: $progress)';
  }

  ScanResult copyWith({
    String? networkRange,
    List<Host>? hosts,
    ScanStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    String? error,
    double? progress,
  }) {
    return ScanResult(
      networkRange: networkRange ?? this.networkRange,
      hosts: hosts ?? this.hosts,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      error: error ?? this.error,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'networkRange': networkRange,
      'hosts': hosts.map((h) => h.toJson()).toList(),
      'status': status.toString(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'error': error,
      'progress': progress,
    };
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      networkRange: json['networkRange'],
      hosts: (json['hosts'] as List<dynamic>)
          .map((h) => Host.fromJson(h))
          .toList(),
      status: ScanStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ScanStatus.idle,
      ),
      startTime: json['startTime'] != null 
          ? DateTime.parse(json['startTime']) 
          : null,
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime']) 
          : null,
      error: json['error'],
      progress: json['progress'],
    );
  }
}
