import 'package:freezed_annotation/freezed_annotation.dart';

part 'advertisement.freezed.dart';
part 'advertisement.g.dart';

@freezed
abstract class Advertisement with _$Advertisement {
  const factory Advertisement({
    required String id,
    required String title,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'text_content') String? textContent,
    @JsonKey(name: 'display_duration_seconds')
    @Default(5)
    int displayDurationSeconds,
    @JsonKey(name: 'ad_end_date') DateTime? adEndDate,
    @JsonKey(name: 'show_remaining_time')
    @Default(false)
    bool showRemainingTime,
    @JsonKey(name: 'target_screen') @Default('both') String targetScreen,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'link_url') String? linkUrl,
    @JsonKey(name: 'linked_website_id') String? linkedWebsiteId,
    @JsonKey(name: 'detail_card_enabled')
    @Default(false)
    bool detailCardEnabled,
    @JsonKey(name: 'detail_card_instructions') String? detailCardInstructions,
    @JsonKey(name: 'detail_card_button_text') String? detailCardButtonText,
    @JsonKey(name: 'detail_card_action_type')
    @Default('support_chat')
    String detailCardActionType,
    @JsonKey(name: 'detail_card_action_url') String? detailCardActionUrl,
  }) = _Advertisement;

  factory Advertisement.fromJson(Map<String, dynamic> json) =>
      _$AdvertisementFromJson(json);
}
