import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class LoadingView extends StatelessWidget {
  final String message;

  const LoadingView({super.key, this.message = 'Loading'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: AppTheme.textSecondary),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class OfflineNotice extends StatelessWidget {
  final DateTime? syncedAt;

  const OfflineNotice({super.key, this.syncedAt});

  @override
  Widget build(BuildContext context) {
    final stamp = syncedAt == null
        ? 'no sync recorded'
        : '${syncedAt!.day.toString().padLeft(2, '0')}/'
            '${syncedAt!.month.toString().padLeft(2, '0')} '
            '${syncedAt!.hour.toString().padLeft(2, '0')}:'
            '${syncedAt!.minute.toString().padLeft(2, '0')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      color: const Color(0xFFFFF4E0),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 15, color: Color(0xFF9A6412)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline. Showing data cached on this device ($stamp)',
              style: AppTheme.mono(size: 11, color: const Color(0xFF9A6412)),
            ),
          ),
        ],
      ),
    );
  }
}
