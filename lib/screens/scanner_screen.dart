import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_scan_provider.dart';
import '../models/scan_result.dart';
import '../widgets/host_list_item.dart';
import '../widgets/network_info_card.dart';
import '../widgets/scan_controls.dart';
import '../widgets/scan_progress.dart';
import 'host_details_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NetworkScanProvider>().initializeNetworkInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<NetworkScanProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<HostSortCriteria>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort hosts',
                onSelected: (criteria) => provider.sortHosts(criteria),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: HostSortCriteria.ipAddress,
                    child: Text('Sort by IP Address'),
                  ),
                  const PopupMenuItem(
                    value: HostSortCriteria.hostname,
                    child: Text('Sort by Hostname'),
                  ),
                  const PopupMenuItem(
                    value: HostSortCriteria.responseTime,
                    child: Text('Sort by Response Time'),
                  ),
                  const PopupMenuItem(
                    value: HostSortCriteria.serviceCount,
                    child: Text('Sort by Service Count'),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<NetworkScanProvider>().clearResults();
            },
            tooltip: 'Clear results',
          ),
        ],
      ),
      body: Consumer<NetworkScanProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Network info card
              const NetworkInfoCard(),
              
              // Scan controls
              const ScanControls(),
              
              // Progress indicator
              if (provider.isScanning) const ScanProgress(),
              
              // Scan summary
              _buildScanSummary(provider),
              
              // Host list
              Expanded(
                child: _buildHostList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScanSummary(NetworkScanProvider provider) {
    final result = provider.scanResult;
    
    if (result.hosts.isEmpty && result.status == ScanStatus.idle) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Total', '${result.totalHosts}', Colors.blue),
            _buildSummaryItem('Online', '${result.onlineHosts}', Colors.green),
            _buildSummaryItem('Offline', '${result.offlineHosts}', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildHostList(NetworkScanProvider provider) {
    final hosts = provider.onlineHosts;
    
    if (hosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              provider.isScanning ? 'Scanning for devices...' : 'No devices found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (!provider.isScanning && provider.scanResult.status == ScanStatus.idle)
              const SizedBox(height: 8),
            if (!provider.isScanning && provider.scanResult.status == ScanStatus.idle)
              Text(
                'Tap the scan button to discover devices',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await provider.startScan();
      },
      child: ListView.builder(
        itemCount: hosts.length,
        itemBuilder: (context, index) {
          final host = hosts[index];
          return HostListItem(
            host: host,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HostDetailsScreen(host: host),
                ),
              );
            },
            onRefresh: () {
              provider.refreshHost(host.ipAddress);
            },
          );
        },
      ),
    );
  }
}
