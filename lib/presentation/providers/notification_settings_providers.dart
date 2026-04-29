import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import 'auth_providers.dart';

/// Streams the current user's notification preferences from `profiles`.
///
/// Only one preference is user-mutable: `notif_all_new_content` (default
/// `false`). Critical pushes (support chat, admin broadcasts) are always on
/// — they're gated only by the OS-level notification switch.
final notificationPrefsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return {'notif_all_new_content': false};
  }

  final response = await SupabaseConfig.client
      .from('profiles')
      .select('notif_all_new_content')
      .eq('id', user.id)
      .maybeSingle();

  return {
    'notif_all_new_content':
        response?['notif_all_new_content'] as bool? ?? false,
  };
});
