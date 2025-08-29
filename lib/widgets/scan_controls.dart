import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_scan_provider.dart';

class ScanControls extends StatelessWidget {
  const ScanControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkScanProvider>(
      builder: (context, provider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: provider.isScanning ? null : () async {
                    await provider.startScan();
                  },
                  icon: provider.isScanning 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                  label: Text(provider.isScanning ? 'Scanning...' : 'Start Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.isScanning 
                      ? Colors.grey 
                      : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: provider.isScanning ? () {
                    provider.stopScan();
                  } : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.isScanning 
                      ? Colors.red 
                      : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: provider.isScanning ? null : () {
                    provider.clearResults();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
