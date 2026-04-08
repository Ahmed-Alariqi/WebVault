import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../data/models/referral_model.dart';

final _supabase = SupabaseConfig.client;

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

  // Generate random suffix: 5 chars alphanumeric
  final rand = Random.secure();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final suffix = List.generate(
    5,
    (_) => chars[rand.nextInt(chars.length)],
  ).join();
  final code = '$username-$suffix';

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
final isEligibleForCollectionProvider = FutureProvider.family<bool, String>((
  ref,
  collectionId,
) async {
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return false;

  // Find campaigns that give access to this collection
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
      .eq('code', code.trim())
      .limit(1);
  if ((codeResp as List).isEmpty) {
    return 'invalid_code';
  }
  final referralCode = ReferralCode.fromJson(codeResp.first);

  // 3. Self-referral check
  if (referralCode.userId == uid) {
    return 'self_referral';
  }

  // 4. Find active campaign
  final campaign = await ref.read(activeReferralCampaignProvider.future);
  if (campaign == null) {
    return 'no_active_campaign';
  }

  // 5. Insert the referral as PENDING (no auto-confirm)
  try {
    await _supabase.from('referrals').insert({
      'campaign_id': campaign.id,
      'referrer_id': referralCode.userId,
      'referred_id': uid,
      'status': 'pending',
    });

    // 6. Update profile.referred_by
    await _supabase
        .from('profiles')
        .update({'referred_by': referralCode.userId})
        .eq('id', uid);

    ref.invalidate(hasBeenReferredProvider);
    ref.invalidate(myReferralsProvider);
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
        .select('id, campaign_id, created_at')
        .eq('referred_id', uid)
        .eq('status', 'pending')
        .limit(1);

    if ((pending as List).isEmpty) return;

    final referralId = pending.first['id'] as String;
    final campaignId = pending.first['campaign_id'] as String;
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

    await _processRewardsIfComplete(campaign, ref);
    ref.invalidate(myReferralsProvider);

    debugPrint('Referral $referralId confirmed via activity verification');
  } catch (e) {
    debugPrint('checkReferralActivityAndConfirm error: $e');
  }
}

/// Check if referrer has reached the target and process rewards
Future<void> _processRewardsIfComplete(
  ReferralCampaign campaign,
  WidgetRef ref,
) async {
  // This gets called after a referral is confirmed
  // We need to find the referrer from the most recently confirmed referral
  // Actually, we should check all referrers for this campaign

  // Get all referrers who might have just reached the target
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
      await _grantReward(entry.key, campaign);
    }
  }
}

/// Grant reward to a referrer
Future<void> _grantReward(String referrerId, ReferralCampaign campaign) async {
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
  await _processRewardsIfComplete(campaign, ref);

  ref.invalidate(campaignReferralsProvider(campaignId));
  ref.invalidate(campaignStatsProvider(campaignId));
  ref.invalidate(topReferrersProvider(campaignId));
}
