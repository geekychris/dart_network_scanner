import 'dart:math';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkInfoService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Get the local device's IP address
  Future<String?> getLocalIpAddress() async {
    try {
      return await _networkInfo.getWifiIP();
    } catch (e) {
      print('Error getting local IP: $e');
      return null;
    }
  }

  /// Get the local device's subnet mask
  Future<String?> getSubnetMask() async {
    try {
      return await _networkInfo.getWifiSubmask();
    } catch (e) {
      print('Error getting subnet mask: $e');
      return null;
    }
  }

  /// Get the gateway IP address
  Future<String?> getGatewayIp() async {
    try {
      return await _networkInfo.getWifiGatewayIP();
    } catch (e) {
      print('Error getting gateway IP: $e');
      return null;
    }
  }

  /// Get the network name (SSID for WiFi)
  Future<String?> getNetworkName() async {
    try {
      return await _networkInfo.getWifiName();
    } catch (e) {
      print('Error getting network name: $e');
      return null;
    }
  }

  /// Calculate network range from IP and subnet mask
  List<String> calculateNetworkRange(String ipAddress, String subnetMask) {
    print('🔍 calculateNetworkRange: IP=$ipAddress, Mask=$subnetMask');
    
    try {
      final ipParts = ipAddress.split('.').map(int.parse).toList();
      print('  ipParts: $ipParts');
      
      final maskParts = subnetMask.split('.').map(int.parse).toList();
      print('  maskParts: $maskParts');
      
      // Calculate network address
      final networkParts = <int>[];
      for (int i = 0; i < 4; i++) {
        networkParts.add(ipParts[i] & maskParts[i]);
      }
      print('  networkParts: $networkParts');

      // Calculate broadcast address
      final broadcastParts = <int>[];
      for (int i = 0; i < 4; i++) {
        broadcastParts.add(networkParts[i] | (255 - maskParts[i]));
      }
      print('  broadcastParts: $broadcastParts');

      // Generate all IP addresses in the range
      final addresses = <String>[];
      
      // For common subnet masks, generate the range
      print('  Calculating host bits...');
      final hostBits = _calculateHostBits(subnetMask);
      print('  hostBits: $hostBits');
      
      final totalHosts = pow(2, hostBits).toInt() - 2; // Exclude network and broadcast
      print('  totalHosts: $totalHosts');
      
      if (totalHosts > 254) {
        print('  Using large network optimization (254 addresses)');
        // For large networks, limit to first 254 addresses for performance
        for (int i = 1; i <= 254; i++) {
          addresses.add('${networkParts[0]}.${networkParts[1]}.${networkParts[2]}.$i');
        }
      } else {
        print('  Generating full range for network');
        // Generate full range for smaller networks
        for (int lastOctet = networkParts[3] + 1; lastOctet < broadcastParts[3]; lastOctet++) {
          addresses.add('${networkParts[0]}.${networkParts[1]}.${networkParts[2]}.$lastOctet');
        }
      }
      
      print('  Generated ${addresses.length} addresses');
      return addresses;
    } catch (e, stackTrace) {
      print('❌ Error in calculateNetworkRange: $e');
      print('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Calculate the number of host bits in a subnet mask
  int _calculateHostBits(String subnetMask) {
    print('    _calculateHostBits: subnetMask=$subnetMask');
    
    // For standard subnet masks, use simple mapping
    switch (subnetMask) {
      case '255.255.255.0':
        return 8;
      case '255.255.0.0':
        return 16;
      case '255.0.0.0':
        return 24;
      case '255.255.255.128':
        return 7;
      case '255.255.255.192':
        return 6;
      case '255.255.255.224':
        return 5;
      case '255.255.255.240':
        return 4;
      case '255.255.255.248':
        return 3;
      case '255.255.255.252':
        return 2;
      case '255.255.255.254':
        return 1;
      default:
        // Fallback: count bits in binary representation
        print('    Using bit counting fallback for $subnetMask');
        return _countHostBitsGeneric(subnetMask);
    }
  }
  
  /// Generic bit counting for non-standard subnet masks
  int _countHostBitsGeneric(String subnetMask) {
    final maskParts = subnetMask.split('.').map(int.parse).toList();
    int totalBits = 32;
    int networkBits = 0;
    
    for (int part in maskParts) {
      if (part == 255) {
        networkBits += 8;
      } else {
        // Count the set bits in this octet
        int temp = part;
        while (temp > 0) {
          if (temp & 1 == 1) {
            networkBits++;
          }
          temp >>= 1;
        }
        break; // Stop at first non-255 octet
      }
    }
    
    return totalBits - networkBits;
  }

  /// Get network information summary
  Future<Map<String, String?>> getNetworkInfo() async {
    return {
      'localIp': await getLocalIpAddress(),
      'subnetMask': await getSubnetMask(),
      'gatewayIp': await getGatewayIp(),
      'networkName': await getNetworkName(),
    };
  }

  /// Check if an IP address is valid
  bool isValidIpAddress(String ipAddress) {
    try {
      final parts = ipAddress.split('.');
      if (parts.length != 4) return false;
      
      for (String part in parts) {
        final num = int.parse(part);
        if (num < 0 || num > 255) return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
