import 'dart:async';
import 'dart:io';
import 'package:dart_ping/dart_ping.dart';
import '../models/host.dart';
import '../models/service.dart';
import 'network_info_service.dart';

class NetworkScannerService {
  final NetworkInfoService _networkInfoService = NetworkInfoService();
  bool _isScanning = false;
  
  /// Common ports to scan for services
  static const List<int> commonPorts = [
    21,    // FTP
    22,    // SSH
    23,    // Telnet
    25,    // SMTP
    53,    // DNS
    80,    // HTTP
    110,   // POP3
    143,   // IMAP
    443,   // HTTPS
    993,   // IMAPS
    995,   // POP3S
    1433,  // SQL Server
    3306,  // MySQL
    3389,  // RDP
    5432,  // PostgreSQL
    5900,  // VNC
    8080,  // HTTP Alt
    9200,  // Elasticsearch
  ];

  /// Service name mappings for common ports
  static const Map<int, String> serviceNames = {
    21: 'FTP',
    22: 'SSH',
    23: 'Telnet',
    25: 'SMTP',
    53: 'DNS',
    80: 'HTTP',
    110: 'POP3',
    143: 'IMAP',
    443: 'HTTPS',
    993: 'IMAPS',
    995: 'POP3S',
    1433: 'SQL Server',
    3306: 'MySQL',
    3389: 'RDP',
    5432: 'PostgreSQL',
    5900: 'VNC',
    8080: 'HTTP Alternative',
    9200: 'Elasticsearch',
  };

  bool get isScanning => _isScanning;

  /// Scan the local network for active hosts
  Stream<Host> scanNetwork({
    Function(double)? onProgress,
  }) async* {
    if (_isScanning) return;
    
    _isScanning = true;
    
    try {
      // Get network information
      final localIp = await _networkInfoService.getLocalIpAddress();
      final subnetMask = await _networkInfoService.getSubnetMask();
      
      if (localIp == null || subnetMask == null) {
        throw Exception('Could not get network information');
      }

      // Calculate IP range to scan
      final ipAddresses = _networkInfoService.calculateNetworkRange(localIp, subnetMask);
      
      // Scan addresses in batches to avoid overwhelming the network
      const batchSize = 20;
      
      print('🔍 Starting network scan:');
      print('  - Local IP: $localIp');
      print('  - Subnet: $subnetMask');
      print('  - Scanning ${ipAddresses.length} addresses');
      print('  - IP Range: ${ipAddresses.first} to ${ipAddresses.last}');
      print('  - Batch size: $batchSize');
      
      int scannedCount = 0;
      final totalAddresses = ipAddresses.length;

      for (int i = 0; i < ipAddresses.length; i += batchSize) {
        if (!_isScanning) break;
        
        final batch = ipAddresses.skip(i).take(batchSize);
        final futures = batch.map((ip) => _pingHost(ip));
        
        final results = await Future.wait(futures);
        
        for (final result in results) {
          if (result != null) {
            // Scan for services on discovered hosts
            final services = await _scanServices(result.ipAddress);
            final hostWithServices = result.copyWith(services: services);
            yield hostWithServices;
          }
          
          scannedCount++;
          final progress = scannedCount / totalAddresses;
          onProgress?.call(progress);
        }
        
        // Small delay between batches
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _isScanning = false;
    }
  }

  /// Ping a single host to check if it's online
  Future<Host?> _pingHost(String ipAddress) async {
    print('🏓 Pinging $ipAddress...');
    try {
      final ping = Ping(ipAddress, count: 1);
      final response = await ping.stream.first.timeout(const Duration(seconds: 5));
      
      print('  Response for $ipAddress: error=${response.error}');
      
      if (response.error == null) {
        print('  ✅ $ipAddress is online!');
        
        // Try to resolve hostname
        String? hostname;
        try {
          print('  🔍 Resolving hostname for $ipAddress...');
          final result = await InternetAddress.lookup(ipAddress).timeout(const Duration(seconds: 3));
          if (result.isNotEmpty) {
            hostname = result.first.host;
            print('  📝 Hostname resolved: $hostname');
          }
        } catch (e) {
          print('  ⚠️ Hostname resolution failed for $ipAddress: $e');
          hostname = null;
        }

        final host = Host(
          ipAddress: ipAddress,
          hostname: hostname,
          status: HostStatus.online,
          services: [], // Will be populated by service scan
          lastSeen: DateTime.now(),
          responseTime: response.response?.time?.inMilliseconds,
        );
        
        print('  🎯 Created host object for $ipAddress');
        return host;
      } else {
        print('  ❌ $ipAddress ping failed: ${response.error}');
      }
    } catch (e) {
      print('  💥 Exception pinging $ipAddress: $e');
    }
    
    return null;
  }

  /// Scan for services on a specific host
  Future<List<Service>> _scanServices(String ipAddress) async {
    final services = <Service>[];
    
    // Scan common ports
    final futures = commonPorts.map((port) => _checkPort(ipAddress, port));
    final results = await Future.wait(futures);
    
    for (int i = 0; i < results.length; i++) {
      final isOpen = results[i];
      final port = commonPorts[i];
      final serviceName = serviceNames[port] ?? 'Unknown';
      
      services.add(Service(
        port: port,
        name: serviceName,
        description: _getServiceDescription(port),
        isOpen: isOpen,
      ));
    }
    
    return services.where((s) => s.isOpen).toList();
  }

  /// Check if a specific port is open on a host
  Future<bool> _checkPort(String ipAddress, int port) async {
    try {
      final socket = await Socket.connect(
        ipAddress, 
        port, 
        timeout: const Duration(seconds: 2),
      );
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get service description for a port
  String _getServiceDescription(int port) {
    switch (port) {
      case 21: return 'File Transfer Protocol';
      case 22: return 'Secure Shell';
      case 23: return 'Telnet Protocol';
      case 25: return 'Simple Mail Transfer Protocol';
      case 53: return 'Domain Name System';
      case 80: return 'HyperText Transfer Protocol';
      case 110: return 'Post Office Protocol v3';
      case 143: return 'Internet Message Access Protocol';
      case 443: return 'HTTPS (HTTP Secure)';
      case 993: return 'IMAP over SSL';
      case 995: return 'POP3 over SSL';
      case 1433: return 'Microsoft SQL Server';
      case 3306: return 'MySQL Database';
      case 3389: return 'Remote Desktop Protocol';
      case 5432: return 'PostgreSQL Database';
      case 5900: return 'Virtual Network Computing';
      case 8080: return 'HTTP Alternative Port';
      case 9200: return 'Elasticsearch REST API';
      default: return 'Unknown Service';
    }
  }

  /// Stop the current scan
  void stopScan() {
    _isScanning = false;
  }

  /// Quick ping to check if a host is reachable
  Future<bool> quickPing(String ipAddress) async {
    try {
      final ping = Ping(ipAddress, count: 1);
      final response = await ping.stream.first.timeout(const Duration(seconds: 3));
      return response.error == null;
    } catch (e) {
      return false;
    }
  }
}
