import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';
import 'auth_providers.dart';

/// The scope of a membership grant
enum MembershipScope {
  global,     // All features
  collection, // Specific collections
  persona,    // Specific personas
}

/// A centralized provider to track and calculate membership status
final membershipStatusProvider = Provider<MembershipStatus>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  
  return profileAsync.maybeWhen(
    data: (profile) {
      if (profile == null) return MembershipStatus.none();
      
      final role = profile['role'] as String? ?? 'user';
      final isAdmin = role == 'admin';
      
      final premiumUntilStr = profile['premium_until'] as String?;
      final premiumUntil = premiumUntilStr != null ? DateTime.parse(premiumUntilStr) : null;
      final permissions = List<String>.from(profile['permissions'] ?? []);
      
      return MembershipStatus(
        premiumUntil: premiumUntil,
        permissions: permissions,
        isAdmin: isAdmin,
      );
    },
    orElse: () => MembershipStatus.none(),
  );
});

class MembershipStatus {
  final DateTime? premiumUntil;
  final List<String> permissions;
  final bool isAdmin;

  MembershipStatus({
    this.premiumUntil,
    required this.permissions,
    required this.isAdmin,
  });

  factory MembershipStatus.none() => MembershipStatus(
    premiumUntil: null,
    permissions: [],
    isAdmin: false,
  );

  /// Returns true if the user has active premium status (global or specific)
  bool get isActive {
    if (isAdmin) return true;
    if (premiumUntil == null) return false;
    return premiumUntil!.isAfter(DateTime.now());
  }

  /// Returns true if the user has global premium access
  bool get isGlobal {
    if (isAdmin) return true;
    if (!isActive) return false;
    return permissions.contains('premium:all');
  }

  /// Returns remaining time as a human-readable string (e.g. "2 days remaining")
  String? get remainingTimeText {
    if (isAdmin) return 'وصول أدمن دائم';
    if (!isActive) return null;
    if (premiumUntil!.year > 2099) return 'عضوية دائمة';
    
    final diff = premiumUntil!.difference(DateTime.now());
    if (diff.inDays > 0) return 'ينتهي خلال ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'ينتهي خلال ${diff.inHours} ساعة';
    return 'ينتهي قريباً';
  }

  /// Check access to a specific item
  bool hasAccessTo({required String type, String? id}) {
    if (isAdmin) return true;
    if (!isActive) return false;
    if (isGlobal) return true;
    
    if (id == null) return false;
    
    if (type == 'collection') {
      return permissions.contains('premium:col_$id');
    }
    if (type == 'persona') {
      // Robust check: matches either the ID (UUID) or the Slug for maximum compatibility
      // with how admins might grant access or how items are referenced.
      return permissions.contains('premium:per_$id');
    }
    
    return false;
  }
}

/// Provider for managing (granting/revoking) memberships
final membershipManagementProvider = Provider((ref) => MembershipManagement());

class MembershipManagement {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Grant membership to a user
  Future<void> grantMembership({
    required String userId,
    required Duration duration,
    required MembershipScope scope,
    List<String>? targetIds, // IDs of collections or personas if scope is not global
  }) async {
    // Calculate new expiration date
    // If user already has premium, we EXTEND it if it's not expired
    final currentProfile = await _client.from('profiles').select('premium_until, permissions').eq('id', userId).single();
    final currentPremiumUntilStr = currentProfile['premium_until'] as String?;
    final currentPremiumUntil = currentPremiumUntilStr != null ? DateTime.parse(currentPremiumUntilStr) : null;
    
    DateTime newUntil;
    if (duration.inDays > 3650) { // Practical "Permanent"
      newUntil = DateTime(2100, 1, 1);
    } else {
      final baseDate = (currentPremiumUntil != null && currentPremiumUntil.isAfter(DateTime.now())) 
          ? currentPremiumUntil 
          : DateTime.now();
      newUntil = baseDate.add(duration);
    }

    final currentPermissions = List<String>.from(currentProfile['permissions'] ?? []);
    final Set<String> newPermissions = currentPermissions.toSet();

    if (scope == MembershipScope.global) {
      newPermissions.add('premium:all');
    } else if (targetIds != null) {
      final prefix = scope == MembershipScope.collection ? 'premium:col_' : 'premium:per_';
      for (final id in targetIds) {
        newPermissions.add('$prefix$id');
      }
    }

    await _client.from('profiles').update({
      'premium_until': newUntil.toIso8601String(),
      'permissions': newPermissions.toList(),
      'last_premium_upgrade_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    // Send Notification
    await sendMembershipNotification(
      userId: userId,
      title: 'تهانينا! 🎉 تم تفعيل العضوية',
      body: scope == MembershipScope.global 
          ? 'تم تفعيل عضويتك المميزة بنجاح! استمتع بكافة الميزات الآن.'
          : 'تم منحك وصولاً خاصاً لبعض المحتويات المميزة.',
    );
  }

  /// Manually update or reset a user's membership
  Future<void> updateMembership({
    required String userId,
    required DateTime? premiumUntil,
    List<String>? permissions,
  }) async {
    final Map<String, dynamic> data = {
      'premium_until': premiumUntil?.toIso8601String(),
      'last_premium_upgrade_at': DateTime.now().toIso8601String(),
    };
    
    if (permissions != null) {
      data['permissions'] = permissions;
    }

    await _client.from('profiles').update(data).eq('id', userId);

    // Synchronize with membership_requests table for UI consistency
    if (premiumUntil == null) {
      // If membership is revoked/canceled, mark any previously approved requests as rejected
      await _client
          .from('membership_requests')
          .update({'status': 'rejected'})
          .eq('user_id', userId)
          .eq('status', 'approved');
    }

    // Send Notification based on action
    if (premiumUntil == null) {
      await sendMembershipNotification(
        userId: userId,
        title: 'تحديث العضوية ⚠️',
        body: 'نعتذر، لقد تم إلغاء عضويتك المميزة حالياً.',
      );
    } else {
      final isPermanent = premiumUntil.year > 2099;
      await sendMembershipNotification(
        userId: userId,
        title: 'تحديث في حالة العضوية 🔄',
        body: isPermanent 
            ? 'تمت ترقية عضويتك لتصبح دائمة! استمتع بالوصول اللامحدود.'
            : 'تم تحديث مدة عضويتك. تنتهي الآن بتاريخ ${premiumUntil.year}/${premiumUntil.month}/${premiumUntil.day}.',
      );
    }
  }

  /// Helper to insert a notification into the database
  Future<void> sendMembershipNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      // 1. Insert into DB for in-app history
      final inserted = await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': 'membership',
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final notificationId = inserted['id'];

      // 4. Trigger Edge Function for Push Notification (FCM)
      await _client.functions.invoke(
        'send-notification',
        body: {
          'title': title,
          'body': body,
          'user_id': userId,
          'notification_id': notificationId,
          'type': 'membership',
        },
      );
    } catch (e) {
      // We don't want to fail the main transaction if notification fails
      print('Notification/Push failed: $e');
    }
  }
}

/// Provider to list all users with active premium status (Real-time)
final activePremiumUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final supabase = SupabaseConfig.client;
  
  // Use Supabase stream on 'profiles' to detect ANY change
  return supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .asyncMap((_) async {
        // When any profile changes, re-fetch the specific premium list with full details
        final response = await supabase
            .from('profiles')
            .select('id, full_name, username, email, premium_until, permissions')
            .not('premium_until', 'is', null)
            .order('premium_until', ascending: false);
        
        return List<Map<String, dynamic>>.from(response);
      });
});
