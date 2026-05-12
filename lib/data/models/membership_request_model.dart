import 'package:flutter/foundation.dart';

/// Model for a user's premium membership request.
@immutable
class MembershipRequest {
  final String id;
  final String userId;
  final String requestType; // 'premium_content' | 'premium_persona'
  final String? targetId;
  final String? reason;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  // Joined profile fields (from admin queries)
  final String? userName;
  final String? userUsername;
  final String? userEmail;
  final int? userReferralCount;

  const MembershipRequest({
    required this.id,
    required this.userId,
    this.requestType = 'premium_content',
    this.targetId,
    this.reason,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.userName,
    this.userUsername,
    this.userEmail,
    this.userReferralCount,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory MembershipRequest.fromJson(Map<String, dynamic> json) {
    // Parse joined profile data
    String? name, username, email;
    if (json['profiles'] is Map) {
      name = json['profiles']['full_name'] as String?;
      username = json['profiles']['username'] as String?;
      email = json['profiles']['email'] as String?;
    }

    return MembershipRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      requestType: json['request_type'] as String? ?? 'premium_content',
      targetId: json['target_id'] as String?,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'pending',
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at']).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      userName: name,
      userUsername: username,
      userEmail: email,
      userReferralCount: json['referral_count'] as int?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'request_type': requestType,
        'target_id': targetId,
        'reason': reason,
      };
}
