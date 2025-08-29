import 'package:flutter/material.dart';
import '../models/host.dart';

class HostListItem extends StatelessWidget {
  final Host host;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;

  const HostListItem({
    super.key,
    required this.host,
    this.onTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: host.isOnline ? Colors.green : Colors.red,
          child: Icon(
            host.isOnline ? Icons.computer : Icons.computer_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          host.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              host.ipAddress,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (host.responseTime != null) ...[
                  Icon(Icons.speed, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${host.responseTime}ms',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(Icons.settings_ethernet, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${host.openPortsCount} services',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (host.services.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${host.openPortsCount}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            if (onRefresh != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: onRefresh,
                tooltip: 'Refresh host',
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
