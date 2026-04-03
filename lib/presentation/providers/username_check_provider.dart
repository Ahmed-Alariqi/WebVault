import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';

/// Checks if a username is available in the profiles table.
/// Returns `true` if the username is available, `false` if taken.
/// [param] is a record of (username, currentUserId) to exclude self.
final usernameAvailableProvider =
    FutureProvider.family<bool, ({String username, String? currentUserId})>((
      ref,
      param,
    ) async {
      final query = SupabaseConfig.client
          .from('profiles')
          .select('id')
          .eq('username', param.username);

      // Exclude the current user's own username during profile edits
      final results = param.currentUserId != null
          ? await query.neq('id', param.currentUserId!)
          : await query;

      return (results as List).isEmpty;
    });
