import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../data/models/giveaway_model.dart';
import '../../data/models/poll_model.dart';

final _supabase = SupabaseConfig.client;

//  HIDDEN EVENTS (SESSION STATE)
// ──────────────────────────────────────────

/// Stores IDs of events (giveaways or polls) the user has dismissed in this session.
final hiddenEventsProvider = StateProvider<Set<String>>((ref) => {});

// ──────────────────────────────────────────
//  GIVEAWAY PROVIDERS
// ──────────────────────────────────────────

/// All giveaways ordered by created_at desc
final giveawaysProvider = FutureProvider<List<Giveaway>>((ref) async {
  final uid = _supabase.auth.currentUser?.id;
  final response = await _supabase
      .from('giveaways')
      .select()
      .order('created_at', ascending: false);

  final giveaways = <Giveaway>[];
  for (final json in response as List) {
    final gId = json['id'] as String;
    // Get entry count
    final countResp = await _supabase
        .from('giveaway_entries')
        .select('id')
        .eq('giveaway_id', gId);
    final count = (countResp as List).length;

    // Check if current user has entered
    bool entered = false;
    if (uid != null) {
      final check = await _supabase
          .from('giveaway_entries')
          .select('id')
          .eq('giveaway_id', gId)
          .eq('user_id', uid);
      entered = (check as List).isNotEmpty;
    }

    giveaways.add(
      Giveaway.fromJson(json, entryCount: count, hasEntered: entered),
    );
  }
  return giveaways;
});

/// Active giveaway for Discover banner (first active one)
final activeGiveawayProvider = FutureProvider<Giveaway?>((ref) async {
  final uid = _supabase.auth.currentUser?.id;
  final response = await _supabase
      .from('giveaways')
      .select()
      .order('created_at', ascending: false)
      .limit(5);

  if ((response as List).isEmpty) return null;

  for (final json in response) {
    final tempG = Giveaway.fromJson(json);
    if (!tempG.shouldDisplay) continue;

    final gId = json['id'] as String;

    final countResp = await _supabase
        .from('giveaway_entries')
        .select('id')
        .eq('giveaway_id', gId);
    final count = (countResp as List).length;

    bool entered = false;
    if (uid != null) {
      final check = await _supabase
          .from('giveaway_entries')
          .select('id')
          .eq('giveaway_id', gId)
          .eq('user_id', uid);
      entered = (check as List).isNotEmpty;
    }

    final g = Giveaway.fromJson(json, entryCount: count, hasEntered: entered);
    if (g.shouldDisplay) return g;
  }

  return null;
});

/// Single giveaway by ID
final giveawayByIdProvider = FutureProvider.family<Giveaway?, String>((
  ref,
  id,
) async {
  final uid = _supabase.auth.currentUser?.id;
  try {
    final json = await _supabase
        .from('giveaways')
        .select()
        .eq('id', id)
        .single();
    final countResp = await _supabase
        .from('giveaway_entries')
        .select('id')
        .eq('giveaway_id', id);
    final count = (countResp as List).length;

    bool entered = false;
    if (uid != null) {
      final check = await _supabase
          .from('giveaway_entries')
          .select('id')
          .eq('giveaway_id', id)
          .eq('user_id', uid);
      entered = (check as List).isNotEmpty;
    }
    return Giveaway.fromJson(json, entryCount: count, hasEntered: entered);
  } catch (_) {
    return null;
  }
});

/// Entries for a specific giveaway (with user names + emails)
final giveawayEntriesProvider =
    FutureProvider.family<List<GiveawayEntry>, String>((ref, giveawayId) async {
      final response = await _supabase
          .from('giveaway_entries')
          .select('*, profiles(full_name, email)')
          .eq('giveaway_id', giveawayId)
          .order('entered_at', ascending: false);
      return (response as List).map((j) => GiveawayEntry.fromJson(j)).toList();
    });

/// Enter a giveaway (with optional entry value)
Future<void> enterGiveaway(
  String giveawayId,
  WidgetRef ref, {
  String? entryValue,
}) async {
  final uid = _supabase.auth.currentUser!.id;
  final data = <String, dynamic>{'giveaway_id': giveawayId, 'user_id': uid};
  if (entryValue != null && entryValue.isNotEmpty) {
    data['entry_value'] = entryValue;
  }
  await _supabase.from('giveaway_entries').insert(data);
  ref.invalidate(giveawaysProvider);
  ref.invalidate(activeGiveawayProvider);
  ref.invalidate(giveawayByIdProvider(giveawayId));
  ref.invalidate(giveawayEntriesProvider(giveawayId));
}

/// Draw N winners randomly
Future<List<String>> drawGiveawayWinner(
  String giveawayId,
  WidgetRef ref, {
  int winnerCount = 1,
}) async {
  final entries = await _supabase
      .from('giveaway_entries')
      .select('user_id')
      .eq('giveaway_id', giveawayId);

  if ((entries as List).isEmpty) return [];

  // Shuffle and pick up to winnerCount unique winners
  final userIds = entries.map((e) => e['user_id'] as String).toSet().toList();
  userIds.shuffle(Random.secure());
  final winners = userIds.take(winnerCount).toList();

  await _supabase
      .from('giveaways')
      .update({
        'status': 'drawn',
        'winner_id': winners.first, // legacy compat
        'winner_ids': winners,
        'winner_announced_at': DateTime.now().toIso8601String(),
      })
      .eq('id', giveawayId);

  ref.invalidate(giveawaysProvider);
  ref.invalidate(activeGiveawayProvider);
  ref.invalidate(giveawayByIdProvider(giveawayId));
  return winners;
}

/// Redraw giveaway — clear winners and draw new ones
Future<List<String>> redrawGiveaway(
  String giveawayId,
  WidgetRef ref, {
  int winnerCount = 1,
}) async {
  // Reset status to active temporarily
  await _supabase
      .from('giveaways')
      .update({
        'status': 'active',
        'winner_id': null,
        'winner_ids': <String>[],
        'winner_announced_at': null,
      })
      .eq('id', giveawayId);

  // Draw fresh winners
  return drawGiveawayWinner(giveawayId, ref, winnerCount: winnerCount);
}

/// Create giveaway — returns the new giveaway ID
Future<String> createGiveaway(Map<String, dynamic> data, WidgetRef ref) async {
  data['created_by'] = _supabase.auth.currentUser!.id;
  final resp = await _supabase
      .from('giveaways')
      .insert(data)
      .select('id')
      .single();
  ref.invalidate(giveawaysProvider);
  ref.invalidate(activeGiveawayProvider);
  return resp['id'] as String;
}

/// Update giveaway
Future<void> updateGiveaway(
  String id,
  Map<String, dynamic> data,
  WidgetRef ref,
) async {
  await _supabase.from('giveaways').update(data).eq('id', id);
  ref.invalidate(giveawaysProvider);
  ref.invalidate(activeGiveawayProvider);
  ref.invalidate(giveawayByIdProvider(id));
}

/// Delete giveaway
Future<void> deleteGiveaway(String id, WidgetRef ref) async {
  await _supabase.from('giveaways').delete().eq('id', id);
  ref.invalidate(giveawaysProvider);
  ref.invalidate(activeGiveawayProvider);
}

// ──────────────────────────────────────────
//  POLL PROVIDERS
// ──────────────────────────────────────────

/// All polls ordered by created_at desc
final pollsProvider = FutureProvider<List<Poll>>((ref) async {
  final uid = _supabase.auth.currentUser?.id;
  final response = await _supabase
      .from('polls')
      .select()
      .order('created_at', ascending: false);

  final polls = <Poll>[];
  for (final json in response as List) {
    final pId = json['id'] as String;
    polls.add(await _enrichPoll(json, pId, uid));
  }
  return polls;
});

/// Active poll for Discover card (first active one)
final activePollProvider = FutureProvider<Poll?>((ref) async {
  final uid = _supabase.auth.currentUser?.id;
  final response = await _supabase
      .from('polls')
      .select()
      .order('created_at', ascending: false)
      .limit(5);

  if ((response as List).isEmpty) return null;

  for (final json in response) {
    final tempP = Poll.fromJson(json);
    if (!tempP.shouldDisplay) continue;

    final pId = json['id'] as String;
    final poll = await _enrichPoll(json, pId, uid);
    if (poll.shouldDisplay) return poll;
  }

  return null;
});

/// Single poll by ID
final pollByIdProvider = FutureProvider.family<Poll?, String>((ref, id) async {
  final uid = _supabase.auth.currentUser?.id;
  try {
    final json = await _supabase.from('polls').select().eq('id', id).single();
    return await _enrichPoll(json, id, uid);
  } catch (_) {
    return null;
  }
});

/// Helper: enrich a poll with vote counts and user votes
Future<Poll> _enrichPoll(
  Map<String, dynamic> json,
  String pollId,
  String? uid,
) async {
  final allVotes = await _supabase
      .from('poll_votes')
      .select('selected_option, user_id')
      .eq('poll_id', pollId);

  final Map<int, int> counts = {};
  int total = 0;
  final Set<int> userSelected = {};

  for (final v in allVotes as List) {
    final opt = v['selected_option'] as int;
    counts[opt] = (counts[opt] ?? 0) + 1;
    total++;
    if (uid != null && v['user_id'] == uid) {
      userSelected.add(opt);
    }
  }

  return Poll.fromJson(
    json,
    voteCounts: counts,
    totalVotes: total,
    userVotes: userSelected,
  );
}

/// Vote on a poll
Future<void> votePoll(String pollId, int optionIndex, WidgetRef ref) async {
  final uid = _supabase.auth.currentUser!.id;
  await _supabase.from('poll_votes').insert({
    'poll_id': pollId,
    'user_id': uid,
    'selected_option': optionIndex,
  });
  ref.invalidate(pollsProvider);
  ref.invalidate(activePollProvider);
  ref.invalidate(pollByIdProvider(pollId));
}

/// Remove vote from a poll
Future<void> unvotePoll(String pollId, int optionIndex, WidgetRef ref) async {
  final uid = _supabase.auth.currentUser!.id;
  await _supabase
      .from('poll_votes')
      .delete()
      .eq('poll_id', pollId)
      .eq('user_id', uid)
      .eq('selected_option', optionIndex);
  ref.invalidate(pollsProvider);
  ref.invalidate(activePollProvider);
  ref.invalidate(pollByIdProvider(pollId));
}

/// Create poll — returns the new poll ID
Future<String> createPoll(Map<String, dynamic> data, WidgetRef ref) async {
  data['created_by'] = _supabase.auth.currentUser!.id;
  final resp = await _supabase.from('polls').insert(data).select('id').single();
  ref.invalidate(pollsProvider);
  ref.invalidate(activePollProvider);
  return resp['id'] as String;
}

/// Update poll
Future<void> updatePoll(
  String id,
  Map<String, dynamic> data,
  WidgetRef ref,
) async {
  await _supabase.from('polls').update(data).eq('id', id);
  ref.invalidate(pollsProvider);
  ref.invalidate(activePollProvider);
  ref.invalidate(pollByIdProvider(id));
}

/// Delete poll
Future<void> deletePoll(String id, WidgetRef ref) async {
  await _supabase.from('polls').delete().eq('id', id);
  ref.invalidate(pollsProvider);
  ref.invalidate(activePollProvider);
}

/// End a poll manually
Future<void> endPoll(String id, WidgetRef ref) async {
  await _supabase.from('polls').update({'status': 'ended'}).eq('id', id);
  ref.invalidate(pollsProvider);
  ref.invalidate(activePollProvider);
  ref.invalidate(pollByIdProvider(id));
}

/// Winner profile info provider (name + email)
final winnerNameProvider = FutureProvider.family<String, String>((
  ref,
  userId,
) async {
  try {
    final resp = await _supabase
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .single();
    return resp['full_name'] as String? ?? 'Unknown';
  } catch (_) {
    return 'Unknown';
  }
});

/// Winner profile info (name + email) for rich display
final winnerProfileProvider =
    FutureProvider.family<Map<String, String>, String>((ref, userId) async {
      try {
        final resp = await _supabase
            .from('profiles')
            .select('full_name, email')
            .eq('id', userId)
            .single();
        return {
          'name': resp['full_name'] as String? ?? 'Unknown',
          'email': resp['email'] as String? ?? '',
        };
      } catch (_) {
        return {'name': 'Unknown', 'email': ''};
      }
    });
