import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';

class OfflineWarningWidget extends StatelessWidget {
  final Object error;

  const OfflineWarningWidget({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final errStr = error.toString().toLowerCase();
    final isOffline =
        errStr.contains('socketexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('connection refused') ||
        errStr.contains('clientexception') ||
        errStr.contains('network is unreachable') ||
        errStr.contains('xmlhttprequest error') ||
        errStr.contains('network error') ||
        errStr.contains('fetch failed') ||
        errStr.contains('offline');

    if (isOffline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.wifiSlash(PhosphorIconsStyle.duotone),
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'You are offline',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    // Default Error Fallback
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Error: $error',
          style: const TextStyle(color: AppTheme.errorColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
