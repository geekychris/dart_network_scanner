import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/host.dart';
import '../models/service.dart';
import '../providers/network_scan_provider.dart';

class HostDetailsScreen extends StatelessWidget {
  final Host host;

  const HostDetailsScreen({super.key, required this.host});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(host.displayName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<NetworkScanProvider>().refreshHost(host.ipAddress);
            },
            tooltip: 'Refresh host',
          ),
        ],
      ),
      body: Consumer<NetworkScanProvider>(
        builder: (context, provider, child) {
          // Get updated host information from provider
          final currentHost = provider.getHostByIp(host.ipAddress) ?? host;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Host overview card
                _buildHostOverview(currentHost),
                const SizedBox(height: 16),
                
                // Services section
                _buildServicesSection(currentHost),
                const SizedBox(height: 16),
                
                // Additional information
                _buildAdditionalInfo(currentHost),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHostOverview(Host host) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: host.isOnline ? Colors.green : Colors.red,
                  child: Icon(
                    host.isOnline ? Icons.computer : Icons.computer_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        host.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        host.ipAddress,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: host.isOnline ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    host.isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoGrid(host),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(Host host) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildInfoItem('Hostname', host.hostname ?? 'Unknown')),
            Expanded(child: _buildInfoItem('MAC Address', host.macAddress ?? 'Unknown')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildInfoItem('Response Time', 
                host.responseTime != null ? '${host.responseTime}ms' : 'N/A')),
            Expanded(child: _buildInfoItem('Vendor', host.vendor ?? 'Unknown')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildInfoItem('Last Seen', 
                _formatDateTime(host.lastSeen))),
            Expanded(child: _buildInfoItem('Open Ports', '${host.openPortsCount}')),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection(Host host) {
    final openServices = host.services.where((s) => s.isOpen).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_ethernet),
                const SizedBox(width: 8),
                Text(
                  'Services (${openServices.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (openServices.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No services detected',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ...openServices.map((service) => _buildServiceItem(service)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(Service service) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${service.port}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  service.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Open',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(Host host) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow('Status', host.isOnline ? 'Online' : 'Offline'),
            _buildDetailRow('Last Seen', _formatDateTime(host.lastSeen)),
            if (host.responseTime != null)
              _buildDetailRow('Response Time', '${host.responseTime}ms'),
            if (host.macAddress != null)
              _buildDetailRow('MAC Address', host.macAddress!),
            if (host.vendor != null)
              _buildDetailRow('Vendor', host.vendor!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}
