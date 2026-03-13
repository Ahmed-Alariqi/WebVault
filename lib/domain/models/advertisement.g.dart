// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advertisement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Advertisement _$AdvertisementFromJson(Map<String, dynamic> json) =>
    _Advertisement(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      textContent: json['text_content'] as String?,
      displayDurationSeconds:
          (json['display_duration_seconds'] as num?)?.toInt() ?? 5,
      adEndDate: json['ad_end_date'] == null
          ? null
          : DateTime.parse(json['ad_end_date'] as String),
      showRemainingTime: json['show_remaining_time'] as bool? ?? false,
      targetScreen: json['target_screen'] as String? ?? 'both',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      linkUrl: json['link_url'] as String?,
      linkedWebsiteId: json['linked_website_id'] as String?,
    );

Map<String, dynamic> _$AdvertisementToJson(_Advertisement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'image_url': instance.imageUrl,
      'text_content': instance.textContent,
      'display_duration_seconds': instance.displayDurationSeconds,
      'ad_end_date': instance.adEndDate?.toIso8601String(),
      'show_remaining_time': instance.showRemainingTime,
      'target_screen': instance.targetScreen,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'link_url': instance.linkUrl,
      'linked_website_id': instance.linkedWebsiteId,
    };
