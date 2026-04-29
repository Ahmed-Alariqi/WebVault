import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/app_localizations.dart';

import '../../presentation/providers/auth_providers.dart';

import '../../presentation/providers/referral_providers.dart';

import '../../core/theme/app_theme.dart';

import '../../core/services/in_app_message_service.dart';

import '../../core/supabase_config.dart';

import '../../core/constants.dart';

import '../../data/models/referral_model.dart';

import '../../presentation/providers/chat_providers.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'dart:ui';

import 'dart:async';



class AppShell extends ConsumerStatefulWidget {

  final Widget child;



  const AppShell({super.key, required this.child});



  @override

  ConsumerState<AppShell> createState() => _AppShellState();

}



class _AppShellState extends ConsumerState<AppShell> {

  @override

  void initState() {

    super.initState();

    // Check for in-app messages globally

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (mounted) {

        InAppMessageService.checkAndShowMessage(context);

        _checkReferralCodeRequirement();

        _checkPendingReferralActivity();

        _checkCommunityBadge();

      }

    });

  }



  // Used to prevent showing the dialog multiple times in one session

  static bool _hasCheckedReferral = false;

  bool _isChatBubbleDismissed = false;

  DateTime? _lastCommunityVisit;

  bool _hasNewCommunityPosts = false;

  StreamSubscription? _latestPostSub;



  @override

  void dispose() {

    _latestPostSub?.cancel();

    super.dispose();

  }



  Future<void> _checkCommunityBadge() async {

    final box = Hive.box(kSettingsBox);

    final lastVisitStr = box.get('last_community_visit') as String?;

    if (lastVisitStr != null) {

      _lastCommunityVisit = DateTime.tryParse(lastVisitStr);

    }



    // Subscribe to the latest community post

    _latestPostSub = SupabaseConfig.client

        .from('community_posts')

        .stream(primaryKey: ['id'])

        .map((data) {

          if (data.isEmpty) return null;

          // Find the newest post

          data.sort((a, b) => b['created_at'].compareTo(a['created_at']));

          return DateTime.parse(data.first['created_at']);

        })

        .listen((latestPostDate) {

          if (latestPostDate == null) return;

          if (_lastCommunityVisit == null ||

              latestPostDate.isAfter(_lastCommunityVisit!)) {

            if (mounted && !_hasNewCommunityPosts) {

              setState(() => _hasNewCommunityPosts = true);

            }

          }

        });

  }



  Future<void> _checkReferralCodeRequirement() async {

    if (_hasCheckedReferral || !mounted) return;

    _hasCheckedReferral = true;



    try {

      // 1. Check if user profile is less than 24 hours old

      final profile = await ref.read(userProfileProvider.future);

      if (profile == null) return;

      if (profile['referred_by'] != null) return;



      final createdAtStr = profile['created_at']?.toString();

      if (createdAtStr == null) return;

      final createdAt = DateTime.tryParse(createdAtStr);

      if (createdAt == null) return;



      final diff = DateTime.now().difference(createdAt);

      if (diff.inHours >= 24) return;



      // 2. Check if a campaign exists

      final campaign = await ref.read(activeReferralCampaignProvider.future);

      if (campaign == null) return;



      if (mounted) {

        _showReferralCodeDialog(campaign);

      }

    } catch (_) {

      // Ignore errors silently for background checks

    }

  }



  /// Check if the current user has a pending referral that can be confirmed

  /// via activity verification. Only runs if an active campaign exists.

  static bool _hasCheckedActivity = false;



  Future<void> _checkPendingReferralActivity() async {

    if (_hasCheckedActivity || !mounted) return;

    _hasCheckedActivity = true;



    try {

      // Gate: only check if an active campaign exists

      final campaign = await ref.read(activeReferralCampaignProvider.future);

      if (campaign == null) return;



      await checkReferralActivityAndConfirm(ref);

    } catch (_) {

      // Fail silently

    }

  }



  Future<void> _showReferralCodeDialog(ReferralCampaign campaign) async {

    if (!mounted) return;



    final codeCtrl = TextEditingController();

    final l10n = AppLocalizations.of(context)!;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool submitting = false;

    String? errorMsg;



    String rewardText = '';

    switch (campaign.referredRewardType) {

      case 'giveaway_entry':

        rewardText =

            'تذكرة انضمام مجانية في سحب ${campaign.referredRewardDescription ?? "الجوائز"} 🎟️';

        break;

      case 'giveaway_boost':

        rewardText = 'تعزيز فرصتك في السحب بـ 3 مشاركات إضافية ⚡';

        break;

      case 'collection_access':

        rewardText = 'صلاحية فتح المجموعات المميزة 🔓';

        break;

      case 'custom':

      default:

        rewardText = campaign.referredRewardDescription?.isNotEmpty == true

            ? campaign.referredRewardDescription!

            : 'مزايا حصرية 🎁';

    }

    final String dynamicDesc = 'أدخل الكود الآن واحصل على:\n$rewardText';



    await showDialog<void>(

      context: context,

      barrierDismissible: false,

      builder: (dialogContext) => StatefulBuilder(

        builder: (ctx, setDialogState) {

          return Dialog(

            backgroundColor: Colors.transparent,

            elevation: 0,

            child: Container(

              width: double.infinity,

              padding: const EdgeInsets.only(bottom: 20),

              decoration: BoxDecoration(

                color: isDark ? AppTheme.darkCard : Colors.white,

                borderRadius: BorderRadius.circular(28),

                boxShadow: [

                  BoxShadow(

                    color: AppTheme.primaryColor.withValues(alpha: 0.15),

                    blurRadius: 40,

                    offset: const Offset(0, 10),

                  ),

                ],

              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  // Header Banner

                  Container(

                    width: double.infinity,

                    padding: const EdgeInsets.symmetric(

                      vertical: 24,

                      horizontal: 20,

                    ),

                    decoration: BoxDecoration(

                      gradient: LinearGradient(

                        colors: [

                          AppTheme.primaryColor.withValues(alpha: 0.8),

                          AppTheme.primaryColor,

                        ],

                        begin: Alignment.topLeft,

                        end: Alignment.bottomRight,

                      ),

                      borderRadius: const BorderRadius.only(

                        topLeft: Radius.circular(28),

                        topRight: Radius.circular(28),

                      ),

                    ),

                    child: Column(

                      children: [

                        Container(

                          padding: const EdgeInsets.all(12),

                          decoration: BoxDecoration(

                            color: Colors.white.withValues(alpha: 0.2),

                            shape: BoxShape.circle,

                          ),

                          child: Icon(

                            PhosphorIcons.gift(PhosphorIconsStyle.fill),

                            size: 40,

                            color: Colors.white,

                          ),

                        ),

                        const SizedBox(height: 16),

                        const Text(

                          'هل تمتلك رمز دعوة؟',

                          style: TextStyle(

                            fontSize: 20,

                            fontWeight: FontWeight.w900,

                            color: Colors.white,

                            letterSpacing: 0.5,

                          ),

                          textAlign: TextAlign.center,

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(height: 24),



                  // Description

                  Padding(

                    padding: const EdgeInsets.symmetric(horizontal: 24),

                    child: Text(

                      dynamicDesc,

                      style: TextStyle(

                        fontSize: 15,

                        height: 1.6,

                        fontWeight: FontWeight.w600,

                        color: isDark ? Colors.white70 : Colors.black87,

                      ),

                      textAlign: TextAlign.center,

                    ),

                  ),

                  const SizedBox(height: 24),



                  // Text Field

                  Padding(

                    padding: const EdgeInsets.symmetric(horizontal: 24),

                    child: TextField(

                      controller: codeCtrl,

                      autofocus: true,

                      textAlign: TextAlign.center,

                      style: TextStyle(

                        fontSize: 20,

                        fontWeight: FontWeight.w800,

                        letterSpacing: 2,

                        color: isDark ? Colors.white : Colors.black87,

                      ),

                      decoration: InputDecoration(

                        hintText: l10n.referralEnterCodeHint,

                        hintStyle: TextStyle(

                          color: isDark ? Colors.white30 : Colors.black26,

                          fontWeight: FontWeight.w500,

                          letterSpacing: 0,

                          fontSize: 16,

                        ),

                        filled: true,

                        fillColor: isDark

                            ? Colors.white.withValues(alpha: 0.05)

                            : Colors.black.withValues(alpha: 0.03),

                        contentPadding: const EdgeInsets.symmetric(

                          vertical: 18,

                          horizontal: 20,

                        ),

                        border: OutlineInputBorder(

                          borderRadius: BorderRadius.circular(16),

                          borderSide: BorderSide(

                            color: isDark

                                ? Colors.white.withValues(alpha: 0.1)

                                : Colors.black.withValues(alpha: 0.1),

                          ),

                        ),

                        focusedBorder: OutlineInputBorder(

                          borderRadius: BorderRadius.circular(16),

                          borderSide: const BorderSide(

                            color: AppTheme.primaryColor,

                            width: 2,

                          ),

                        ),

                      ),

                    ),

                  ),

                  if (errorMsg != null) ...[

                    const SizedBox(height: 12),

                    Padding(

                      padding: const EdgeInsets.symmetric(horizontal: 24),

                      child: Text(

                        errorMsg!,

                        style: const TextStyle(

                          color: AppTheme.errorColor,

                          fontSize: 13,

                          fontWeight: FontWeight.w600,

                        ),

                        textAlign: TextAlign.center,

                      ),

                    ),

                  ],

                  const SizedBox(height: 28),



                  // Action Buttons

                  Padding(

                    padding: const EdgeInsets.symmetric(horizontal: 24),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [

                        ElevatedButton(

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

                                    final result = await submitReferralCode(

                                      code,

                                      ref,

                                    );

                                    if (result == null &&

                                        dialogContext.mounted) {

                                      Navigator.pop(dialogContext);

                                      if (mounted) {

                                        ScaffoldMessenger.of(

                                          context,

                                        ).showSnackBar(

                                          SnackBar(

                                            content: Text(

                                              l10n.referralCodeSuccess,

                                            ),

                                            backgroundColor:

                                                AppTheme.successColor,

                                            behavior: SnackBarBehavior.floating,

                                            shape: RoundedRectangleBorder(

                                              borderRadius:

                                                  BorderRadius.circular(10),

                                            ),

                                          ),

                                        );

                                      }

                                    } else {

                                      setDialogState(() {

                                        submitting = false;

                                        errorMsg = _errorMessage(result, l10n);

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

                            backgroundColor: AppTheme.primaryColor,

                            foregroundColor: Colors.white,

                            padding: const EdgeInsets.symmetric(vertical: 16),

                            elevation: 0,

                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(14),

                            ),

                          ),

                          child: submitting

                              ? const SizedBox(

                                  width: 20,

                                  height: 20,

                                  child: CircularProgressIndicator(

                                    strokeWidth: 2.5,

                                    color: Colors.white,

                                  ),

                                )

                              : Text(

                                  l10n.referralSubmitCode,

                                  style: const TextStyle(

                                    fontSize: 16,

                                    fontWeight: FontWeight.w700,

                                  ),

                                ),

                        ),

                        const SizedBox(height: 12),

                        TextButton(

                          onPressed: () {

                            Navigator.pop(dialogContext);

                          },

                          style: TextButton.styleFrom(

                            minimumSize: const Size(double.infinity, 50),

                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(14),

                            ),

                          ),

                          child: Text(

                            l10n.referralSkipCode,

                            style: TextStyle(

                              fontSize: 15,

                              fontWeight: FontWeight.w600,

                              color: isDark ? Colors.white54 : Colors.black45,

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),

                ],

              ),

            ),

          );

        },

      ),

    );

  }



  String _errorMessage(String? result, AppLocalizations l10n) {

    switch (result) {

      case 'invalid':

        return l10n.referralCodeInvalid;

      case 'self':

        return l10n.referralCodeSelfError;

      case 'already_used':

        return l10n.referralCodeAlreadyUsed;

      case 'no_campaign':

        return l10n.referralCodeNoCampaign;

      default:

        return l10n.referralCodeError;

    }

  }



  static int _calculateSelectedIndex(BuildContext context, bool isAdmin) {

    final location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith('/dashboard')) return 0;

    if (location.startsWith('/pages')) return 1;

    if (location.startsWith('/discover') ||

        location.startsWith('/notifications')) {

      return 2;

    }

    if (location.startsWith('/clipboard')) return 3;

    if (isAdmin && location.startsWith('/admin')) return 4;

    if (!isAdmin && location.startsWith('/community')) return 4;

    if (location.startsWith('/settings')) return 5;

    return 0;

  }



  void _onItemTapped(BuildContext context, int index, bool isAdmin) {

    switch (index) {

      case 0:

        context.go('/dashboard');

        break;

      case 1:

        context.go('/pages');

        break;

      case 2:

        context.go('/discover');

        break;

      case 3:

        context.go('/clipboard');

        break;

      case 4:

        if (isAdmin) {

          context.push('/admin');

        } else {

          // Clear badge when tapped

          if (_hasNewCommunityPosts) {

            setState(() => _hasNewCommunityPosts = false);

            _lastCommunityVisit = DateTime.now().toUtc();

            Hive.box(kSettingsBox).put(

              'last_community_visit',

              _lastCommunityVisit!.toIso8601String(),

            );

          }

          context.go('/community');

        }

        break;

      case 5:

        context.go('/settings');

        break;

    }

  }



  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isAdmin = ref.watch(hasAdminAccessProvider).valueOrNull ?? false;

    final selectedIndex = _calculateSelectedIndex(context, isAdmin);



    return Scaffold(

      body: Stack(

        children: [

          widget.child,

          // Support Chat Bubble Overlay for Users OR Admin Message Alert for Admins

          Positioned(

            top: MediaQuery.of(context).padding.top + 16,

            left: 20,

            right: 20,

            child: Consumer(

              builder: (context, ref, child) {

                final isAdmin =

                    ref.watch(hasAdminAccessProvider).valueOrNull ?? false;



                if (isAdmin) {

                  final adminUnreadCount = ref.watch(

                    adminTotalUnreadCountProvider,

                  );

                  if (adminUnreadCount <= 0 || _isChatBubbleDismissed) {

                    return const SizedBox.shrink();

                  }



                  return TweenAnimationBuilder<double>(

                    tween: Tween(begin: 0.0, end: 1.0),

                    duration: const Duration(milliseconds: 600),

                    curve: Curves.elasticOut,

                    builder: (context, value, child) {

                      return Transform.translate(

                        offset: Offset(0, -60 * (1 - value)),

                        child: Opacity(

                          opacity: value.clamp(0.0, 1.0),

                          child: child,

                        ),

                      );

                    },

                    child: GestureDetector(

                      onTap: () {

                        setState(() => _isChatBubbleDismissed = true);

                        context.push('/admin/user-chats');

                      },

                      child: Container(

                        padding: const EdgeInsets.symmetric(

                          horizontal: 16,

                          vertical: 12,

                        ),

                        decoration: BoxDecoration(

                          gradient: LinearGradient(

                            colors: [

                              Colors.amber.shade700,

                              Colors.amber.shade900,

                            ],

                            begin: Alignment.topLeft,

                            end: Alignment.bottomRight,

                          ),

                          borderRadius: BorderRadius.circular(24),

                          boxShadow: [

                            BoxShadow(

                              color: Colors.amber.withValues(alpha: 0.3),

                              blurRadius: 16,

                              offset: const Offset(0, 8),

                            ),

                          ],

                        ),

                        child: Row(

                          children: [

                            Container(

                              padding: const EdgeInsets.all(8),

                              decoration: const BoxDecoration(

                                color: Colors.white24,

                                shape: BoxShape.circle,

                              ),

                              child: const Icon(

                                PhosphorIconsRegular.usersThree,

                                color: Colors.white,

                                size: 20,

                              ),

                            ),

                            const SizedBox(width: 12),

                            Expanded(

                              child: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,

                                mainAxisSize: MainAxisSize.min,

                                children: [

                                  const Text(

                                    'رسائل المستخدمين',

                                    style: TextStyle(

                                      color: Colors.white70,

                                      fontSize: 12,

                                      fontWeight: FontWeight.w600,

                                    ),

                                  ),

                                  Text(

                                    'لديك ($adminUnreadCount) محادثات بانتظار الرد',

                                    style: const TextStyle(

                                      color: Colors.white,

                                      fontSize: 13,

                                      fontWeight: FontWeight.bold,

                                    ),

                                  ),

                                ],

                              ),

                            ),

                            GestureDetector(

                              onTap: () {

                                setState(() => _isChatBubbleDismissed = true);

                              },

                              child: Container(

                                padding: const EdgeInsets.all(6),

                                decoration: const BoxDecoration(

                                  color: Colors.white24,

                                  shape: BoxShape.circle,

                                ),

                                child: const Icon(

                                  Icons.close,

                                  color: Colors.white,

                                  size: 16,

                                ),

                              ),

                            ),

                          ],

                        ),

                      ),

                    ),

                  );

                }



                // Normal user chat bubble logic

                final unreadCount =

                    ref.watch(userUnreadCountStreamProvider).valueOrNull ?? 0;

                if (unreadCount <= 0 || _isChatBubbleDismissed) {

                  return const SizedBox.shrink();

                }



                return TweenAnimationBuilder<double>(

                  tween: Tween(begin: 0.0, end: 1.0),

                  duration: const Duration(milliseconds: 600),

                  curve: Curves.elasticOut,

                  builder: (context, value, child) {

                    return Transform.translate(

                      offset: Offset(0, -60 * (1 - value)),

                      child: Opacity(

                        opacity: value.clamp(0.0, 1.0),

                        child: child,

                      ),

                    );

                  },

                  child: GestureDetector(

                    onTap: () {

                      setState(() => _isChatBubbleDismissed = true);

                      context.push('/chat');

                    },

                    child: Container(

                      padding: const EdgeInsets.symmetric(

                        horizontal: 16,

                        vertical: 12,

                      ),

                      decoration: BoxDecoration(

                        gradient: LinearGradient(

                          colors: [

                            AppTheme.primaryColor,

                            AppTheme.primaryColor.withValues(alpha: 0.8),

                          ],

                          begin: Alignment.topLeft,

                          end: Alignment.bottomRight,

                        ),

                        borderRadius: BorderRadius.circular(24),

                        boxShadow: [

                          BoxShadow(

                            color: AppTheme.primaryColor.withValues(alpha: 0.3),

                            blurRadius: 16,

                            offset: const Offset(0, 8),

                          ),

                        ],

                      ),

                      child: Row(

                        children: [

                          Container(

                            padding: const EdgeInsets.all(8),

                            decoration: const BoxDecoration(

                              color: Colors.white24,

                              shape: BoxShape.circle,

                            ),

                            child: const Icon(

                              Icons.chat_bubble_rounded,

                              color: Colors.white,

                              size: 20,

                            ),

                          ),

                          const SizedBox(width: 12),

                          Expanded(

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              mainAxisSize: MainAxisSize.min,

                              children: [

                                Text(

                                  AppLocalizations.of(context)!.chatSupport,

                                  style: const TextStyle(

                                    color: Colors.white70,

                                    fontSize: 12,

                                    fontWeight: FontWeight.w600,

                                  ),

                                ),

                                Text(

                                  AppLocalizations.of(

                                    context,

                                  )!.chatNew(unreadCount),

                                  style: const TextStyle(

                                    color: Colors.white,

                                    fontSize: 14,

                                    fontWeight: FontWeight.bold,

                                  ),

                                ),

                              ],

                            ),

                          ),

                          GestureDetector(

                            onTap: () {

                              setState(() => _isChatBubbleDismissed = true);

                            },

                            child: Container(

                              padding: const EdgeInsets.all(6),

                              decoration: const BoxDecoration(

                                color: Colors.white24,

                                shape: BoxShape.circle,

                              ),

                              child: const Icon(

                                Icons.close,

                                color: Colors.white,

                                size: 16,

                              ),

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                );

              },

            ),

          ),



          // ── Zad Expert FAB ──

          Positioned(

            bottom: 140, // Positioning above the bottom nav on the left edge

            left: 0,

            child: _ZadExpertFab(isDark: isDark),

          ),

        ],

      ),

      bottomNavigationBar: SafeArea(

        child: Padding(

          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),

          child: Container(

            decoration: BoxDecoration(

              color: isDark

                  ? AppTheme.darkSurface.withValues(alpha: 0.92)

                  : Colors.white.withValues(alpha: 0.92),

              borderRadius: BorderRadius.circular(28),

              border: Border.all(

                color: isDark

                    ? Colors.white.withValues(alpha: 0.06)

                    : Colors.black.withValues(alpha: 0.04),

                width: 1,

              ),

              boxShadow: [

                BoxShadow(

                  color: AppTheme.primaryColor.withValues(

                    alpha: isDark ? 0.10 : 0.08,

                  ),

                  blurRadius: 24,

                  spreadRadius: 0,

                  offset: const Offset(0, 8),

                ),

                BoxShadow(

                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),

                  blurRadius: 12,

                  offset: const Offset(0, 4),

                ),

              ],

            ),

            child: ClipRRect(

              borderRadius: BorderRadius.circular(28),

              child: BackdropFilter(

                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),

                child: Padding(

                  padding: const EdgeInsets.symmetric(

                    horizontal: 8,

                    vertical: 8,

                  ),

                  child: Row(

                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [

                      _buildNavItem(

                        context,

                        icon: PhosphorIcons.squaresFour(

                          PhosphorIconsStyle.fill,

                        ),

                        inactiveIcon: PhosphorIcons.squaresFour(),

                        label: AppLocalizations.of(context)!.home,

                        index: 0,

                        selectedIndex: selectedIndex,

                        isDark: isDark,

                      ),

                      _buildNavItem(

                        context,

                        icon: PhosphorIcons.browsers(PhosphorIconsStyle.fill),

                        inactiveIcon: PhosphorIcons.browsers(),

                        label: AppLocalizations.of(context)!.pages,

                        index: 1,

                        selectedIndex: selectedIndex,

                        isDark: isDark,

                      ),

                      _buildNavItem(

                        context,

                        icon: PhosphorIcons.compass(PhosphorIconsStyle.fill),

                        inactiveIcon: PhosphorIcons.compass(),

                        label: AppLocalizations.of(context)!.discover,

                        index: 2,

                        selectedIndex: selectedIndex,

                        isDark: isDark,

                      ),

                      _buildNavItem(

                        context,

                        icon: PhosphorIcons.clipboardText(

                          PhosphorIconsStyle.fill,

                        ),

                        inactiveIcon: PhosphorIcons.clipboardText(),

                        label: AppLocalizations.of(context)!.clipboard,

                        index: 3,

                        selectedIndex: selectedIndex,

                        isDark: isDark,

                      ),

                      _buildNavItem(

                        context,

                        icon: isAdmin

                            ? PhosphorIcons.crown(PhosphorIconsStyle.fill)

                            : PhosphorIcons.usersThree(PhosphorIconsStyle.fill),

                        inactiveIcon: isAdmin

                            ? PhosphorIcons.crown()

                            : PhosphorIcons.usersThree(),

                        label: isAdmin

                            ? AppLocalizations.of(context)!.adminDashboard

                            : AppLocalizations.of(context)!.communityTitle,

                        index: 4,

                        selectedIndex: selectedIndex,

                        isDark: isDark,

                        isAdmin: isAdmin,

                      ),

                      _buildNavItem(

                        context,

                        icon: PhosphorIcons.gear(PhosphorIconsStyle.fill),

                        inactiveIcon: PhosphorIcons.gear(),

                        label: AppLocalizations.of(context)!.settings,

                        index: 5,

                        selectedIndex: selectedIndex,

                        isDark: isDark,

                      ),

                    ],

                  ),

                ),

              ),

            ),

          ),

        ),

      ),

    );

  }



  // Premium nav item:
  //   • Inactive  → just an icon (subtle muted colour). Tighter footprint
  //     keeps the bar lean.
  //   • Selected  → expands into a gradient pill (primary → accent) with the
  //     icon and label rendered in white. The pill glows with a soft
  //     brand-coloured shadow so it visually "lifts" off the glass bar.
  //   • Animated using a single AnimatedContainer so taps feel instant but
  //     transitions stay buttery (300 ms easeOutCubic).
  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
    required int index,
    required int selectedIndex,
    required bool isDark,
    bool isAdmin = false,
  }) {
    final isSelected = index == selectedIndex;
    final showCommunityDot =
        !isAdmin && index == 4 && _hasNewCommunityPosts;

    final inactiveColor =
        isDark ? Colors.white.withValues(alpha: 0.62) : Colors.black54;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(context, index, isAdmin),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            // Solid primary tint when selected (no gradient) — matches the
            // app's primary brand colour the user requested.
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isSelected ? icon : inactiveIcon,
                      key: ValueKey(isSelected),
                      size: 22,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : inactiveColor,
                    ),
                  ),
                  if (showCommunityDot)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppTheme.darkSurface
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // Always-visible label so the user can read every tab name.
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.1,
                  fontWeight: isSelected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}



// ── Zad Expert FAB ─────────────────────────────────────────────────────────

class _ZadExpertFab extends StatefulWidget {

  final bool isDark;

  const _ZadExpertFab({required this.isDark});



  @override

  State<_ZadExpertFab> createState() => _ZadExpertFabState();

}



class _ZadExpertFabState extends State<_ZadExpertFab>

    with SingleTickerProviderStateMixin {

  late AnimationController _pulseController;

  late Animation<double> _pulseAnimation;

  // Tap feedback: when true, the FAB protrudes a bit further to acknowledge
  // the press; on tap-up we navigate, then ease back to the resting state.
  bool _isPressed = false;



  @override

  void initState() {

    super.initState();

    _pulseController = AnimationController(

      vsync: this,

      duration: const Duration(milliseconds: 2000),

    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(

      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),

    );

  }



  @override

  void dispose() {

    _pulseController.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return AnimatedBuilder(

      animation: _pulseAnimation,

      builder: (context, child) {

        final glowOpacity = 0.15 + (_pulseAnimation.value * 0.2);

        return Container(

          decoration: BoxDecoration(

            borderRadius: const BorderRadius.only(

              topRight: Radius.circular(20),

              bottomRight: Radius.circular(20),

            ),

            boxShadow: [

              BoxShadow(

                color: const Color(0xFF8B5CF6).withValues(alpha: glowOpacity),

                blurRadius: 10 + (_pulseAnimation.value * 4),

                spreadRadius: 0,

                offset: const Offset(2, 0),

              ),

            ],

          ),

          child: child,

        );

      },

      child: GestureDetector(

        behavior: HitTestBehavior.opaque,

        onTapDown: (_) => setState(() => _isPressed = true),

        onTapCancel: () => setState(() => _isPressed = false),

        onTapUp: (_) async {

          // Briefly protrude further to acknowledge the press, then navigate.

          await Future.delayed(const Duration(milliseconds: 120));

          if (!context.mounted) return;

          context.push('/zad-expert');

          if (mounted) setState(() => _isPressed = false);

        },

        child: AnimatedContainer(

          duration: const Duration(milliseconds: 140),

          curve: Curves.easeOutCubic,

          padding: EdgeInsets.only(

            left: 8,

            right: _isPressed ? 19 : 11,

            top: 12,

            bottom: 12,

          ),

          decoration: BoxDecoration(

            gradient: const LinearGradient(

              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],

              begin: Alignment.bottomLeft,

              end: Alignment.topRight,

            ),

            borderRadius: const BorderRadius.only(

              topRight: Radius.circular(22),

              bottomRight: Radius.circular(22),

            ),

            border: Border(

              right: BorderSide(

                color: Colors.white.withValues(alpha: widget.isDark ? 0.15 : 0.4),

                width: 1.5,

              ),

              top: BorderSide(

                color: Colors.white.withValues(alpha: widget.isDark ? 0.15 : 0.4),

                width: 1.5,

              ),

              bottom: BorderSide(

                color: Colors.white.withValues(alpha: widget.isDark ? 0.15 : 0.4),

                width: 1.5,

              ),

              left: BorderSide.none,

            ),

          ),

          child: const Icon(

            PhosphorIconsFill.sparkle,

            color: Colors.white,

            size: 22,

          ),

        ),

      ),

    );

  }

}



