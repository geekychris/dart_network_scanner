# Network Scanner Flutter App

A Flutter application that scans your local network to discover devices and their running services, similar to "IP Scanner Pro".

## Features

- **Network Discovery**: Automatically detects your local network and scans for active devices
- **Service Detection**: Identifies running services on discovered hosts by scanning common ports
- **Device Information**: Shows hostname, IP address, response time, and MAC address (when available)
- **Real-time Scanning**: Live progress updates during network scans
- **Device Details**: Detailed view of each discovered device with service information
- **Sort & Filter**: Multiple sorting options for discovered hosts
- **Cross-Platform**: Runs on iOS, Android, macOS, and other Flutter-supported platforms

## How to Use

1. **Launch the App**: The app will automatically detect your current network information
2. **Start Scanning**: Tap the "Start Scan" button to begin discovering devices
3. **View Progress**: Monitor the scanning progress in real-time
4. **Browse Results**: View discovered devices in the main list
5. **Device Details**: Tap on any device to see detailed information and services
6. **Refresh**: Use the refresh button to rescan specific devices or clear all results

## Installation

1. Ensure Flutter is installed on your system
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Building

### macOS
```bash
flutter build macos
```

### iOS (requires Xcode)
```bash
flutter build ios
```

### Android (requires Android SDK)
```bash
flutter build apk
```

## Permissions

### Android
- `INTERNET`: Required for network communication
- `ACCESS_NETWORK_STATE`: Required to detect network state  
- `ACCESS_WIFI_STATE`: Required to get WiFi network information

### iOS
- `NSLocalNetworkUsageDescription`: Required for local network access

## Architecture

The app follows a clean, layered architecture:

```
lib/
├── models/          # Data structures (Host, Service, ScanResult)
├── services/        # Business logic (Network scanning, discovery)
├── providers/       # State management (Provider pattern)
├── screens/         # UI screens (Scanner, Host details)
└── widgets/         # Reusable UI components
```

**Key Components:**
- **NetworkScannerService**: Core scanning engine with ping and port detection
- **NetworkInfoService**: Local network information and IP range calculation
- **NetworkScanProvider**: State management with Provider pattern
- **Responsive UI**: Material Design with real-time progress updates

## Quick Start

```bash
# Clone and setup
cd /path/to/project
flutter pub get

# Run on macOS (recommended for development)
flutter run -d macos

# Or run on other platforms
flutter run -d ios      # iOS simulator
flutter run -d android   # Android emulator
flutter run -d chrome    # Web browser
```

## Key Features

### Network Discovery
- Automatic local network detection
- Ping-based host discovery with configurable timeouts
- Concurrent scanning with intelligent batching
- Hostname resolution and response time measurement

### Service Detection
- Port scanning for 18+ common services
- Service identification (SSH, HTTP, HTTPS, databases, etc.)
- Real-time service status updates
- Detailed service descriptions and port information

### User Interface
- Clean, intuitive Material Design interface
- Real-time scanning progress with visual indicators
- Sortable host list (by IP, hostname, response time, services)
- Detailed host view with comprehensive service information
- Pull-to-refresh and manual host refresh capabilities

## Dependencies

### Core Dependencies
- **dart_ping** (^9.0.1): Network ping functionality
- **network_info_plus** (^6.1.4): Network information access
- **provider** (^6.1.2): State management
- **permission_handler** (^11.3.1): Cross-platform permissions
- **http** (^1.2.1): HTTP client for future enhancements

### Development Dependencies
- **flutter_lints** (^5.0.0): Code quality and style enforcement
- **flutter_test**: Testing framework

## Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| **macOS** | ✅ Fully Supported | Recommended for development |
| **iOS** | ✅ Fully Supported | Requires local network permission |
| **Android** | ✅ Fully Supported | Network permissions auto-granted |
| **Web** | ⚠️ Limited | Browser security restrictions |
| **Windows** | ✅ Supported | Desktop functionality |
| **Linux** | ✅ Supported | Desktop functionality |

## Documentation

- **[README_DETAILED.md](README_DETAILED.md)**: Comprehensive documentation with architecture details, extension guides, and advanced features
- **[API Documentation](#)**: Auto-generated API docs (run `dart doc`)
- **Inline Comments**: Detailed code documentation throughout the project

## Extending the App

This app is designed to be easily extensible. See **[README_DETAILED.md](README_DETAILED.md)** for comprehensive guides on:

- Adding new service types and port scanning
- Implementing advanced host detection (OS fingerprinting, device types)
- Creating network monitoring and real-time updates
- Adding data export capabilities (CSV, JSON)
- Building network topology visualization
- Implementing Wake-on-LAN and SNMP integration
- Performance optimization techniques
- Testing strategies and best practices

## Common Use Cases

1. **Network Administration**: Discover devices and services on corporate networks
2. **Home Network Management**: Monitor IoT devices and home automation
3. **Security Assessment**: Identify open ports and running services
4. **Troubleshooting**: Diagnose network connectivity and service issues
5. **Device Inventory**: Catalog network-connected equipment

## Performance Notes

- **Scanning Speed**: ~20 IPs per second (configurable)
- **Memory Usage**: ~50MB for 200+ discovered devices
- **Battery Impact**: Optimized for mobile with intelligent batching
- **Network Load**: Respectful scanning with rate limiting

## Troubleshooting

### Common Issues

**No devices found:**
- Ensure device is connected to WiFi (not cellular)
- Check that target devices respond to ping
- Verify network permissions are granted

**Slow scanning:**
- Reduce batch size in `NetworkScannerService`
- Check network latency with manual ping tests
- Consider scanning fewer ports initially

**Build errors:**
```bash
flutter clean
flutter pub get
flutter doctor  # Check environment
```

---

**For detailed architecture documentation, extension guides, and advanced features, see [README_DETAILED.md](README_DETAILED.md)**
