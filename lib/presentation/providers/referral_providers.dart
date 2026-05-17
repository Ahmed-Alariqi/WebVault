import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/supabase_config.dart';
import '../../data/models/referral_model.dart';
import '../../data/models/membership_request_model.dart';
import 'zad_expert_providers.dart';
import 'membership_providers.dart';
import 'auth_providers.dart';

final _supabase = SupabaseConfig.client;

/// The fixed UUID for the default (always-on) membership campaign.
const kDefaultMembershipCampaignId = '00000000-0000-0000-0000-000000000001';

// ══════════════════════════════════════════════════════
//  APP CONFIG PROVIDERS
// ══════════════════════════════════════════════════════

/// Global app settings (key-value from app_settings table).
final appSettingsProvider = FutureProvider<Map<String, String>>((ref) async {
  final response = await _supabase.from('app_settings').select();
  final map = <String, String>{};
  for (final row in response as List) {
    map[row['key'] as String] = row['value'] as String;
  }
  return map;
});

/// Default number of invites required (from app_settings).
final defaultRequiredInvitesProvider = FutureProvider<int>((ref) async {
  final settings = await ref.watch(appSettingsProvider.future);
  return int.tryParse(settings['default_required_invites'] ?? '3') ?? 3;
});

/// Whether membership requests are enabled.
final membershipRequestsEnabledProvider = FutureProvider<bool>((ref) async {
  final settings = await ref.watch(appSettingsProvider.future);
  return settings['membership_requests_enabled'] == 'true';
});

/// Duration (in days) for the referred user reward (from app_settings).
final referredRewardDaysProvider = FutureProvider<int>((ref) async {
  final settings = await ref.watch(appSettingsProvider.future);
  return int.tryParse(settings['referral_referred_reward_days'] ?? '3') ?? 3;
});

// ══════════════════════════════════════════════════════
//  CAMPAIGN PROVIDERS
// ══════════════════════════════════════════════════════

/// All campaigns (admin view)
final referralCampaignsProvider = FutureProvider<List<ReferralCampaign>>((
  ref,
) async {
  final response = await _supabase
      .from('referral_campaigns')
      .select()
      .order('created_at', ascending: false);
  return (response as List).map((j) => ReferralCampaign.fromJson(j)).toList();
});

/// Active + visible campaign for user-facing UI (only the first one)
final activeReferralCampaignProvider = FutureProvider<ReferralCampaign?>((
  ref,
) async {
  final response = await _supabase
      .from('referral_campaigns')
      .select()
      .eq('is_active', true)
      .eq('is_visible', true)
      .order('created_at', ascending: false)
      .limit(1);
  if ((response as List).isEmpty) return null;
  final campaign = ReferralCampaign.fromJson(response.first);
  if (campaign.isExpired) return null;
  return campaign;
});

// ══════════════════════════════════════════════════════
//  REFERRAL CODE PROVIDERS
// ══════════════════════════════════════════════════════

/// Current user's referral code
final myReferralCodeProvider = FutureProvider<ReferralCode?>((ref) async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return null;
  final response = await _supabase
      .from('referral_codes')
      .select()
      .eq('user_id', uid)
      .limit(1);
  if ((response as List).isEmpty) return null;
  return ReferralCode.fromJson(response.first);
});

/// Generate code for current user (called lazily if none exists)
Future<ReferralCode> ensureReferralCode(WidgetRef ref) async {
  final existing = await ref.read(myReferralCodeProvider.future);
  if (existing != null) return existing;

  final uid = _supabase.auth.currentUser!.id;
  // Get username
  final profile = await _supabase
      .from('profiles')
      .select('username')
      .eq('id', uid)
      .single();
  final username = profile['username'] as String? ?? 'user';

  // Generate random suffix: 5 chars alphanumeric (UPPERCASE for professionalism)
  final rand = Random.secure();
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final suffix = List.generate(
    5,
    (_) => chars[rand.nextInt(chars.length)],
  ).join();
  final code = '$username-$suffix'.toUpperCase();

  final resp = await _supabase
      .from('referral_codes')
      .insert({'user_id': uid, 'code': code})
      .select()
      .single();

  ref.invalidate(myReferralCodeProvider);
  return ReferralCode.fromJson(resp);
}

// ══════════════════════════════════════════════════════
//  REFERRAL RECORD PROVIDERS
// ══════════════════════════════════════════════════════

/// My referrals (as referrer) for the active campaign
final myReferralsProvider = FutureProvider<List<Referral>>((ref) async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return [];

  final campaign = await ref.watch(activeReferralCampaignProvider.future);
  if (campaign == null) return [];

  final response = await _supabase
      .from('referrals')
      .select('*, referred:referred_id(full_name, username)')
      .eq('referrer_id', uid)
      .eq('campaign_id', campaign.id)
      .order('created_at', ascending: false);

  return (response as List).map((j) => Referral.fromJson(j)).toList();
});

/// Total confirmed referrals across ALL campaigns (including default).
/// This is used for the "default invite" system when no specific campaign exists.
final myTotalConfirmedReferralsProvider = FutureProvider<int>((ref) async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return 0;

  final response = await _supabase
      .from('referrals')
      .select('id')
      .eq('referrer_id', uid)
      .eq('status', 'confirmed');

  return (response as List).length;
});

/// Confirmed referral count for current user for a specific campaign
final myConfirmedReferralCountProvider = FutureProvider.family<int, String>((
  ref,
  campaignId,
) async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return 0;

  final response = await _supabase
      .from('referrals')
      .select('id')
      .eq('referrer_id', uid)
      .eq('campaign_id', campaignId)
      .eq('status', 'confirmed');

  return (response as List).length;
});

/// All referrals for a campaign (admin view)
final campaignReferralsProvider = FutureProvider.family<List<Referral>, String>((
  ref,
  campaignId,
) async {
  final response = await _supabase
      .from('referrals')
      .select(
        '*, referred:referred_id(full_name, username), referrer:referrer_id(full_name, username)',
      )
      .eq('campaign_id', campaignId)
      .order('created_at', ascending: false);

  return (response as List).map((j) => Referral.fromJson(j)).toList();
});

/// Stats for a campaign (admin view)
final campaignStatsProvider = FutureProvider.family<Map<String, int>, String>((
  ref,
  campaignId,
) async {
  final referrals = await ref.watch(
    campaignReferralsProvider(campaignId).future,
  );
  return {
    'total': referrals.length,
    'confirmed': referrals.where((r) => r.isConfirmed).length,
    'pending': referrals.where((r) => r.isPending).length,
    'rejected': referrals.where((r) => r.isRejected).length,
    'expired': referrals.where((r) => r.isExpired).length,
  };
});

/// Top referrers for a campaign (admin view)
final topReferrersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      campaignId,
    ) async {
      final referrals = await ref.watch(
        campaignReferralsProvider(campaignId).future,
      );
      // Group by referrer
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final r in referrals) {
        grouped.putIfAbsent(
          r.referrerId,
          () => {
            'user_id': r.referrerId,
            'name': r.referrerName ?? '?',
            'username': r.referrerUsername ?? '?',
            'total': 0,
            'confirmed': 0,
          },
        );
        grouped[r.referrerId]!['total'] =
            (grouped[r.referrerId]!['total'] as int) + 1;
        if (r.isConfirmed) {
          grouped[r.referrerId]!['confirmed'] =
              (grouped[r.referrerId]!['confirmed'] as int) + 1;
        }
      }
      final list = grouped.values.toList()
        ..sort(
          (a, b) => (b['confirmed'] as int).compareTo(a['confirmed'] as int),
        );
      return list;
    });

/// Reward status for the current user as a referrer
/// Returns a map with 'earned' (bool), 'rewardType', 'giveawayName', etc.
final myReferralRewardStatusProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return {'earned': false};

  final campaign = await ref.watch(activeReferralCampaignProvider.future);
  if (campaign == null) return {'earned': false};

  final confirmed = await ref.watch(
    myConfirmedReferralCountProvider(campaign.id).future,
  );

  if (confirmed < campaign.requiredReferrals) {
    return {'earned': false};
  }

  // User has earned the reward!
  String? giveawayName;
  if (campaign.rewardGiveawayId != null) {
    try {
      final giveaway = await _supabase
          .from('giveaways')
          .select('title')
          .eq('id', campaign.rewardGiveawayId!)
          .single();
      giveawayName = giveaway['title'] as String?;
    } catch (_) {}
  }

  return {
    'earned': true,
    'rewardType': campaign.rewardType,
    'rewardDescription': campaign.rewardDescription,
    'giveawayName': giveawayName,
    'collectionId': campaign.rewardCollectionId,
  };
});

/// Reward status for the current user as a referred user
/// Returns null if no reward, or a map with reward details
final myReferredRewardProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return null;

  final campaign = await ref.watch(activeReferralCampaignProvider.future);
  if (campaign == null) return null;
  if (campaign.referredRewardType == 'none') return null;

  // Check if this user has a confirmed referral as a referred user
  final referral = await _supabase
      .from('referrals')
      .select('status')
      .eq('referred_id', uid)
      .eq('campaign_id', campaign.id)
      .eq('status', 'confirmed')
      .limit(1);

  if ((referral as List).isEmpty) return null;

  // User has earned the referred reward!
  String? giveawayName;
  if (campaign.rewardGiveawayId != null) {
    try {
      final giveaway = await _supabase
          .from('giveaways')
          .select('title')
          .eq('id', campaign.rewardGiveawayId!)
          .single();
      giveawayName = giveaway['title'] as String?;
    } catch (_) {}
  }

  return {
    'rewardType': campaign.referredRewardType,
    'rewardDescription': campaign.referredRewardDescription,
    'giveawayName': giveawayName,
  };
});

/// Check if the user has already been referred
final hasBeenReferredProvider = FutureProvider<bool>((ref) async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return false;
  final profile = await _supabase
      .from('profiles')
      .select('referred_by')
      .eq('id', uid)
      .single();
  return profile['referred_by'] != null;
});

/// Check if user qualifies for a specific referral-exclusive collection
/// (either via referrals OR via a manual admin grant).
final isEligibleForCollectionProvider =
    FutureProvider.family<bool, String>((ref, collectionId) async {
  // 1. Check if user is an admin
  final isAdmin = await ref.watch(isAdminProvider.future);
  if (isAdmin) return true;

  // 2. Check the new robust membership status
  final memStatus = ref.watch(membershipStatusProvider);
  if (memStatus.hasAccessTo(type: 'collection', id: collectionId)) {
    return true;
  }

  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return false;

  // 3. Fallback to existing manual_user_ids check for backward compatibility
  try {
    final col = await _supabase
        .from('featured_collections')
        .select('manual_user_ids')
        .eq('id', collectionId)
        .maybeSingle();
    final ids = (col?['manual_user_ids'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    if (ids.contains(uid)) return true;
  } catch (_) {}

  // 4. Referral-based eligibility (fallback to check if any campaign rewards this collection)
  final campaigns = await _supabase
      .from('referral_campaigns')
      .select('id, required_referrals')
      .eq('reward_type', 'collection_access')
      .eq('reward_collection_id', collectionId)
      .eq('is_active', true);

  if ((campaigns as List).isEmpty) return false;

  // Check each campaign if user has enough confirmed referrals
  for (final c in campaigns) {
    final required = c['required_referrals'] as int;
    final cId = c['id'] as String;

    final referrals = await _supabase
        .from('referrals')
        .select('id')
        .eq('referrer_id', uid)
        .eq('campaign_id', cId)
        .eq('status', 'confirmed');

    if ((referrals as List).length >= required) return true;
  }
  return false;
});

// ══════════════════════════════════════════════════════
//  ACTIONS
// ══════════════════════════════════════════════════════

/// Submit a referral code (called by the referred user)
/// Referral stays as 'pending' until activity verification passes.
/// Now works even without an active campaign by using the default system campaign.
Future<String?> submitReferralCode(String code, WidgetRef ref) async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return 'Not logged in';

  // 1. Check if already referred
  final profile = await _supabase
      .from('profiles')
      .select('referred_by')
      .eq('id', uid)
      .single();
  if (profile['referred_by'] != null) {
    return 'already_referred';
  }

  // 2. Find the code
  final codeResp = await _supabase
      .from('referral_codes')
      .select()
      .eq('code', code.trim().toUpperCase())
      .limit(1);
  if ((codeResp as List).isEmpty) {
    return 'invalid_code';
  }
  final referralCode = ReferralCode.fromJson(codeResp.first);

  // 3. Self-referral check
  if (referralCode.userId == uid) {
    return 'self_referral';
  }

  // 4. Find active campaign OR fall back to default membership campaign
  final campaign = await ref.read(activeReferralCampaignProvider.future);
  final campaignId = campaign?.id ?? kDefaultMembershipCampaignId;

  // 5. Insert the referral as PENDING (no auto-confirm)
  try {
    await _supabase.from('referrals').insert({
      'campaign_id': campaignId,
      'referrer_id': referralCode.userId,
      'referred_id': uid,
      'status': 'pending',
    });

    // 6. Update profile.referred_by
    await _supabase
        .from('profiles')
        .update({'referred_by': referralCode.userId})
        .eq('id', uid);

    // 7. NEW: Grant instant reward to the REFERRED user
    try {
      final rewardDays = await ref.read(referredRewardDaysProvider.future);
      await ref.read(membershipManagementProvider).grantMembership(
            userId: uid,
            duration: Duration(days: rewardDays),
            scope: MembershipScope.global,
          );
      
      // Update local state so UI reflects premium status immediately
      ref.invalidate(userProfileProvider);
    } catch (e) {
      debugPrint('Error granting instant referral reward: $e');
      // We don't return error here because the referral itself succeeded
    }

    ref.invalidate(hasBeenReferredProvider);
    ref.invalidate(myReferralsProvider);
    ref.invalidate(myTotalConfirmedReferralsProvider);
    return null; // success
  } catch (e) {
    if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
      return 'already_referred';
    }
    return 'error';
  }
}

/// Check if the current referred user meets activity requirements
/// to auto-confirm their pending referral.
///
/// Requirements (all must be met within 3 days of referral creation):
/// 1. Profile complete: full_name + username both non-empty
/// 2. At least 3 app_open events
/// 3. At least 1 content activity: item_view, clipboard_add, page_add, search, or bookmark
///
/// This should only be called if an active campaign exists.
Future<void> checkReferralActivityAndConfirm(WidgetRef ref) async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return;

  try {
    // 1. Find pending referral for this user
    final pending = await _supabase
        .from('referrals')
        .select('id, campaign_id, created_at, referrer_id')
        .eq('referred_id', uid)
        .eq('status', 'pending')
        .limit(1);

    if ((pending as List).isEmpty) return;

    final referralId = pending.first['id'] as String;
    final campaignId = pending.first['campaign_id'] as String;
    final referrerId = pending.first['referrer_id'] as String;
    final createdAt = DateTime.parse(pending.first['created_at'] as String);

    // 2. Check if 3-day grace period has expired
    final now = DateTime.now().toUtc();
    final deadline = createdAt.add(const Duration(days: 3));
    if (now.isAfter(deadline)) {
      // Grace period expired — mark as expired
      await _supabase
          .from('referrals')
          .update({'status': 'expired'})
          .eq('id', referralId);
      ref.invalidate(myReferralsProvider);
      return;
    }

    // 3. Check profile completeness
    final profile = await _supabase
        .from('profiles')
        .select('full_name, username')
        .eq('id', uid)
        .single();

    final hasName = (profile['full_name'] as String?)?.isNotEmpty ?? false;
    final hasUsername = (profile['username'] as String?)?.isNotEmpty ?? false;
    if (!hasName || !hasUsername) return; // Not ready yet

    // 4. Check app_open count (must be >= 3 since referral creation)
    final appOpens = await _supabase
        .from('user_activity')
        .select('id')
        .eq('user_id', uid)
        .eq('activity_type', 'app_open')
        .gte('created_at', createdAt.toIso8601String());

    if ((appOpens as List).length < 3) return; // Not enough logins

    // 5. Check content activity (at least 1)
    final contentActivity = await _supabase
        .from('user_activity')
        .select('id')
        .eq('user_id', uid)
        .inFilter('activity_type', [
          'item_view',
          'clipboard_add',
          'page_add',
          'search',
          'bookmark',
        ])
        .gte('created_at', createdAt.toIso8601String())
        .limit(1);

    if ((contentActivity as List).isEmpty) return; // No content activity

    // ✅ All conditions met — confirm the referral
    await _supabase
        .from('referrals')
        .update({
          'status': 'confirmed',
          'confirmed_at': now.toIso8601String(),
          'verified_at': now.toIso8601String(),
        })
        .eq('id', referralId);

    // Process rewards
    final campaignResp = await _supabase
        .from('referral_campaigns')
        .select()
        .eq('id', campaignId)
        .single();
    final campaign = ReferralCampaign.fromJson(campaignResp);

    // Grant referred user reward (giveaway_entry)
    if (campaign.referredRewardType == 'giveaway_entry' &&
        campaign.rewardGiveawayId != null) {
      try {
        await _supabase.from('giveaway_entries').insert({
          'giveaway_id': campaign.rewardGiveawayId,
          'user_id': uid,
        });
      } catch (_) {
        // May already be entered
      }
    }

    await _processRewardsIfComplete(campaign, ref, referrerId: referrerId);
    ref.invalidate(myReferralsProvider);

    debugPrint('Referral $referralId confirmed via activity verification');
  } catch (e) {
    debugPrint('checkReferralActivityAndConfirm error: $e');
  }
}

/// Check if referrer has reached the target and process rewards
Future<void> _processRewardsIfComplete(
  ReferralCampaign campaign,
  WidgetRef ref, {
  String? referrerId,
}) async {
  if (referrerId != null) {
    final confirmedCount = await ref.read(
      myConfirmedReferralCountProvider(campaign.id).future,
    );
    if (confirmedCount >= campaign.requiredReferrals) {
      await _grantReward(referrerId, campaign, ref);
    }
    return;
  }

  // Fallback: check all referrers (rarely needed)
  final allReferrals = await _supabase
      .from('referrals')
      .select('referrer_id')
      .eq('campaign_id', campaign.id)
      .eq('status', 'confirmed');

  // Group by referrer and count
  final Map<String, int> counts = {};
  for (final r in allReferrals as List) {
    final rid = r['referrer_id'] as String;
    counts[rid] = (counts[rid] ?? 0) + 1;
  }

  for (final entry in counts.entries) {
    if (entry.value >= campaign.requiredReferrals) {
      await _grantReward(entry.key, campaign, ref);
    }
  }
}

Future<void> _grantReward(String referrerId, ReferralCampaign campaign, WidgetRef ref) async {
  // Check if reward was already granted to avoid duplicate notifications.
  // We check if the user already has a membership that expires far in the future (year 2100).
  try {
    final profile = await _supabase.from('profiles').select('premium_until').eq('id', referrerId).single();
    final untilStr = profile['premium_until'] as String?;
    if (untilStr != null) {
      final until = DateTime.tryParse(untilStr);
      if (until != null && until.year >= 2100) {
        // Reward already granted, skip to avoid spamming notifications
        return;
      }
    }
  } catch (e) {
    debugPrint('Error checking reward idempotency: $e');
  }

  // Always grant Permanent Global Premium as a bonus reward for completing any campaign goal
  try {
    await ref.read(membershipManagementProvider).grantMembership(
      userId: referrerId,
      duration: const Duration(days: 36500), // ~100 years = Permanent
      scope: MembershipScope.global,
    );

    // Send a more specific referral-success notification
    await ref.read(membershipManagementProvider).sendMembershipNotification(
      userId: referrerId,
      title: 'إنجاز رائع! 🏆',
      body: 'لقد حققت هدف الدعوات بنجاح! تم منحك العضوية الدائمة كجائزة على مجهودك.',
    );
  } catch (e) {
    debugPrint('Error granting auto-membership reward: $e');
  }

  switch (campaign.rewardType) {
    case 'giveaway_entry':
      if (campaign.rewardGiveawayId == null) return;
      // Auto-enter referrer into the giveaway
      try {
        await _supabase.from('giveaway_entries').insert({
          'giveaway_id': campaign.rewardGiveawayId,
          'user_id': referrerId,
        });
      } catch (_) {
        // Already entered
      }
      break;

    case 'giveaway_boost':
      if (campaign.rewardGiveawayId == null) return;
      // Add extra entries (3 extra entries as boost)
      for (int i = 0; i < 3; i++) {
        try {
          await _supabase.from('giveaway_entries').insert({
            'giveaway_id': campaign.rewardGiveawayId,
            'user_id': referrerId,
            'entry_value': 'referral_boost_${i + 1}',
          });
        } catch (_) {
          // Ignore
        }
      }
      break;

    case 'collection_access':
      // Access is checked dynamically via isEligibleForCollectionProvider
      // No action needed — RLS/provider handles it
      break;

    case 'custom':
      // Admin handles manually — no automatic action
      break;
  }

  // Send notification for reward
  String title = '🎁 مبروك! لقد حصلت على مكافأة';
  String body = '';

  switch (campaign.rewardType) {
    case 'giveaway_entry':
      body = 'تم تسجيلك في السحب بنجاح لتجاوزك عدد الإحالات المطلوبة.';
      break;
    case 'giveaway_boost':
      body = 'تم تعزيز فرصك في السحب بـ 3 مشاركات إضافية.';
      break;
    case 'collection_access':
      body = 'تم منحك صلاحية الوصول للمحتوى المميز بنجاح.';
      break;
    case 'custom':
      body = campaign.rewardDescription ?? 'تواصل مع الدعم لاستلام مكافأتك.';
      break;
  }

  if (body.isNotEmpty) {
    await sendNotification(
      userId: referrerId,
      title: title,
      body: body,
      type: 'reward',
    );
  }
}

// ══════════════════════════════════════════════════════
//  ADMIN ACTIONS
// ══════════════════════════════════════════════════════

/// Create a new campaign
Future<String> createReferralCampaign(
  Map<String, dynamic> data,
  WidgetRef ref,
) async {
  data['created_by'] = _supabase.auth.currentUser!.id;
  final resp = await _supabase
      .from('referral_campaigns')
      .insert(data)
      .select('id')
      .single();
  ref.invalidate(referralCampaignsProvider);
  ref.invalidate(activeReferralCampaignProvider);
  return resp['id'] as String;
}

/// Update a campaign
Future<void> updateReferralCampaign(
  String id,
  Map<String, dynamic> data,
  WidgetRef ref,
) async {
  await _supabase.from('referral_campaigns').update(data).eq('id', id);
  ref.invalidate(referralCampaignsProvider);
  ref.invalidate(activeReferralCampaignProvider);
}

/// Delete a campaign
Future<void> deleteReferralCampaign(String id, WidgetRef ref) async {
  // 1. Delete associated referrals first
  await _supabase.from('referrals').delete().eq('campaign_id', id);
  // 2. Delete the campaign
  await _supabase.from('referral_campaigns').delete().eq('id', id);

  ref.invalidate(referralCampaignsProvider);
  ref.invalidate(activeReferralCampaignProvider);
}

/// Reject a referral (admin)
Future<void> rejectReferral(String referralId, WidgetRef ref) async {
  final referral = await _supabase
      .from('referrals')
      .select('campaign_id')
      .eq('id', referralId)
      .single();

  await _supabase
      .from('referrals')
      .update({'status': 'rejected'})
      .eq('id', referralId);

  ref.invalidate(campaignReferralsProvider(referral['campaign_id'] as String));
  ref.invalidate(campaignStatsProvider(referral['campaign_id'] as String));
  ref.invalidate(topReferrersProvider(referral['campaign_id'] as String));
}

/// Approve a pending referral manually (admin)
Future<void> approveReferral(String referralId, WidgetRef ref) async {
  final referral = await _supabase
      .from('referrals')
      .select('campaign_id')
      .eq('id', referralId)
      .single();

  await _supabase
      .from('referrals')
      .update({
        'status': 'confirmed',
        'confirmed_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', referralId);

  final campaignId = referral['campaign_id'] as String;

  // Process rewards
  final campaignResp = await _supabase
      .from('referral_campaigns')
      .select()
      .eq('id', campaignId)
      .single();
  final campaign = ReferralCampaign.fromJson(campaignResp);
  
  // Get the referrer_id for this specific referral to target reward processing
  final referralData = await _supabase.from('referrals').select('referrer_id').eq('id', referralId).single();
  final referrerId = referralData['referrer_id'] as String;

  await _processRewardsIfComplete(campaign, ref, referrerId: referrerId);

  ref.invalidate(campaignReferralsProvider(campaignId));
  ref.invalidate(campaignStatsProvider(campaignId));
  ref.invalidate(topReferrersProvider(campaignId));
}

// ══════════════════════════════════════════════════════
//  MEMBERSHIP REQUEST PROVIDERS & ACTIONS
// ══════════════════════════════════════════════════════

/// Current user's membership requests (history).
final myMembershipRequestsProvider = FutureProvider<List<MembershipRequest>>(
  (ref) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return [];

    final response = await _supabase
        .from('membership_requests')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    if ((response as List).isEmpty) return [];
    return response.map((j) => MembershipRequest.fromJson(j)).toList();
  },
);

/// All membership requests (admin view) - Real-time
final adminMembershipRequestsProvider =
    StreamProvider<List<MembershipRequest>>((ref) {
  return _supabase
      .from('membership_requests')
      .stream(primaryKey: ['id'])
      .asyncMap((_) async {
        final response = await _supabase
            .from('membership_requests')
            .select('*, profiles(full_name, username, email)')
            .order('created_at', ascending: false);

        return (response as List)
            .map((j) => MembershipRequest.fromJson(j))
            .toList();
      });
});

/// Pending membership requests count (for admin badge) - Real-time
final pendingMembershipCountProvider = StreamProvider<int>((ref) {
  return _supabase
      .from('membership_requests')
      .stream(primaryKey: ['id'])
      .map((list) => list.where((row) => row['status'] == 'pending').length);
});

/// Submit a membership request.
Future<String?> submitMembershipRequest({
  required WidgetRef ref,
  required String requestType,
  String? targetId,
  String? reason,
}) async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return 'Not logged in';

  try {
    await _supabase.from('membership_requests').insert({
      'user_id': uid,
      'request_type': requestType,
      'target_id': targetId,
      'reason': reason,
    });
    ref.invalidate(myMembershipRequestsProvider);
    ref.invalidate(adminMembershipRequestsProvider);
    ref.invalidate(pendingMembershipCountProvider);
    return null; // success
  } catch (e) {
    return 'error';
  }
}

/// Approve a membership request (admin).
Future<void> approveMembershipRequest(String requestId, WidgetRef ref) async {
  final adminId = _supabase.auth.currentUser?.id;
  await _supabase.from('membership_requests').update({
    'status': 'approved',
    'reviewed_by': adminId,
    'reviewed_at': DateTime.now().toUtc().toIso8601String(),
  }).eq('id', requestId);

  ref.invalidate(adminMembershipRequestsProvider);
  ref.invalidate(pendingMembershipCountProvider);

  // Send notification to the user
  try {
    final req = await _supabase
        .from('membership_requests')
        .select('user_id')
        .eq('id', requestId)
        .single();
    final userId = req['user_id'] as String;

    await sendNotification(
      userId: userId,
      title: '🎉 تم قبول طلب العضوية',
      body: 'تهانينا! تم قبول طلبك للحصول على العضوية المميزة. يمكنك الآن الاستمتاع بكافة المزايا.',
      type: 'membership_approved',
    );
  } catch (e) {
    debugPrint('Error sending approval notification: $e');
  }
}

/// Send a targeted notification to a user (In-app + Push)
Future<void> sendNotification({
  required String userId,
  required String title,
  required String body,
  String type = 'general',
  String? targetUrl,
}) async {
  try {
    // 1. Insert into DB for in-app history
    // NOTE: Do NOT pass 'created_at' — let Supabase use server-side now()
    // to avoid timezone mismatch (client DateTime.now() is local, not UTC).
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'target_url': targetUrl,
    });

    // 2. Trigger Edge Function for Push Notification
    try {
      await _supabase.functions.invoke(
        'send-notification',
        body: {
          'title': title,
          'body': body,
          'type': type,
          'target_url': targetUrl,
          'target_user_id': userId,
          'mode': 'direct_to_user', // Mode for targeted push
        },
      );
    } catch (e) {
      debugPrint('Error triggering push notification: $e');
    }
  } catch (e) {
    debugPrint('Error inserting notification: $e');
  }
}

/// Reject a membership request (admin).
Future<void> rejectMembershipRequest(String requestId, WidgetRef ref) async {
  final adminId = _supabase.auth.currentUser?.id;
  await _supabase.from('membership_requests').update({
    'status': 'rejected',
    'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    'reviewed_by': adminId,
  }).eq('id', requestId);

  ref.invalidate(adminMembershipRequestsProvider);
  ref.invalidate(pendingMembershipCountProvider);
}

/// Delete a membership request (admin).
Future<void> deleteMembershipRequest(String requestId, WidgetRef ref) async {
  await _supabase.from('membership_requests').delete().eq('id', requestId);

  ref.invalidate(adminMembershipRequestsProvider);
  ref.invalidate(pendingMembershipCountProvider);
}

/// Update a global app setting (admin).
Future<void> updateAppSetting(
  String key,
  String value,
  WidgetRef ref,
) async {
  await _supabase
      .from('app_settings')
      .upsert({'key': key, 'value': value, 'updated_at': DateTime.now().toUtc().toIso8601String()});
  ref.invalidate(appSettingsProvider);
  ref.invalidate(defaultRequiredInvitesProvider);
  ref.invalidate(membershipRequestsEnabledProvider);
}

/// Toggle persona premium status (admin).
Future<void> togglePersonaPremium(
  String personaId,
  bool isPremium,
  WidgetRef ref,
) async {
  await _supabase
      .from('ai_personas')
      .update({'is_premium': isPremium})
      .eq('id', personaId);
  
  // Invalidate the main personas provider so users see the change immediately
  ref.invalidate(expertPersonasProvider);
}

// ══════════════════════════════════════════════════════
//  ALL REFERRALS ACROSS ALL CAMPAIGNS (Admin — for
//  the new membership management tab)
// ══════════════════════════════════════════════════════

/// All referrals across all campaigns (admin view for membership management).
/// All referrals for all users (admin view) - Real-time
final allReferralsProvider = StreamProvider<List<Referral>>((ref) {
  return _supabase
      .from('referrals')
      .stream(primaryKey: ['id'])
      .asyncMap((_) async {
        final response = await _supabase.from('referrals').select(
              '*, referred:referred_id(full_name, username), referrer:referrer_id(full_name, username)',
            ).order('created_at', ascending: false);

        return (response as List).map((j) => Referral.fromJson(j)).toList();
      });
});

/// Instant-confirm a pending referral (admin shortcut).
Future<void> instantConfirmReferral(String referralId, WidgetRef ref) async {
  await _supabase.from('referrals').update({
    'status': 'confirmed',
    'confirmed_at': DateTime.now().toUtc().toIso8601String(),
    'verified_at': DateTime.now().toUtc().toIso8601String(),
  }).eq('id', referralId);

  ref.invalidate(allReferralsProvider);
  ref.invalidate(myTotalConfirmedReferralsProvider);
}

/// Short, viral invitation message for quick sharing (e.g. from Premium Sheets).
Future<void> shareViralInvitation(WidgetRef ref) async {
  try {
    final codeObj = await ensureReferralCode(ref);
    final code = codeObj.code;
    final campaign = await ref.read(activeReferralCampaignProvider.future);
    final rewardMention = campaign?.referredRewardDescription ?? '';
    const appLink = 'https://zaadtech.netlify.app';
    
    final message = '''
🚀 انضم إليّ في 'زاد'.. عقلك الثاني لتنظيم حياتك الرقمية! 🧠

لقد بدأت باستخدام تطبيق 'زاد' لتنظيم كل روابطي، مفاتيحي، وأدواتي التقنية في مكان واحد، وأردت مشاركة الفائدة معك!

ماذا ستحصل عليه في زاد؟
🔖 تنظيم ذكي للمواقع والأدوات.
🤖 مساعد AI متقدم لشرح وتلخيص المحتوى.
🧠 خبير زاد: استشارات تقنية فورية من خبراء ذكاء اصطناعي.
⚡ تصفح ذكي وأتمتة للحافظة (Clipboard) توفر وقتك.
🧭 استكشاف أفضل المصادر التقنية المحدثة.

${rewardMention.isNotEmpty ? '🎁 مكافأة خاصة بانتظارك: $rewardMention' : ''}

✨ استخدم كود الدعوة الخاص بي عند التسجيل للحصول على الامتيازات:
📌 $code

⬇️ حمّل التطبيق الآن وابدأ رحلة التنظيم:
$appLink

زاد.. حيث تبدأ إنتاجيتك الرقمية الحقيقية! 🚀''';

    await Clipboard.setData(ClipboardData(text: message));
    await Share.share(message);
  } catch (e) {
    debugPrint('Error sharing viral invitation: $e');
  }
}

/// Long, detailed invitation message for the Profile screen.
/// Combines the full marketing pitch with the referral code.
Future<void> shareDetailedInvitation(WidgetRef ref) async {
  try {
    final codeObj = await ensureReferralCode(ref);
    final code = codeObj.code;
    final campaign = await ref.read(activeReferralCampaignProvider.future);
    final rewardMention = campaign?.referredRewardDescription ?? '';
    const appLink = 'https://zaadtech.netlify.app';

    final message = '''
لو كنت طالب، تقني، مصمم، مبرمج، مختص أمن سيبراني أو مهندس ذكاء اصطناعي.. فأكيد تعرف "دوامة" تشتت المصادر والروابط والأدوات! 🤯

تطبيق "زاد" صُمم ليكون "عقلك الثاني".. المكان الذكي الذي ينظم اهتماماتك الرقمية في مكان واحد 👌

🔖 احفظ أي موقع أو أداة مفيدة بنقرة.
🔐 خزّن مفاتيحك (API، أكواد، حسابات…) بأمان.
🤖 مساعد ذكي (AI) لشرح وتلخيص أي أداة أو موقع.
🧠 خبير زاد: مستشارك التقني الخاص من خبراء الذكاء الاصطناعي.
🌐 متصفح زاد الذكي: تصفح واجعل الـ AI يلخص لك المحتوى بلمحة بصر.
⚡ النسخ المتقدم وأتمتة الحافظة (Clipboard) لتوفير وقتك.
🧭 استكشف أفضل الأدوات والكورسات والمصادر التقنية المحدثة.
💬 مجتمع تقني حي لتبادل الخبرات.

${rewardMention.isNotEmpty ? '🎁 مكافأة خاصة بانتظارك عبر رابطي: $rewardMention' : ''}

✨ استخدم كود الدعوة الخاص بي عند التسجيل للحصول على الامتيازات:
📌 $code

⬇️ حمّل التطبيق الآن وابدأ رحلة التنظيم:
$appLink

زاد.. حيث تبدأ إنتاجيتك الرقمية الحقيقية! 🚀''';

    await Clipboard.setData(ClipboardData(text: message));
    await Share.share(message);
  } catch (e) {
    debugPrint('Error sharing detailed invitation: $e');
  }
}
