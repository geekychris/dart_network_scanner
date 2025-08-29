import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_scan_provider.dart';

class NetworkInfoCard extends StatelessWidget {
  const NetworkInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkScanProvider>(
      builder: (context, provider, child) {
        final networkInfo = provider.networkInfo;
        
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ExpansionTile(
            leading: const Icon(Icons.info_outline),
            title: Text(
              networkInfo['networkName'] ?? 'Network Information',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(networkInfo['localIp'] ?? 'Unknown IP'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('Local IP', networkInfo['localIp']),
                    _buildInfoRow('Subnet Mask', networkInfo['subnetMask']),
                    _buildInfoRow('Gateway IP', networkInfo['gatewayIp']),
                    _buildInfoRow('Network Name', networkInfo['networkName']),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value ?? 'Unknown',
            style: TextStyle(
              fontFamily: 'monospace',
              color: value != null ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
