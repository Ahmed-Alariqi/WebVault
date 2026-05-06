import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdminUIUtils {
  AdminUIUtils._();

  /// Shows a unified floating success snackbar with a checkmark icon.
  static void showSuccess(BuildContext context, String message) {
    _showFloatingSnackbar(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: AppTheme.successColor,
    );
  }

  /// Shows a unified floating info snackbar with an info icon.
  static void showInfo(BuildContext context, String message) {
    _showFloatingSnackbar(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: const Color(0xFF455A64), // Blue Grey
      duration: const Duration(seconds: 4),
    );
  }

  /// Shows a unified floating warning snackbar with an alert icon.
  static void showWarning(BuildContext context, String message) {
    _showFloatingSnackbar(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: AppTheme.warningColor,
    );
  }

  /// Shows a unified floating error snackbar with an error icon.
  static void showError(BuildContext context, String message) {
    _showFloatingSnackbar(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: AppTheme.errorColor,
    );
  }

  /// Variant that takes a [ScaffoldMessengerState] directly. Useful when
  /// the caller wants to capture the messenger before closing a sheet/dialog
  /// (so the snackbar still shows after the sheet pops).
  static void showSuccessOn(ScaffoldMessengerState messenger, String message) {
    _showFloatingSnackbarOn(
      messenger,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: AppTheme.successColor,
    );
  }

  static void showErrorOn(ScaffoldMessengerState messenger, String message) {
    _showFloatingSnackbarOn(
      messenger,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: AppTheme.errorColor,
    );
  }

  static void _showFloatingSnackbar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showFloatingSnackbarOn(
      ScaffoldMessenger.of(context),
      message: message,
      icon: icon,
      backgroundColor: backgroundColor,
      duration: duration,
    );
  }

  static void _showFloatingSnackbarOn(
    ScaffoldMessengerState messenger, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
    );
  }
}
