import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_scan_provider.dart';

class ScanProgress extends StatelessWidget {
  const ScanProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkScanProvider>(
      builder: (context, provider, child) {
        final result = provider.scanResult;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scanning Network',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(result.progress * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: result.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                if (result.hosts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Found ${result.onlineHosts} devices so far',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
