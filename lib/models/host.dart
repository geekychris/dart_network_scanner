import 'service.dart';

enum HostStatus { unknown, online, offline }

class Host {
  final String ipAddress;
  final String? hostname;
  final String? macAddress;
  final String? vendor;
  final HostStatus status;
  final List<Service> services;
  final DateTime lastSeen;
  final int? responseTime; // in milliseconds

  Host({
    required this.ipAddress,
    this.hostname,
    this.macAddress,
    this.vendor,
    required this.status,
    required this.services,
    required this.lastSeen,
    this.responseTime,
  });

  String get displayName {
    if (hostname != null && hostname!.isNotEmpty) {
      return hostname!;
    }
    return ipAddress;
  }

  bool get isOnline => status == HostStatus.online;

  int get openPortsCount => services.where((s) => s.isOpen).length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Host &&
        other.ipAddress == ipAddress &&
        other.hostname == hostname &&
        other.macAddress == macAddress &&
        other.vendor == vendor &&
        other.status == status &&
        other.responseTime == responseTime;
  }

  @override
  int get hashCode {
    return ipAddress.hashCode ^
        hostname.hashCode ^
        macAddress.hashCode ^
        vendor.hashCode ^
        status.hashCode ^
        responseTime.hashCode;
  }

  @override
  String toString() {
    return 'Host(ip: $ipAddress, hostname: $hostname, status: $status, services: ${services.length})';
  }

  Map<String, dynamic> toJson() {
    return {
      'ipAddress': ipAddress,
      'hostname': hostname,
      'macAddress': macAddress,
      'vendor': vendor,
      'status': status.toString(),
      'services': services.map((s) => s.toJson()).toList(),
      'lastSeen': lastSeen.toIso8601String(),
      'responseTime': responseTime,
    };
  }

  factory Host.fromJson(Map<String, dynamic> json) {
    return Host(
      ipAddress: json['ipAddress'],
      hostname: json['hostname'],
      macAddress: json['macAddress'],
      vendor: json['vendor'],
      status: HostStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => HostStatus.unknown,
      ),
      services: (json['services'] as List<dynamic>?)
              ?.map((s) => Service.fromJson(s))
              .toList() ??
          [],
      lastSeen: DateTime.parse(json['lastSeen']),
      responseTime: json['responseTime'],
    );
  }

  Host copyWith({
    String? ipAddress,
    String? hostname,
    String? macAddress,
    String? vendor,
    HostStatus? status,
    List<Service>? services,
    DateTime? lastSeen,
    int? responseTime,
  }) {
    return Host(
      ipAddress: ipAddress ?? this.ipAddress,
      hostname: hostname ?? this.hostname,
      macAddress: macAddress ?? this.macAddress,
      vendor: vendor ?? this.vendor,
      status: status ?? this.status,
      services: services ?? this.services,
      lastSeen: lastSeen ?? this.lastSeen,
      responseTime: responseTime ?? this.responseTime,
    );
  }
}
