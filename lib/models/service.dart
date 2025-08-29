class Service {
  final int port;
  final String name;
  final String description;
  final bool isOpen;

  Service({
    required this.port,
    required this.name,
    required this.description,
    required this.isOpen,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Service &&
        other.port == port &&
        other.name == name &&
        other.description == description &&
        other.isOpen == isOpen;
  }

  @override
  int get hashCode {
    return port.hashCode ^
        name.hashCode ^
        description.hashCode ^
        isOpen.hashCode;
  }

  @override
  String toString() {
    return 'Service(port: $port, name: $name, description: $description, isOpen: $isOpen)';
  }

  Map<String, dynamic> toJson() {
    return {
      'port': port,
      'name': name,
      'description': description,
      'isOpen': isOpen,
    };
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      port: json['port'],
      name: json['name'],
      description: json['description'],
      isOpen: json['isOpen'],
    );
  }
}
