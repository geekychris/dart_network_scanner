# Network Scanner Flutter App - Detailed Documentation

A comprehensive Flutter application that scans your local network to discover devices and their running services, similar to "IP Scanner Pro".

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Installation & Setup](#installation--setup)
3. [Building & Running](#building--running)
4. [Extension Guide](#extension-guide)
5. [API Reference](#api-reference)
6. [Testing](#testing)
7. [Performance](#performance)
8. [Security](#security)

## Architecture Overview

The app follows a clean architecture pattern with clear separation of concerns:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │    Business     │    │      Data       │
│     Layer       │    │     Logic       │    │     Layer       │
│                 │    │                 │    │                 │
│ • Screens       │◄──►│ • Providers     │◄──►│ • Services      │
│ • Widgets       │    │ • State Mgmt    │    │ • Models        │
│ • UI Components │    │                 │    │ • Network API   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Directory Structure

```
lib/
├── main.dart                 # App entry point and configuration
├── models/                   # Data structures and entities
│   ├── host.dart            # Host/device model with status and services
│   ├── service.dart         # Network service model (port, name, description)
│   └── scan_result.dart     # Scan session results and metadata
├── services/                # Business logic and external integrations
│   ├── network_info_service.dart    # Network information retrieval
│   └── network_scanner_service.dart # Core scanning and discovery logic
├── providers/               # State management
│   └── network_scan_provider.dart   # Central state for scan results
├── screens/                 # Full-screen UI components
│   ├── scanner_screen.dart  # Main scanning interface
│   └── host_details_screen.dart     # Individual host details
└── widgets/                 # Reusable UI components
    ├── network_info_card.dart       # Network information display
    ├── scan_controls.dart           # Start/Stop/Clear controls
    ├── scan_progress.dart           # Progress indicator
    └── host_list_item.dart          # Individual host list item
```

## Architecture Details

### 1. Data Layer (`models/`)

**Host Model** (`host.dart`):
- Represents discovered network devices
- Contains IP address, hostname, MAC address, vendor info
- Tracks online/offline status and response times
- Includes list of detected services
- Provides utility methods for display and comparison

**Service Model** (`service.dart`):
- Represents network services (HTTP, SSH, FTP, etc.)
- Contains port number, service name, and description
- Tracks whether port is open or closed
- Supports JSON serialization for data persistence

**ScanResult Model** (`scan_result.dart`):
- Encapsulates entire scan session data
- Tracks scan progress, status, and timing
- Aggregates all discovered hosts
- Provides statistical methods (online/offline counts)

### 2. Business Logic Layer (`services/`)

**NetworkInfoService** (`network_info_service.dart`):
```dart
class NetworkInfoService {
  // Core Methods:
  Future<String?> getLocalIpAddress()     // Get device's IP
  Future<String?> getSubnetMask()         // Get subnet mask
  Future<String?> getGatewayIp()          // Get gateway IP
  Future<String?> getNetworkName()        // Get network name (SSID)
  List<String> calculateNetworkRange()    // Calculate scan range
  bool isValidIpAddress()                 // IP validation
}
```

**NetworkScannerService** (`network_scanner_service.dart`):
```dart
class NetworkScannerService {
  // Core Methods:
  Stream<Host> scanNetwork()              // Main scanning method
  Future<Host?> _pingHost()               // Individual host ping
  Future<List<Service>> _scanServices()   // Port scanning
  Future<bool> _checkPort()               // Individual port check
  Future<bool> quickPing()                // Fast connectivity check
  void stopScan()                         // Abort current scan
}
```

### 3. State Management (`providers/`)

**NetworkScanProvider** (`network_scan_provider.dart`):
- Uses Flutter's `ChangeNotifier` pattern
- Coordinates between services and UI components
- Manages scan lifecycle and progress tracking
- Provides methods for sorting, filtering, and data manipulation
- Handles error states and recovery

```dart
class NetworkScanProvider extends ChangeNotifier {
  // State Management:
  Future<void> startScan()                // Initialize and start scanning
  void stopScan()                         // Stop current scan
  void clearResults()                     // Clear all results
  Future<void> refreshHost()              // Refresh single host
  void sortHosts()                        // Sort hosts by criteria
  
  // Getters:
  ScanResult get scanResult               // Current scan state
  bool get isScanning                     // Scanning status
  List<Host> get onlineHosts              // Filtered online hosts
}
```

### 4. Presentation Layer (`screens/` & `widgets/`)

**Modular Widget Architecture**:
- Each widget has a single, focused responsibility
- Consistent styling using Theme-based design
- Responsive layouts that adapt to different screen sizes
- Error handling and loading states built into UI components

## Installation & Setup

### Prerequisites

- **Flutter SDK**: Version 3.7.2 or higher
- **Dart SDK**: Included with Flutter
- **Platform-specific tools**:
  - **macOS**: Xcode (for iOS builds)
  - **Android**: Android Studio and SDK
  - **Windows**: Visual Studio
  - **Linux**: Standard development tools

### 1. Environment Setup

```bash
# Verify Flutter installation
flutter doctor

# Enable desired platforms
flutter config --enable-macos-desktop
flutter config --enable-windows-desktop
flutter config --enable-linux-desktop

# Check available devices
flutter devices
```

### 2. Project Setup

```bash
# Clone or navigate to project directory
cd /path/to/network_scanner

# Install dependencies
flutter pub get

# Verify installation
flutter analyze
```

### 3. Platform Configuration

**iOS Configuration** (ios/Runner/Info.plist):
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs access to local network to scan for devices and services.</string>
```

**Android Configuration** (android/app/src/main/AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

## Building & Running

### Development Mode

```bash
# Quick start (auto-detects platform)
flutter run

# Platform-specific runs
flutter run -d macos          # macOS desktop
flutter run -d ios            # iOS simulator
flutter run -d android        # Android emulator/device
flutter run -d chrome         # Web browser
flutter run -d windows        # Windows desktop
flutter run -d linux          # Linux desktop

# Hot reload development
flutter run --hot
```

### Release Builds

```bash
# macOS application (.app bundle)
flutter build macos --release
# Output: build/macos/Build/Products/Release/network_scanner.app

# iOS app (requires Apple Developer account for distribution)
flutter build ios --release
flutter build ipa             # For App Store distribution

# Android APK (for direct installation)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Android App Bundle (for Google Play)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab

# Web application
flutter build web --release
# Output: build/web/

# Windows executable
flutter build windows --release
# Output: build/windows/x64/runner/Release/

# Linux executable  
flutter build linux --release
# Output: build/linux/x64/release/bundle/
```

### Build Optimization

```bash
# Code quality analysis
flutter analyze

# Run all tests
flutter test

# Performance profiling (debug mode)
flutter run --profile

# Check dependencies
flutter pub deps
flutter pub outdated

# Update dependencies
flutter pub upgrade
```

## Extension Guide

### 1. Adding New Service Detection

**Step 1: Add ports to scan list**

```dart
// In services/network_scanner_service.dart
static const List<int> commonPorts = [
  // Existing ports...
  1521,  // Oracle Database
  5432,  // PostgreSQL  
  6379,  // Redis
  27017, // MongoDB
  5984,  // CouchDB
  // Add your custom ports
];
```

**Step 2: Add service definitions**

```dart
static const Map<int, String> serviceNames = {
  // Existing services...
  1521: 'Oracle DB',
  5432: 'PostgreSQL',
  6379: 'Redis',
  27017: 'MongoDB',
  5984: 'CouchDB',
};

String _getServiceDescription(int port) {
  switch (port) {
    // Existing cases...
    case 1521: return 'Oracle Database Server';
    case 5432: return 'PostgreSQL Database Server';
    case 6379: return 'Redis Key-Value Store';
    case 27017: return 'MongoDB Document Database';
    case 5984: return 'CouchDB HTTP API';
    default: return 'Unknown Service';
  }
}
```

### 2. Adding Advanced Host Information

**Step 1: Extend Host model**

```dart
// In models/host.dart
class Host {
  // Existing fields...
  final String? operatingSystem;
  final String? deviceType;        // Router, Printer, Computer, etc.
  final List<String>? openPorts;   // All discovered open ports
  final Map<String, dynamic>? metadata; // Additional device info
  
  // Add to constructor and methods accordingly
}
```

**Step 2: Implement OS detection**

```dart
// In services/network_scanner_service.dart
Future<String?> _detectOperatingSystem(String ipAddress) async {
  try {
    // HTTP banner grabbing
    final httpResponse = await http.get(
      Uri.parse('http://$ipAddress'),
      timeout: Duration(seconds: 2),
    );
    
    if (httpResponse.headers.containsKey('server')) {
      return _parseServerHeader(httpResponse.headers['server']);
    }
    
    // SSH banner grabbing
    final sshBanner = await _getSshBanner(ipAddress);
    if (sshBanner != null) {
      return _parseSshBanner(sshBanner);
    }
    
    return null;
  } catch (e) {
    return null;
  }
}
```

### 3. Adding Network Monitoring

**Step 1: Create monitoring service**

```dart
// Create services/network_monitor_service.dart
class NetworkMonitorService {
  Timer? _monitorTimer;
  final StreamController<NetworkEvent> _eventController = StreamController();
  
  Stream<NetworkEvent> get events => _eventController.stream;
  
  void startMonitoring() {
    _monitorTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkNetworkChanges();
    });
  }
  
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }
  
  Future<void> _checkNetworkChanges() async {
    // Implement change detection logic
  }
}

enum NetworkEventType { deviceJoined, deviceLeft, serviceChanged }

class NetworkEvent {
  final NetworkEventType type;
  final Host host;
  final DateTime timestamp;
  
  NetworkEvent({
    required this.type,
    required this.host,
    required this.timestamp,
  });
}
```

**Step 2: Integrate with provider**

```dart
// In providers/network_scan_provider.dart
class NetworkScanProvider extends ChangeNotifier {
  final NetworkMonitorService _monitorService = NetworkMonitorService();
  
  void enableMonitoring() {
    _monitorService.events.listen((event) {
      _handleNetworkEvent(event);
    });
    _monitorService.startMonitoring();
  }
  
  void _handleNetworkEvent(NetworkEvent event) {
    // Update host list based on network events
    notifyListeners();
  }
}
```

### 4. Adding Data Export

**Step 1: Create export service**

```dart
// Create services/export_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ExportService {
  Future<String> exportToCsv(List<Host> hosts) async {
    final buffer = StringBuffer();
    
    // CSV header
    buffer.writeln('IP Address,Hostname,Status,Response Time,Open Ports,Services');
    
    // Data rows
    for (final host in hosts) {
      final services = host.services.where((s) => s.isOpen)
                          .map((s) => '${s.port}:${s.name}').join(';');
      buffer.writeln('${host.ipAddress},${host.hostname ?? 'Unknown'},'
                    '${host.status.toString()},${host.responseTime ?? 'N/A'},'
                    '${host.openPortsCount},"$services"');
    }
    
    return buffer.toString();
  }
  
  Future<String> exportToJson(ScanResult scanResult) async {
    return jsonEncode(scanResult.toJson());
  }
  
  Future<File> saveToFile(String content, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    return await file.writeAsString(content);
  }
}
```

**Step 2: Add export UI**

```dart
// Create widgets/export_controls.dart
class ExportControls extends StatelessWidget {
  final List<Host> hosts;
  
  const ExportControls({Key? key, required this.hosts}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => _exportCsv(context),
          icon: Icon(Icons.table_chart),
          label: Text('Export CSV'),
        ),
        SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _exportJson(context),
          icon: Icon(Icons.code),
          label: Text('Export JSON'),
        ),
      ],
    );
  }
  
  void _exportCsv(BuildContext context) async {
    final exportService = ExportService();
    final csvContent = await exportService.exportToCsv(hosts);
    final file = await exportService.saveToFile(
      csvContent, 
      'network_scan_${DateTime.now().millisecondsSinceEpoch}.csv'
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported to ${file.path}')),
    );
  }
}
```

### 5. Adding Network Mapping Visualization

**Step 1: Add network topology calculation**

```dart
// Create models/network_topology.dart
class NetworkTopology {
  final String networkRange;
  final Host? gateway;
  final List<NetworkSegment> segments;
  final List<Connection> connections;
  
  NetworkTopology({
    required this.networkRange,
    this.gateway,
    required this.segments,
    required this.connections,
  });
}

class NetworkSegment {
  final String range;
  final List<Host> hosts;
  final SegmentType type;
  
  NetworkSegment({
    required this.range,
    required this.hosts,
    required this.type,
  });
}

enum SegmentType { wired, wireless, guest, iot }

class Connection {
  final Host from;
  final Host to;
  final ConnectionType type;
  final int? latency;
  
  Connection({
    required this.from,
    required this.to,
    required this.type,
    this.latency,
  });
}

enum ConnectionType { direct, routed, bridge }
```

**Step 2: Create visualization widget**

```dart
// Create widgets/network_map.dart
import 'package:flutter/material.dart';

class NetworkMap extends StatefulWidget {
  final NetworkTopology topology;
  
  const NetworkMap({Key? key, required this.topology}) : super(key: key);
  
  @override
  State<NetworkMap> createState() => _NetworkMapState();
}

class _NetworkMapState extends State<NetworkMap> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      child: CustomPaint(
        painter: NetworkTopologyPainter(widget.topology),
        child: Container(),
      ),
    );
  }
}

class NetworkTopologyPainter extends CustomPainter {
  final NetworkTopology topology;
  
  NetworkTopologyPainter(this.topology);
  
  @override
  void paint(Canvas canvas, Size size) {
    // Implement network topology visualization
    _drawGateway(canvas, size);
    _drawHosts(canvas, size);
    _drawConnections(canvas, size);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

### 6. Adding Advanced Scanning Features

**Custom scan profiles:**

```dart
// Create models/scan_profile.dart
class ScanProfile {
  final String name;
  final List<int> ports;
  final Duration timeout;
  final int batchSize;
  final bool enableServiceDetection;
  final bool enableOsDetection;
  
  ScanProfile({
    required this.name,
    required this.ports,
    required this.timeout,
    required this.batchSize,
    required this.enableServiceDetection,
    required this.enableOsDetection,
  });
  
  // Predefined profiles
  static final ScanProfile quick = ScanProfile(
    name: 'Quick Scan',
    ports: [22, 80, 443],
    timeout: Duration(seconds: 1),
    batchSize: 50,
    enableServiceDetection: false,
    enableOsDetection: false,
  );
  
  static final ScanProfile comprehensive = ScanProfile(
    name: 'Comprehensive Scan',
    ports: NetworkScannerService.commonPorts,
    timeout: Duration(seconds: 5),
    batchSize: 10,
    enableServiceDetection: true,
    enableOsDetection: true,
  );
}
```

## API Reference

### NetworkScanProvider Public API

```dart
class NetworkScanProvider extends ChangeNotifier {
  // Properties
  ScanResult get scanResult;
  Map<String, String?> get networkInfo;
  bool get isScanning;
  List<Host> get onlineHosts;
  List<Host> get allHosts;
  
  // Methods
  Future<void> initializeNetworkInfo();
  Future<void> startScan();
  void stopScan();
  void clearResults();
  Future<void> refreshHost(String ipAddress);
  Host? getHostByIp(String ipAddress);
  void sortHosts(HostSortCriteria criteria);
  List<Host> getHostsByStatus(HostStatus status);
}
```

### NetworkScannerService Public API

```dart
class NetworkScannerService {
  // Properties
  bool get isScanning;
  static const List<int> commonPorts;
  static const Map<int, String> serviceNames;
  
  // Methods
  Stream<Host> scanNetwork({Function(double)? onProgress});
  void stopScan();
  Future<bool> quickPing(String ipAddress);
}
```

## Testing

### Test Structure

```
test/
├── unit/                     # Unit tests
│   ├── models/
│   │   ├── host_test.dart
│   │   ├── service_test.dart
│   │   └── scan_result_test.dart
│   ├── services/
│   │   ├── network_info_service_test.dart
│   │   └── network_scanner_service_test.dart
│   └── providers/
│       └── network_scan_provider_test.dart
├── widget/                   # Widget tests
│   ├── host_list_item_test.dart
│   ├── scan_controls_test.dart
│   └── network_info_card_test.dart
└── integration/              # End-to-end tests
    └── app_test.dart
```

### Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/unit/services/network_scanner_service_test.dart

# Tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integration tests
flutter drive --target=test_driver/app.dart
```

### Writing Tests

**Unit Test Example:**
```dart
// test/unit/services/network_scanner_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:network_scanner/services/network_scanner_service.dart';

void main() {
  group('NetworkScannerService', () {
    late NetworkScannerService service;
    
    setUp(() {
      service = NetworkScannerService();
    });
    
    test('should validate IP addresses correctly', () {
      expect(service.quickPing('192.168.1.1'), completes);
      expect(service.quickPing('invalid_ip'), throwsException);
    });
    
    test('should handle scan lifecycle', () {
      expect(service.isScanning, false);
      // Test scan start/stop logic
    });
  });
}
```

## Performance Optimization

### 1. Scanning Performance

```dart
// Configurable parameters in NetworkScannerService
class ScanConfig {
  static const int defaultBatchSize = 20;      // Concurrent pings
  static const Duration pingTimeout = Duration(seconds: 2);
  static const Duration portTimeout = Duration(seconds: 1);
  static const int maxRetries = 2;
  
  // Adjust based on network capacity
  static int getBatchSize(int totalHosts) {
    if (totalHosts > 200) return 10;     // Conservative for large networks
    if (totalHosts > 50) return 20;      // Default for medium networks
    return 30;                           // Aggressive for small networks
  }
}
```

### 2. UI Performance

```dart
// Implement virtual scrolling for large lists
class OptimizedHostList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: hosts.length,
      itemExtent: 80.0,              // Fixed height for performance
      cacheExtent: 400.0,            // Cache off-screen items
      itemBuilder: (context, index) {
        return HostListItem(host: hosts[index]);
      },
    );
  }
}
```

### 3. Memory Management

```dart
// In NetworkScanProvider
class NetworkScanProvider extends ChangeNotifier {
  static const int maxHistorySize = 1000;
  
  void _cleanupOldResults() {
    if (_scanResult.hosts.length > maxHistorySize) {
      final sortedHosts = List<Host>.from(_scanResult.hosts)
        ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
      
      final recentHosts = sortedHosts.take(maxHistorySize).toList();
      _updateScanResult(_scanResult.copyWith(hosts: recentHosts));
    }
  }
}
```

## Security Considerations

### Ethical Scanning

```dart
// Add scanning ethics validation
class ScanEthics {
  static bool isEthicalToScan(String targetIp, String localIp) {
    // Only scan local network ranges
    final localNetwork = _getNetworkAddress(localIp);
    final targetNetwork = _getNetworkAddress(targetIp);
    
    return localNetwork == targetNetwork;
  }
  
  static void enforceRateLimit() {
    // Implement rate limiting to be respectful of network resources
  }
}
```

### Data Protection

```dart
// No persistent storage of sensitive data
// All scan results are ephemeral and stored only in memory
// No external network communications except for scanning
```

## Advanced Features Implementation

### 1. Wake-on-LAN Support

```dart
// services/wake_on_lan_service.dart
import 'dart:typed_data';
import 'dart:io';

class WakeOnLanService {
  Future<void> wakeHost(String macAddress, {String? broadcastAddress}) async {
    final packet = _createMagicPacket(macAddress);
    final address = broadcastAddress ?? '255.255.255.255';
    
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    socket.send(packet, InternetAddress(address), 9);
    socket.close();
  }
  
  Uint8List _createMagicPacket(String macAddress) {
    final mac = macAddress.replaceAll(':', '').replaceAll('-', '');
    final macBytes = List.generate(6, (i) => 
      int.parse(mac.substring(i * 2, i * 2 + 2), radix: 16));
    
    final packet = Uint8List(102);
    
    // 6 bytes of 0xFF
    for (int i = 0; i < 6; i++) {
      packet[i] = 0xFF;
    }
    
    // 16 repetitions of MAC address
    for (int i = 0; i < 16; i++) {
      for (int j = 0; j < 6; j++) {
        packet[6 + i * 6 + j] = macBytes[j];
      }
    }
    
    return packet;
  }
}
```

### 2. SNMP Integration

```dart
// Add dart_snmp package to pubspec.yaml
// services/snmp_service.dart
import 'package:dart_snmp/dart_snmp.dart';

class SnmpService {
  Future<Map<String, dynamic>?> getDeviceInfo(String ipAddress) async {
    try {
      final session = await Snmp.createSession(
        target: InternetAddress(ipAddress),
        community: 'public',
        version: SnmpVersion.v2c,
      );
      
      // Standard OIDs for device information
      final sysName = await session.get(Oid.fromString('1.3.6.1.2.1.1.5.0'));
      final sysDescr = await session.get(Oid.fromString('1.3.6.1.2.1.1.1.0'));
      final sysUptime = await session.get(Oid.fromString('1.3.6.1.2.1.1.3.0'));
      
      session.close();
      
      return {\n        'name': sysName?.value,\n        'description': sysDescr?.value,\n        'uptime': sysUptime?.value,\n      };\n    } catch (e) {\n      return null;\n    }\n  }\n}\n```\n\n### 3. Custom Scanning Algorithms\n\n```dart\n// services/advanced_scanner_service.dart\nclass AdvancedScannerService {\n  Future<List<Host>> tcpSynScan(List<String> ipAddresses, List<int> ports) async {\n    // Implement TCP SYN scanning for faster port detection\n  }\n  \n  Future<List<Host>> udpScan(List<String> ipAddresses, List<int> ports) async {\n    // Implement UDP port scanning\n  }\n  \n  Future<String?> bannerGrabbing(String ipAddress, int port) async {\n    // Implement service banner detection\n    try {\n      final socket = await Socket.connect(ipAddress, port,\n          timeout: Duration(seconds: 3));\n      \n      final buffer = <int>[];\n      socket.listen((data) => buffer.addAll(data));\n      \n      await Future.delayed(Duration(seconds: 1));\n      socket.close();\n      \n      return String.fromCharCodes(buffer).trim();\n    } catch (e) {\n      return null;\n    }\n  }\n}\n```\n\n## Deployment\n\n### App Store Distribution\n\n**iOS App Store:**\n1. Configure signing in Xcode\n2. Update `ios/Runner/Info.plist` with proper app metadata\n3. Build archive: `flutter build ios --release`\n4. Upload via Xcode or Application Loader\n\n**Google Play Store:**\n1. Generate signing key: `keytool -genkey -v -keystore release-key.keystore`\n2. Configure `android/app/build.gradle` with signing config\n3. Build bundle: `flutter build appbundle --release`\n4. Upload via Google Play Console\n\n**macOS App Store:**\n1. Configure entitlements in `macos/Runner/Release.entitlements`\n2. Add sandboxing for App Store compliance\n3. Build: `flutter build macos --release`\n4. Package and upload via Xcode\n\n### Direct Distribution\n\n```bash\n# Create installable packages\n# macOS DMG\ncreate-dmg --volname \"Network Scanner\" \\\n          --window-size 400 300 \\\n          --icon-size 80 \\\n          build/NetworkScanner.dmg \\\n          build/macos/Build/Products/Release/network_scanner.app\n\n# Windows Installer (using Inno Setup or NSIS)\n# Linux AppImage or Snap package\n```\n\n## Configuration Options\n\n### Environment Variables\n\n```dart\n// lib/config/app_config.dart\nclass AppConfig {\n  static const bool enableDebugLogging = bool.fromEnvironment(\n    'DEBUG_LOGGING', \n    defaultValue: false\n  );\n  \n  static const int defaultScanTimeout = int.fromEnvironment(\n    'SCAN_TIMEOUT_SECONDS',\n    defaultValue: 5\n  );\n  \n  static const List<int> customPorts = [\n    // Define via environment or configuration file\n  ];\n}\n```\n\n### Runtime Configuration\n\n```dart\n// services/config_service.dart\nclass ConfigService {\n  static const String configKey = 'app_config';\n  \n  Future<AppSettings> loadSettings() async {\n    final prefs = await SharedPreferences.getInstance();\n    final configJson = prefs.getString(configKey);\n    \n    if (configJson != null) {\n      return AppSettings.fromJson(jsonDecode(configJson));\n    }\n    \n    return AppSettings.defaultSettings();\n  }\n  \n  Future<void> saveSettings(AppSettings settings) async {\n    final prefs = await SharedPreferences.getInstance();\n    await prefs.setString(configKey, jsonEncode(settings.toJson()));\n  }\n}\n\nclass AppSettings {\n  final int scanTimeout;\n  final int batchSize;\n  final List<int> customPorts;\n  final bool enableNotifications;\n  final bool enableAutoRefresh;\n  \n  // Constructor and methods...\n}\n```\n\n## Troubleshooting\n\n### Build Issues\n\n```bash\n# Clean and rebuild\nflutter clean\nflutter pub get\nflutter build [platform]\n\n# Check Flutter environment\nflutter doctor -v\n\n# Update Flutter\nflutter upgrade\n```\n\n### Runtime Issues\n\n**Network permissions:**\n```bash\n# Check platform-specific permissions\n# iOS: Settings > Privacy > Local Network\n# Android: App permissions in device settings\n# macOS: System Preferences > Security & Privacy > Privacy\n```\n\n**Performance issues:**\n- Reduce batch size for slower networks\n- Limit port scanning to essential services\n- Enable debug logging to identify bottlenecks\n\n**Connectivity problems:**\n- Verify device is on same network as scan targets\n- Test basic connectivity: `ping [target_ip]`\n- Check for corporate firewall restrictions\n\n## Contributing\n\n### Development Workflow\n\n1. **Setup development environment**\n2. **Create feature branch**: `git checkout -b feature/new-scanner-type`\n3. **Implement changes** following architecture patterns\n4. **Add tests** for new functionality\n5. **Update documentation**\n6. **Submit pull request**\n\n### Code Style Guidelines\n\n- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) conventions\n- Use `dart format` for consistent formatting\n- Add documentation comments for public APIs\n- Maintain test coverage above 80%\n- Use meaningful commit messages\n\n### Architecture Guidelines\n\n- Keep business logic in `services/` layer\n- Use Provider pattern for state management\n- Create reusable widgets in `widgets/`\n- Maintain clear separation between layers\n- Handle errors gracefully with user feedback\n\n## License\n\nThis project is created for educational purposes. Feel free to use, modify, and distribute according to your needs.\n\n---\n\n**Built with ❤️ using Flutter**", "search_start_line_number": 1}]
