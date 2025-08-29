import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/host.dart';
import '../models/scan_result.dart';
import '../services/network_scanner_service.dart';
import '../services/fallback_scanner_service.dart';
import '../services/network_info_service.dart';

enum HostSortBy {
  ipAddress,
  hostname,
  status,
  lastSeen,
  serviceCount,
}

enum SortOrder {
  ascending,
  descending,
}

class NetworkScanProvider with ChangeNotifier {
  final NetworkScannerService _scannerService = NetworkScannerService();
  final FallbackScannerService _fallbackScannerService = FallbackScannerService();
  final NetworkInfoService _networkInfoService = NetworkInfoService();
  
  bool _useFallbackScanner = false;
  Timer? _scanTimeoutTimer;
  
  ScanResult _scanResult = ScanResult(
    networkRange: '',
    hosts: [],
    status: ScanStatus.idle,
    progress: 0.0,
  );
  
  Map<String, String?> _networkInfo = {};
  StreamSubscription<Host>? _scanSubscription;

  ScanResult get scanResult => _scanResult;
  Map<String, String?> get networkInfo => _networkInfo;
  
  bool get isScanning => _scanResult.status == ScanStatus.scanning;
  List<Host> get onlineHosts => _scanResult.hosts.where((h) => h.isOnline).toList();
  List<Host> get allHosts => _scanResult.hosts;

  /// Initialize network information
  Future<void> initializeNetworkInfo() async {
    try {
      _networkInfo = await _networkInfoService.getNetworkInfo();
      notifyListeners();
    } catch (e) {
      print('Error initializing network info: $e');
    }
  }

  /// Start scanning the network
  Future<void> startScan() async {
    if (isScanning) return;

    print('▶️ NetworkScanProvider: Starting scan...');
    
    try {
      // Initialize network info if not already done
      if (_networkInfo.isEmpty) {
        print('🔄 Initializing network info...');
        await initializeNetworkInfo();
      }
      
      print('Network info: $_networkInfo');
      
      // Clear previous results
      _updateScanResult(ScanResult(
        networkRange: _buildNetworkRange(),
        hosts: [],
        status: ScanStatus.scanning,
        startTime: DateTime.now(),
        progress: 0.0,
      ));

      print('📊 Scan result initialized, starting scanner service...');
      
      // Skip primary scanner and directly use fallback scanner for testing
      print('⚡ Skipping primary scanner, using fallback TCP scanner directly');
      _switchToFallbackScanner();
      
    } catch (e) {
      print('💥 Exception in startScan: $e');
      _updateScanResult(_scanResult.copyWith(
        status: ScanStatus.error,
        error: e.toString(),
        endTime: DateTime.now(),
      ));
    }
  }

  /// Switch to fallback scanner when primary scanner fails or times out
  void _switchToFallbackScanner() async {
    if (_useFallbackScanner) return; // Already using fallback
    
    print('🔄 Switching to fallback TCP scanner...');
    _useFallbackScanner = true;
    
    // Cancel primary scanner
    _scannerService.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    
    try {
      final localIp = _networkInfo['localIp'];
      if (localIp == null) {
        throw Exception('Unable to determine local IP address');
      }
      
      // Start fallback scanner
      final hosts = await _fallbackScannerService.scanNetwork(
        localIp: localIp,
        onProgress: (progress) {
          print('🔍 Fallback scan progress: ${(progress * 100).toInt()}%');
          _updateScanResult(_scanResult.copyWith(progress: progress));
        },
        onHostFound: (host) {
          print('🎯 Fallback scanner found host: ${host.ipAddress}');
          final updatedHosts = List<Host>.from(_scanResult.hosts)..add(host);
          _updateScanResult(_scanResult.copyWith(hosts: updatedHosts));
        },
      );
      
      print('✅ Fallback scan completed! Found ${hosts.length} hosts');
      _updateScanResult(_scanResult.copyWith(
        status: ScanStatus.completed,
        endTime: DateTime.now(),
        progress: 1.0,
        hosts: hosts,
      ));
    } catch (e) {
      print('❌ Fallback scanner error: $e');
      _updateScanResult(_scanResult.copyWith(
        status: ScanStatus.error,
        error: 'Both primary and fallback scanners failed: $e',
        endTime: DateTime.now(),
      ));
    }
  }

  /// Stop the current scan
  void stopScan() {
    if (!isScanning) return;

    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;
    _scannerService.stopScan();
    _fallbackScannerService.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _useFallbackScanner = false;

    _updateScanResult(_scanResult.copyWith(
      status: ScanStatus.completed,
      endTime: DateTime.now(),
    ));
  }

  /// Clear scan results
  void clearResults() {
    _useFallbackScanner = false;
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;
    
    _updateScanResult(ScanResult(
      networkRange: _buildNetworkRange(),
      hosts: [],
      status: ScanStatus.idle,
      progress: 0.0,
    ));
  }

  /// Refresh/rescan a specific host
  Future<void> refreshHost(String ipAddress) async {
    try {
      final isOnline = await _scannerService.quickPing(ipAddress);
      
      final updatedHosts = _scanResult.hosts.map((host) {
        if (host.ipAddress == ipAddress) {
          return host.copyWith(
            status: isOnline ? HostStatus.online : HostStatus.offline,
            lastSeen: DateTime.now(),
          );
        }
        return host;
      }).toList();

      _updateScanResult(_scanResult.copyWith(hosts: updatedHosts));
    } catch (e) {
      print('Error refreshing host $ipAddress: $e');
    }
  }

  /// Get host by IP address
  Host? getHostByIp(String ipAddress) {
    try {
      return _scanResult.hosts.firstWhere((h) => h.ipAddress == ipAddress);
    } catch (e) {
      return null;
    }
  }

  /// Sort hosts by different criteria
  void sortHosts(HostSortCriteria criteria) {
    final sortedHosts = List<Host>.from(_scanResult.hosts);
    
    switch (criteria) {
      case HostSortCriteria.ipAddress:
        sortedHosts.sort((a, b) => _compareIpAddresses(a.ipAddress, b.ipAddress));
        break;
      case HostSortCriteria.hostname:
        sortedHosts.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
      case HostSortCriteria.responseTime:
        sortedHosts.sort((a, b) {
          if (a.responseTime == null && b.responseTime == null) return 0;
          if (a.responseTime == null) return 1;
          if (b.responseTime == null) return -1;
          return a.responseTime!.compareTo(b.responseTime!);
        });
        break;
      case HostSortCriteria.serviceCount:
        sortedHosts.sort((a, b) => b.openPortsCount.compareTo(a.openPortsCount));
        break;
    }

    _updateScanResult(_scanResult.copyWith(hosts: sortedHosts));
  }

  /// Filter hosts by status
  List<Host> getHostsByStatus(HostStatus status) {
    return _scanResult.hosts.where((h) => h.status == status).toList();
  }

  void _updateScanResult(ScanResult newResult) {
    _scanResult = newResult;
    notifyListeners();
  }

  String _buildNetworkRange() {
    final localIp = _networkInfo['localIp'];
    final subnetMask = _networkInfo['subnetMask'];
    
    if (localIp != null && subnetMask != null) {
      return '$localIp/$subnetMask';
    }
    
    return 'Unknown';
  }

  int _compareIpAddresses(String ip1, String ip2) {
    final parts1 = ip1.split('.').map(int.parse).toList();
    final parts2 = ip2.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 4; i++) {
      final comparison = parts1[i].compareTo(parts2[i]);
      if (comparison != 0) return comparison;
    }
    
    return 0;
  }

  @override
  void dispose() {
    stopScan();
    super.dispose();
  }
}

enum HostSortCriteria {
  ipAddress,
  hostname,
  responseTime,
  serviceCount,
}
