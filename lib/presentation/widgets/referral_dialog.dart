import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/referral_model.dart';
import '../../presentation/providers/referral_providers.dart';
import '../../l10n/app_localizations.dart';

Future<void> showReferralCodeDialog(
  BuildContext context,
  WidgetRef ref,
  ReferralCampaign? campaign,
) async {
  final codeCtrl = TextEditingController();
  final l10n = AppLocalizations.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  bool submitting = false;
  String? errorMsg;

  final primaryBlue = AppTheme.primaryColor;
  final accentTeal = AppTheme.accentColor;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: primaryBlue.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Premium Royal Header
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryBlue, accentTeal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.2),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: const Icon(
                                  PhosphorIconsFill.gift,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'تفعيل رمز الدعوة',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                      child: Column(
                        children: [
                          Text(
                            'لديك كود دعوة؟ استلم هديتك الآن! 🎁',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "أدخل كود الدعوة لتستمتع بكافة ميزات 'زاد التقني' المميزة مجاناً. إدخالك للكود يدعم صديقك أيضاً للحصول على مكافأته.",
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          TextField(
                            controller: codeCtrl,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.none, // Allow natural input
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2, // Reduced from 4 to be more natural
                              color: isDark ? Colors.white : primaryBlue,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ABCD123', // More natural hint
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white10 : Colors.black12,
                                letterSpacing: 1.2,
                                fontSize: 20,
                              ),
                              filled: true,
                              fillColor: isDark 
                                ? Colors.white.withValues(alpha: 0.05) 
                                : AppTheme.primaryLight.withValues(alpha: 0.5),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: primaryBlue.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: primaryBlue, width: 2),
                              ),
                            ),
                            onChanged: (v) {
                              // Optional: auto-uppercase for visual consistency if desired, 
                              // but without forcing it in the field behavior if it feels laggy.
                            },
                          ),
                          
                          if (errorMsg != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              errorMsg!,
                              style: const TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          
                          const SizedBox(height: 32),

                          Container(
                            width: double.infinity,
                            height: 52, // Reduced height for more elegance
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                if (!submitting)
                                  BoxShadow(
                                    color: primaryBlue.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: submitting
                                  ? null
                                  : () async {
                                      final code = codeCtrl.text.trim();
                                      if (code.isEmpty) return;

                                      setDialogState(() {
                                        submitting = true;
                                        errorMsg = null;
                                      });

                                      try {
                                        final result = await submitReferralCode(code, ref);
                                        if (result == null && dialogContext.mounted) {
                                          final rewardDays = await ref.read(referredRewardDaysProvider.future);
                                          if (!dialogContext.mounted) return;
                                          Navigator.pop(dialogContext);
                                          
                                          // Show Enhanced Premium Success Dialog
                                          if (context.mounted) {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => Dialog(
                                                backgroundColor: Colors.transparent,
                                                insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                                child: Container(
                                                  constraints: const BoxConstraints(maxWidth: 450),
                                                  padding: const EdgeInsets.all(24),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? AppTheme.darkSurface : Colors.white,
                                                    borderRadius: BorderRadius.circular(32),
                                                    border: Border.all(color: accentTeal.withValues(alpha: 0.5), width: 2),
                                                    boxShadow: [
                                                      BoxShadow(color: accentTeal.withValues(alpha: 0.25), blurRadius: 40, spreadRadius: -10),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      // Success Icon & Title
                                                      Container(
                                                        padding: const EdgeInsets.all(16),
                                                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [primaryBlue, accentTeal])),
                                                        child: const Icon(PhosphorIconsFill.confetti, size: 40, color: Colors.white),
                                                      ),
                                                      const SizedBox(height: 20),
                                                      const Text('تم تفعيل هديتك بنجاح! 🎉', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                                                      const SizedBox(height: 8),
                                                      Text('أنت الآن عضو VIP لمدة $rewardDays أيام كاملة', style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black54), textAlign: TextAlign.center),
                                                      
                                                      const SizedBox(height: 24),
                                                      const Divider(height: 1),
                                                      const SizedBox(height: 24),

                                                      // Premium Benefits Section
                                                      Row(
                                                        children: [
                                                          _BenefitItem(icon: PhosphorIconsFill.lightning, title: 'مزايا حصرية', sub: 'شروحات وأدوات متقدمة', isDark: isDark),
                                                          _BenefitItem(icon: PhosphorIconsFill.robot, title: 'ذكاء متطور', sub: 'شخصيات خبير زاد', isDark: isDark),
                                                          _BenefitItem(icon: PhosphorIconsFill.ticket, title: 'عروض خاصة', sub: 'هدايا وعروض مجانية', isDark: isDark),
                                                        ],
                                                      ),

                                                      const SizedBox(height: 24),
                                                      
                                                      // Friendship Message
                                                      Container(
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                          color: primaryBlue.withValues(alpha: 0.05),
                                                          borderRadius: BorderRadius.circular(16),
                                                          border: Border.all(color: primaryBlue.withValues(alpha: 0.1)),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            const Icon(PhosphorIconsFill.handHeart, color: Colors.pinkAccent, size: 24),
                                                            const SizedBox(width: 12),
                                                            Expanded(
                                                              child: Text(
                                                                'مشاركتك النشطة وإكمال بياناتك عبر الملف الشخصي تضمن حصول صديقك الذي دعاك على مكافأته كاملة.',
                                                                style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.white70 : Colors.black87),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      const SizedBox(height: 32),

                                                      // Actions
                                                      Column(
                                                        children: [
                                                          SizedBox(
                                                            width: double.infinity,
                                                            height: 54,
                                                            child: ElevatedButton(
                                                              onPressed: () => Navigator.pop(ctx),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: accentTeal,
                                                                foregroundColor: Colors.white,
                                                                elevation: 0,
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                              ),
                                                              child: const Text('ابدأ التجربة الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 12),
                                                          TextButton.icon(
                                                            onPressed: () {
                                                              Navigator.pop(ctx);
                                                              // Small delay to ensure current dialog is fully closed
                                                              Future.delayed(const Duration(milliseconds: 300), () {
                                                                if (context.mounted) {
                                                                  // Redirect to share screen
                                                                  Navigator.pushNamed(context, '/referral-share');
                                                                }
                                                              });
                                                            },
                                                            icon: const Icon(PhosphorIconsFill.shareNetwork, size: 20, color: Colors.blueAccent),
                                                            label: const Text('ادعُ أصدقاءك واكسب المزيد 🚀', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        } else {
                                          setDialogState(() {
                                            submitting = false;
                                            errorMsg = _getReferralErrorMessage(result, l10n);
                                          });
                                        }
                                      } catch (e) {
                                        setDialogState(() {
                                          submitting = false;
                                          errorMsg = l10n.referralCodeError;
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: submitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'تأكيد الكود',
                                      style: TextStyle(
                                        fontSize: 16, // Reduced font size
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              l10n.referralSkipCode,
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final bool isDark;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.sub,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            sub,
            style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black45),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _getReferralErrorMessage(String? result, AppLocalizations l10n) {
  switch (result) {
    case 'invalid_code':
      return l10n.referralCodeInvalid;
    case 'self_referral':
      return l10n.referralCodeSelfError;
    case 'already_referred':
      return l10n.referralCodeAlreadyUsed;
    case 'no_campaign':
      return l10n.referralCodeNoCampaign;
    default:
      return l10n.referralCodeError;
  }
}
