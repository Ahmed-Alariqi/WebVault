import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════
//  REFERRAL CAMPAIGN — Admin-managed campaign
// ══════════════════════════════════════════════════════

@immutable
class ReferralCampaign {
  final String id;
  final String title;
  final String? description;
  final bool isActive;
  final bool isVisible;
  final int requiredReferrals;
  // Referrer rewards
  final String
  rewardType; // none / giveaway_entry / giveaway_boost / collection_access / custom
  final String? rewardGiveawayId;
  final String? rewardCollectionId;
  final String? rewardDescription;
  // Referred user rewards
  final String referredRewardType; // none / giveaway_entry
  final String? referredRewardDescription;
  // Timing
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? createdBy;
  final DateTime createdAt;

  const ReferralCampaign({
    required this.id,
    required this.title,
    this.description,
    this.isActive = false,
    this.isVisible = false,
    this.requiredReferrals = 3,
    this.rewardType = 'none',
    this.rewardGiveawayId,
    this.rewardCollectionId,
    this.rewardDescription,
    this.referredRewardType = 'none',
    this.referredRewardDescription,
    this.startsAt,
    this.endsAt,
    this.createdBy,
    required this.createdAt,
  });

  bool get isRunning {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  bool get isExpired => endsAt != null && DateTime.now().isAfter(endsAt!);

  factory ReferralCampaign.fromJson(Map<String, dynamic> json) {
    return ReferralCampaign(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      isVisible: json['is_visible'] as bool? ?? false,
      requiredReferrals: json['required_referrals'] as int? ?? 3,
      rewardType: json['reward_type'] as String? ?? 'none',
      rewardGiveawayId: json['reward_giveaway_id'] as String?,
      rewardCollectionId: json['reward_collection_id'] as String?,
      rewardDescription: json['reward_description'] as String?,
      referredRewardType: json['referred_reward_type'] as String? ?? 'none',
      referredRewardDescription: json['referred_reward_description'] as String?,
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at']).toLocal()
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at']).toLocal()
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'is_active': isActive,
      'is_visible': isVisible,
      'required_referrals': requiredReferrals,
      'reward_type': rewardType,
      'reward_giveaway_id': rewardGiveawayId,
      'reward_collection_id': rewardCollectionId,
      'reward_description': rewardDescription,
      'referred_reward_type': referredRewardType,
      'referred_reward_description': referredRewardDescription,
      'starts_at': startsAt?.toUtc().toIso8601String(),
      'ends_at': endsAt?.toUtc().toIso8601String(),
    };
  }

  ReferralCampaign copyWith({
    String? title,
    String? description,
    bool? isActive,
    bool? isVisible,
    int? requiredReferrals,
    String? rewardType,
    String? rewardGiveawayId,
    String? rewardCollectionId,
    String? rewardDescription,
    String? referredRewardType,
    String? referredRewardDescription,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    return ReferralCampaign(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isVisible: isVisible ?? this.isVisible,
      requiredReferrals: requiredReferrals ?? this.requiredReferrals,
      rewardType: rewardType ?? this.rewardType,
      rewardGiveawayId: rewardGiveawayId ?? this.rewardGiveawayId,
      rewardCollectionId: rewardCollectionId ?? this.rewardCollectionId,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      referredRewardType: referredRewardType ?? this.referredRewardType,
      referredRewardDescription:
          referredRewardDescription ?? this.referredRewardDescription,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}

// ══════════════════════════════════════════════════════
//  REFERRAL CODE — One per user
// ══════════════════════════════════════════════════════

@immutable
class ReferralCode {
  final String id;
  final String userId;
  final String code;
  final DateTime createdAt;

  const ReferralCode({
    required this.id,
    required this.userId,
    required this.code,
    required this.createdAt,
  });

  factory ReferralCode.fromJson(Map<String, dynamic> json) {
    return ReferralCode(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}

// ══════════════════════════════════════════════════════
//  REFERRAL — Individual referral record
// ══════════════════════════════════════════════════════

@immutable
class Referral {
  final String id;
  final String campaignId;
  final String referrerId;
  final String referredId;
  final String status; // pending / confirmed / rejected / expired
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? verifiedAt;
  // Joined fields
  final String? referredName;
  final String? referredUsername;
  final String? referrerName;
  final String? referrerUsername;

  const Referral({
    required this.id,
    required this.campaignId,
    required this.referrerId,
    required this.referredId,
    this.status = 'pending',
    required this.createdAt,
    this.confirmedAt,
    this.verifiedAt,
    this.referredName,
    this.referredUsername,
    this.referrerName,
    this.referrerUsername,
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';
  bool get isExpired => status == 'expired';

  factory Referral.fromJson(Map<String, dynamic> json) {
    // Parse joined profile data
    String? refName, refUsername, rerName, rerUsername;
    if (json['referred'] is Map) {
      refName = json['referred']['full_name'] as String?;
      refUsername = json['referred']['username'] as String?;
    }
    if (json['referrer'] is Map) {
      rerName = json['referrer']['full_name'] as String?;
      rerUsername = json['referrer']['username'] as String?;
    }

    return Referral(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String,
      referrerId: json['referrer_id'] as String,
      referredId: json['referred_id'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at']).toLocal()
          : null,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at']).toLocal()
          : null,
      referredName: refName,
      referredUsername: refUsername,
      referrerName: rerName,
      referrerUsername: rerUsername,
    );
  }
}
