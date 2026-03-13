import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/advertisement.dart';
import '../../core/supabase_config.dart';

// Provides a list of active advertisements for a specific target screen ('home' or 'discover').
final advertisementsProvider =
    FutureProvider.family<List<Advertisement>, String>((
      ref,
      targetScreen,
    ) async {
      final response = await SupabaseConfig.client
          .from('advertisements')
          .select()
          .eq('is_active', true)
          .inFilter('target_screen', [targetScreen, 'both'])
          .order('created_at', ascending: false);

      final List<Advertisement> allAds = (response as List)
          .map((json) => Advertisement.fromJson(json))
          .toList();

      // Filter out ads that have passed their adEndDate
      final now = DateTime.now();
      return allAds.where((ad) {
        if (ad.adEndDate == null) return true;
        return ad.adEndDate!.isAfter(now);
      }).toList();
    });
