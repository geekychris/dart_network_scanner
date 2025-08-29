import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:dart_ping/dart_ping.dart';

void main() async {
  print('🔍 Network Scanner Debug Tool');
  print('================================');
  
  await testNetworkInfo();
  await testBasicPing();
  await testLocalPing();
}

Future<void> testNetworkInfo() async {
  print('\n📡 Testing Network Information...');
  
  try {
    final info = NetworkInfo();
    
    final localIp = await info.getWifiIP();
    print('Local IP: $localIp');
    
    final subnetMask = await info.getWifiSubmask();
    print('Subnet Mask: $subnetMask');
    
    final gateway = await info.getWifiGatewayIP();
    print('Gateway: $gateway');
    
    final networkName = await info.getWifiName();
    print('Network Name: $networkName');
    
    if (localIp != null && subnetMask != null) {
      print('\n✅ Network info retrieved successfully!');
      
      // Calculate a small range to test
      final ipParts = localIp.split('.').map(int.parse).toList();
      final testRange = <String>[];
      for (int i = 1; i <= 5; i++) {
        testRange.add('${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.$i');
      }
      
      print('Test range: ${testRange.join(', ')}');
    } else {
      print('❌ Failed to get network information');
    }
  } catch (e) {
    print('💥 Error getting network info: $e');
  }
}

Future<void> testBasicPing() async {
  print('\n🏓 Testing Basic Ping...');
  
  final testTargets = [
    '8.8.8.8',        // Google DNS
    '1.1.1.1',        // Cloudflare DNS
  ];
  
  for (final target in testTargets) {
    print('\nPinging $target...');
    try {
      final ping = Ping(target, count: 1);
      final stopwatch = Stopwatch()..start();
      
      await for (final response in ping.stream) {
        stopwatch.stop();
        print('  Response: ${response.response?.toString() ?? 'No response'}');
        print('  Error: ${response.error?.toString() ?? 'None'}');
        print('  Time: ${stopwatch.elapsedMilliseconds}ms');
        break;
      }
    } catch (e) {
      print('  💥 Ping failed: $e');
    }
  }
}

Future<void> testLocalPing() async {
  print('\n🏠 Testing Local Network Ping...');
  
  try {
    final info = NetworkInfo();
    final localIp = await info.getWifiIP();
    final gateway = await info.getWifiGatewayIP();
    
    if (localIp != null) {
      print('\nTesting local IP: $localIp');
      await testSinglePing(localIp);
    }
    
    if (gateway != null) {
      print('\nTesting gateway: $gateway');
      await testSinglePing(gateway);
    }
    
    // Test a few local IPs
    if (localIp != null) {
      final ipParts = localIp.split('.').map(int.parse).toList();
      final localTargets = [
        '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.1',   // Common router IP
        '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.2',   // Common device IP
        '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.100', // Common device IP
      ];
      
      for (final target in localTargets) {
        if (target != localIp) {  // Don't ping ourselves
          print('\nTesting local IP: $target');
          await testSinglePing(target);
        }
      }
    }
    
  } catch (e) {
    print('💥 Error in local ping test: $e');
  }
}

Future<void> testSinglePing(String target) async {
  try {
    print('  Pinging $target...');
    final ping = Ping(target, count: 1);
    final stopwatch = Stopwatch()..start();
    
    final completer = Completer();
    bool responseReceived = false;
    
    // Set up timeout
    Timer(const Duration(seconds: 5), () {
      if (!responseReceived) {
        completer.complete();
        print('  ⏰ Timeout after 5 seconds');
      }
    });
    
    ping.stream.listen((response) {
      if (!responseReceived) {
        responseReceived = true;
        stopwatch.stop();
        
        if (response.error == null) {
          print('  ✅ Success! Time: ${stopwatch.elapsedMilliseconds}ms');
          print('  📊 Response details: ${response.response?.toString() ?? 'No details'}');
        } else {
          print('  ❌ Ping failed: ${response.error}');
        }
        
        completer.complete();
      }
    }, onError: (error) {
      if (!responseReceived) {
        responseReceived = true;
        print('  💥 Ping error: $error');
        completer.complete();
      }
    });
    
    await completer.future;
    
  } catch (e) {
    print('  💥 Exception: $e');
  }
}
