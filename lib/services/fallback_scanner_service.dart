import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import '../models/host.dart';
import '../models/service.dart';
import 'network_info_service.dart';

class FallbackScannerService {
  final NetworkInfoService _networkInfoService = NetworkInfoService();
  bool _isScanning = false;
  
  /// Quick ports for initial connectivity test (most common)
  static const List<int> quickPorts = [
    80,    // HTTP - most devices have some web interface
    22,    // SSH - very common
    443,   // HTTPS
    445,   // SMB
    139,   // NetBIOS
    135,   // Windows RPC
    23,    // Telnet
    21,    // FTP
    8080,  // HTTP alternate
    3389,  // RDP
  ];
  
  /// Full comprehensive port list for detailed scans
  static const List<int> allPorts = [
    22,    // SSH - very common
    80,    // HTTP - most devices have some web interface
    443,   // HTTPS
    23,    // Telnet
    21,    // FTP
    25,    // SMTP
    53,    // DNS
    110,   // POP3
    143,   // IMAP
    993,   // IMAPS
    995,   // POP3S
    135,   // Windows RPC
    139,   // NetBIOS
    445,   // SMB
    548,   // AFP (Apple Filing Protocol)
    631,   // IPP (Internet Printing Protocol)
    5353,  // mDNS
    8080,  // HTTP alternate
    8443,  // HTTPS alternate
    1883,  // MQTT
    5000,  // UPnP/Flask dev server
    1900,  // UPnP/SSDP
    3389,  // RDP
    5432,  // PostgreSQL
    3306,  // MySQL
    5900,  // VNC
    8000,  // HTTP alternate
    8888,  // HTTP alternate
    9000,  // HTTP alternate
    9090,  // HTTP alternate
    5601,  // Kibana
    9200,  // Elasticsearch
    6379,  // Redis
    27017, // MongoDB
    8181,  // HTTP alternate
    8282,  // HTTP alternate
    3000,  // Node.js/React dev server
    4000,  // HTTP alternate
    5173,  // Vite dev server
    8100,  // Ionic dev server
  ];

  /// Service name mappings
  static const Map<int, String> serviceNames = {
    21: 'FTP',
    22: 'SSH',
    23: 'Telnet',
    25: 'SMTP',
    53: 'DNS',
    80: 'HTTP',
    110: 'POP3',
    135: 'Windows RPC',
    139: 'NetBIOS',
    143: 'IMAP',
    443: 'HTTPS',
    445: 'SMB',
    548: 'AFP',
    631: 'Printer',
    993: 'IMAPS',
    995: 'POP3S',
    1883: 'MQTT',
    1900: 'UPnP',
    3000: 'Node.js',
    3306: 'MySQL',
    3389: 'RDP',
    4000: 'HTTP-Alt',
    5000: 'HTTP-Alt',
    5173: 'Vite',
    5353: 'mDNS',
    5432: 'PostgreSQL',
    5601: 'Kibana',
    5900: 'VNC',
    6379: 'Redis',
    8000: 'HTTP-Alt',
    8080: 'HTTP-Alt',
    8100: 'Ionic',
    8181: 'HTTP-Alt',
    8282: 'HTTP-Alt',
    8443: 'HTTPS-Alt',
    8888: 'HTTP-Alt',
    9000: 'HTTP-Alt',
    9090: 'HTTP-Alt',
    9200: 'Elasticsearch',
    27017: 'MongoDB',
  };

  bool get isScanning => _isScanning;

  /// Scan network using socket connections instead of ping
  Future<List<Host>> scanNetwork({
    required String localIp,
    Function(double)? onProgress,
    Function(Host)? onHostFound,
  }) async {
    if (_isScanning) return [];
    
    _isScanning = true;
    final foundHosts = <Host>[];
    
    try {
      print('🔍 FallbackScanner: Starting socket-based scan...');
      
      // Use the provided localIp and get subnet mask
      final subnetMask = await _networkInfoService.getSubnetMask();
      
      print('📡 Network info - IP: $localIp, Subnet: $subnetMask');
      
      if (subnetMask == null) {
        throw Exception('Could not get subnet mask');
      }

      // Calculate IP range to scan
      List<String> ipAddresses;
      try {
        ipAddresses = _networkInfoService.calculateNetworkRange(localIp, subnetMask);
        print('🔢 Generated ${ipAddresses.length} IP addresses to scan');
        if (ipAddresses.isNotEmpty) {
          print('   Range: ${ipAddresses.first} - ${ipAddresses.last}');
        } else {
          throw Exception('No IP addresses generated for scanning');
        }
      } catch (e) {
        print('❌ Error calculating network range: $e');
        // Fallback to simple range based on IP
        final ipParts = localIp.split('.');
        ipAddresses = [];
        for (int i = 1; i <= 254; i++) {
          ipAddresses.add('${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.$i');
        }
        print('🔄 Using fallback range: ${ipAddresses.length} addresses');
      }
      
      int scannedCount = 0;
      final totalAddresses = ipAddresses.length;

      // Test connectivity using socket connections with optimized batch processing
      const batchSize = 20; // Larger batches for improved parallelism
      
      for (int i = 0; i < ipAddresses.length; i += batchSize) {
        if (!_isScanning) {
          print('🛑 Scan stopped by user');
          break;
        }
        
        print('📦 Processing batch ${(i / batchSize + 1).ceil()} of ${(ipAddresses.length / batchSize).ceil()}');
        
        final batch = ipAddresses.skip(i).take(batchSize);
        final futures = batch.map((ip) => _testHostConnectivity(ip));
        
        final results = await Future.wait(futures);
        
        for (final result in results) {
          if (result != null) {
            print('✅ Found host: ${result.ipAddress}');
            foundHosts.add(result);
            onHostFound?.call(result);
          }
          
          scannedCount++;
          final progress = scannedCount / totalAddresses;
          onProgress?.call(progress);
          
          if (scannedCount % 40 == 0) {
            print('📊 Progress: ${(progress * 100).toInt()}% ($scannedCount/$totalAddresses)');
          }
        }
        
        // Reduced delay between batches
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      print('🎉 Scan completed! Processed $scannedCount addresses, found ${foundHosts.length} hosts');
      return foundHosts;
      
    } finally {
      _isScanning = false;
    }
  }

  /// Test host connectivity using optimized two-phase approach
  Future<Host?> _testHostConnectivity(String ipAddress) async {
    print('🔌 Testing connectivity to $ipAddress');
    
    try {
      final stopwatch = Stopwatch()..start();
      final openServices = <Service>[];
      bool hostIsOnline = false;
      int? responseTime;
      
      // Phase 1: Quick connectivity test
      // First, check if device exists in ARP table (fastest method)
      final arpResult = await _checkArpTable(ipAddress);
      if (arpResult.exists) {
        hostIsOnline = true;
        stopwatch.stop();
        responseTime = stopwatch.elapsedMilliseconds;
        print('  ✅ $ipAddress - Found in ARP table with MAC ${arpResult.macAddress} (${responseTime}ms)');
        
        // Add a pseudo-service to indicate the device was found via ARP
        if (arpResult.macAddress != null) {
          openServices.add(Service(
            port: 0,
            name: 'Device',
            description: 'MAC: ${arpResult.macAddress}',
            isOpen: true,
          ));
        }
        
        // Phase 2: Since host is confirmed online via ARP, do comprehensive port scan
        await _scanAllPorts(ipAddress, openServices);
      } else {
        // Host not in ARP table, try quick port scan first
        hostIsOnline = await _quickPortScan(ipAddress, openServices, stopwatch);
        
        if (hostIsOnline) {
          responseTime = stopwatch.elapsedMicroseconds ~/ 1000;
          // Do full port scan since host is confirmed online
          await _scanRemainingPorts(ipAddress, openServices);
        }
      }

      // If still not found, try alternative connectivity tests
      if (!hostIsOnline) {
        print('  🔄 No quick connectivity found, trying alternative methods...');
        hostIsOnline = await _tryAlternativeConnectivity(ipAddress);
        if (hostIsOnline) {
          stopwatch.stop();
          responseTime = stopwatch.elapsedMilliseconds;
          print('  ✅ $ipAddress - Host detected via alternative method! (${responseTime}ms)');
        }
      }
      
      // Last resort: try ICMP ping (only if host still not found)
      if (!hostIsOnline) {
        final pingResult = await _pingHost(ipAddress);
        if (pingResult) {
          hostIsOnline = true;
          stopwatch.stop();
          responseTime = stopwatch.elapsedMilliseconds;
          print('  ✅ $ipAddress - Host responded to ping! (${responseTime}ms)');
          
          // Add a pseudo-service to indicate ping response
          openServices.add(Service(
            port: 0,
            name: 'ICMP',
            description: 'Responds to ping',
            isOpen: true,
          ));
        }
      }

      if (hostIsOnline) {
        // Try to resolve hostname - use ARP table data if we have it
        String? hostname = arpResult.hostname;
        if (hostname == null) {
          try {
            print('  🔍 Resolving hostname for $ipAddress...');
            final result = await InternetAddress.lookup(ipAddress)
                .timeout(const Duration(seconds: 1));
            if (result.isNotEmpty && result.first.host != ipAddress) {
              hostname = result.first.host;
              print('  📝 Hostname: $hostname');
            }
          } catch (e) {
            // Skip hostname resolution on timeout to speed up scanning
          }
        } else {
          print('  📝 Hostname from ARP: $hostname');
        }

        final host = Host(
          ipAddress: ipAddress,
          hostname: hostname,
          macAddress: arpResult.macAddress,
          status: HostStatus.online,
          services: openServices,
          lastSeen: DateTime.now(),
          responseTime: responseTime,
        );
        
        print('  🎯 Created host: ${host.displayName} (${openServices.length} services)');
        return host;
      }
      
    } catch (e) {
      print('  💥 Exception testing $ipAddress: $e');
    }
    
    return null;
  }
  
  /// Quick port scan using only the most common ports
  Future<bool> _quickPortScan(String ipAddress, List<Service> openServices, Stopwatch stopwatch) async {
    print('  ⚡ Quick port scan on $ipAddress...');
    
    // Test multiple ports concurrently for speed
    final futures = quickPorts.map((port) => _testPort(ipAddress, port, Duration(milliseconds: 500)));
    final results = await Future.wait(futures);
    
    bool foundAny = false;
    for (int i = 0; i < results.length; i++) {
      if (results[i]) {
        final port = quickPorts[i];
        if (!foundAny) {
          stopwatch.stop();
          foundAny = true;
          print('  ✅ $ipAddress:$port - Connected! (quick scan)');
        } else {
          print('  ✅ $ipAddress:$port - Connected!');
        }
        
        openServices.add(Service(
          port: port,
          name: serviceNames[port] ?? 'Unknown',
          description: _getServiceDescription(port),
          isOpen: true,
        ));
      }
    }
    
    return foundAny;
  }
  
  /// Scan remaining ports not covered in quick scan
  Future<void> _scanRemainingPorts(String ipAddress, List<Service> openServices) async {
    print('  🔍 Scanning remaining ports on $ipAddress...');
    
    // Get ports not already scanned in quick scan
    final remainingPorts = allPorts.where((port) => !quickPorts.contains(port)).toList();
    
    // Test ports in smaller batches to avoid overwhelming the network
    const batchSize = 8;
    for (int i = 0; i < remainingPorts.length; i += batchSize) {
      final batch = remainingPorts.skip(i).take(batchSize);
      final futures = batch.map((port) => _testPort(ipAddress, port, Duration(milliseconds: 400)));
      final results = await Future.wait(futures);
      
      for (int j = 0; j < results.length; j++) {
        if (results[j]) {
          final port = batch.elementAt(j);
          print('  ✅ $ipAddress:$port - Connected!');
          
          openServices.add(Service(
            port: port,
            name: serviceNames[port] ?? 'Unknown',
            description: _getServiceDescription(port),
            isOpen: true,
          ));
        }
      }
      
      // Small delay between batches
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
  
  /// Scan all ports for hosts confirmed to be online via ARP
  Future<void> _scanAllPorts(String ipAddress, List<Service> openServices) async {
    print('  🔍 Full port scan on $ipAddress (ARP confirmed)...');
    
    // Since host is confirmed online via ARP, we can use more aggressive scanning
    const batchSize = 10;
    for (int i = 0; i < allPorts.length; i += batchSize) {
      final batch = allPorts.skip(i).take(batchSize);
      final futures = batch.map((port) => _testPort(ipAddress, port, Duration(milliseconds: 400)));
      final results = await Future.wait(futures);
      
      for (int j = 0; j < results.length; j++) {
        if (results[j]) {
          final port = batch.elementAt(j);
          print('  ✅ $ipAddress:$port - Connected!');
          
          openServices.add(Service(
            port: port,
            name: serviceNames[port] ?? 'Unknown',
            description: _getServiceDescription(port),
            isOpen: true,
          ));
        }
      }
      
      // Small delay between batches
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }
  
  /// Test a single port with timeout
  Future<bool> _testPort(String ipAddress, int port, Duration timeout) async {
    try {
      final socket = await Socket.connect(ipAddress, port, timeout: timeout);
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
      case 80: return 'Web Server (HTTP)';
      case 110: return 'Post Office Protocol v3';
      case 135: return 'Windows RPC Endpoint Mapper';
      case 139: return 'NetBIOS Session Service';
      case 143: return 'Internet Message Access Protocol';
      case 443: return 'Secure Web Server (HTTPS)';
      case 445: return 'SMB File Sharing';
      case 548: return 'Apple File Protocol';
      case 631: return 'Internet Printing Protocol';
      case 993: return 'IMAP over SSL';
      case 995: return 'POP3 over SSL';
      case 1883: return 'MQTT Message Broker';
      case 1900: return 'Universal Plug and Play';
      case 5000: return 'Universal Plug and Play';
      case 5353: return 'Multicast DNS';
      case 8080: return 'HTTP Alternative Port';
      case 8443: return 'HTTPS Alternative Port';
      case 3000: return 'Node.js Development Server';
      case 3306: return 'MySQL Database';
      case 3389: return 'Remote Desktop Protocol';
      case 4000: return 'HTTP Alternative Port';
      case 5173: return 'Vite Development Server';
      case 5432: return 'PostgreSQL Database';
      case 5601: return 'Kibana Dashboard';
      case 5900: return 'Virtual Network Computing';
      case 6379: return 'Redis Database';
      case 8000: return 'HTTP Alternative Port';
      case 8100: return 'Ionic Development Server';
      case 8181: return 'HTTP Alternative Port';
      case 8282: return 'HTTP Alternative Port';
      case 8888: return 'HTTP Alternative Port';
      case 9000: return 'HTTP Alternative Port';
      case 9090: return 'HTTP Alternative Port';
      case 9100: return 'HP JetDirect Printer';
      case 9200: return 'Elasticsearch Search Engine';
      case 27017: return 'MongoDB Database';
      default: return 'Network Service';
    }
  }

  /// Stop the current scan
  void stopScan() {
    print('🛑 FallbackScanner: Stop requested');
    _isScanning = false;
  }

  /// Try alternative connectivity methods for devices without open TCP ports
  Future<bool> _tryAlternativeConnectivity(String ipAddress) async {
    try {
      // Method 1: Try connecting to high-numbered ports (IoT devices often use these)
      final highPortResult = await _tryHighPorts(ipAddress);
      if (highPortResult) {
        print('    ✅ High port connectivity detected');
        return true;
      }
      
      // Method 2: Try ARP-style connectivity test using ICMP/UDP ping-like approach
      final arpResult = await _tryArpStyleConnectivity(ipAddress);
      if (arpResult) {
        print('    ✅ ARP-style connectivity detected');
        return true;
      }
      
      print('    ❌ No alternative connectivity detected');
      return false;
    } catch (e) {
      print('    ⚠️ Alternative connectivity test failed: $e');
      return false;
    }
  }
  
  /// ARP-style connectivity test using UDP broadcast/multicast
  Future<bool> _tryArpStyleConnectivity(String ipAddress) async {
    try {
      // Try a very specific test: attempt to connect to a very uncommon port
      // with a very short timeout. If it times out vs connection refused,
      // it suggests there might be a device there
      
      final testPorts = [9, 7, 13]; // Echo, Discard, Daytime - very basic services
      
      for (final port in testPorts) {
        try {
          final socket = await Socket.connect(
            ipAddress,
            port,
            timeout: const Duration(milliseconds: 100), // Very short timeout
          );
          // If we actually connect, that's great - definitely a device
          await socket.close();
          return true;
        } on SocketException catch (e) {
          // Check if the error suggests a device exists but port is closed
          // vs no device at all (different error messages)
          if (e.message.contains('Connection refused') || 
              e.message.contains('actively refused')) {
            // Device exists but port is closed - this is what we want to detect
            return true;
          }
          // Timeout or host unreachable = probably no device
        } catch (e) {
          // Other errors, continue
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Try connecting to high-numbered ports that IoT devices might use
  Future<bool> _tryHighPorts(String ipAddress) async {
    try {
      // Common IoT and device-specific ports
      final iotPorts = [
        8080,  // HTTP alternate
        8443,  // HTTPS alternate
        9100,  // HP JetDirect printer
        10000, // Webmin
        8888,  // Common web interface
        1883,  // MQTT
        8883,  // MQTT over SSL
        5000,  // UPnP
        1900,  // UPnP/SSDP
        8000,  // Common web server
      ];
      
      for (final port in iotPorts) {
        try {
          final socket = await Socket.connect(
            ipAddress,
            port,
            timeout: const Duration(milliseconds: 300),
          );
          await socket.close();
          print('    ✅ Found service on $ipAddress:$port');
          return true;
        } catch (e) {
          // Continue to next port
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Quick connectivity test
  Future<bool> quickConnectivityTest(String ipAddress) async {
    print('⚡ Quick test for $ipAddress');
    
    // First check ARP table (fastest)
    final arpResult = await _checkArpTable(ipAddress);
    if (arpResult.exists) {
      print('  ✅ $ipAddress found in ARP table');
      return true;
    }
    
    // Try the most common ports quickly
    final quickPorts = [80, 22, 443, 135];
    
    for (final port in quickPorts) {
      try {
        final socket = await Socket.connect(
          ipAddress,
          port,
          timeout: const Duration(milliseconds: 300),
        );
        await socket.close();
        print('  ✅ $ipAddress:$port responded');
        return true;
      } catch (e) {
        // Continue to next port
      }
    }
    
    // Try ping as last resort
    final pingResult = await _pingHost(ipAddress);
    if (pingResult) {
      print('  ✅ $ipAddress responds to ping');
      return true;
    }
    
    print('  ❌ $ipAddress - no response on common ports');
    return false;
  }
  
  /// Check if a host exists in the ARP table
  Future<({bool exists, String? macAddress, String? hostname})> _checkArpTable(String ipAddress) async {
    try {
      // Run the ARP command to get the current ARP table
      final result = await Process.run('arp', ['-a']);
      if (result.exitCode != 0) {
        return (exists: false, macAddress: null, hostname: null);
      }
      
      // Parse the output to find the IP address
      final lines = (result.stdout as String).split('\n');
      for (final line in lines) {
        // Check if this line contains our IP address
        if (line.contains(ipAddress)) {
          // Check if it has a MAC address (not incomplete)
          if (!line.contains('(incomplete)')) {
            // Extract the MAC address using regex
            final macRegex = RegExp(r'([0-9A-Fa-f]{1,2}[:-]){5}([0-9A-Fa-f]{1,2})');
            final macMatch = macRegex.firstMatch(line);
            final macAddress = macMatch?.group(0);
            
            // Try to extract hostname
            String? hostname;
            if (line.contains('.attlocal.net')) {
              final parts = line.trim().split(' ');
              if (parts.isNotEmpty) {
                hostname = parts[0];
              }
            }
            
            return (exists: true, macAddress: macAddress, hostname: hostname);
          }
        }
      }
      
      return (exists: false, macAddress: null, hostname: null);
    } catch (e) {
      print('  ⚠️ Error checking ARP table: $e');
      return (exists: false, macAddress: null, hostname: null);
    }
  }
  
  /// Try to ping the host using ICMP
  Future<bool> _pingHost(String ipAddress) async {
    try {
      // Use the ping command with a single packet and short timeout
      final result = await Process.run('ping', ['-c', '1', '-W', '1', ipAddress]);
      
      // Exit code 0 means success
      return result.exitCode == 0;
    } catch (e) {
      print('  ⚠️ Error pinging host: $e');
      return false;
    }
  }
}
