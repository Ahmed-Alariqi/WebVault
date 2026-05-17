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

  /// Shows the professional storage policy dialog explaining hybrid storage.
  static void showStoragePolicy(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Text('نظام التخزين والأمان', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem(
                Icons.storage_rounded,
                'تخزين محلي غيـر محدود',
                'يتم حفظ كافة بياناتك مشفرة على جهازك فقط. لا يوجد قيود على كمية البيانات التي يمكنك حفظها محلياً.',
                isDark,
              ),
              _buildInfoItem(
                Icons.backup_rounded,
                'نسخ احتياطي مرن',
                'يمكنك إنشاء نسخة احتياطية لكامل بياناتك أو استعادتها في أي وقت من خلال الإعدادات لضمان بقائها معك.',
                isDark,
              ),
              _buildInfoItem(
                Icons.cloud_done_rounded,
                'مزامنة سحابية (اختيارية)',
                'المزامنة السحابية هي ميزة إضافية تتيح لك الوصول لبياناتك من أجهزة أخرى بحدود معينة.',
                isDark,
              ),
              _buildInfoItem(
                Icons.security_rounded,
                'نصيحة الأمان القصوى',
                'لحماية بياناتك من الضياع عند حذف التطبيق أو فقدان الجهاز، ننصح دائماً بتصدير نسخة احتياطية وحفظها في مكان آمن.',
                isDark,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('فهمت ذلك', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoItem(IconData icon, String title, String desc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
