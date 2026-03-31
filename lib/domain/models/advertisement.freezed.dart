// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'advertisement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Advertisement {

 String get id; String get title;@JsonKey(name: 'image_url') String get imageUrl;@JsonKey(name: 'text_content') String? get textContent;@JsonKey(name: 'display_duration_seconds') int get displayDurationSeconds;@JsonKey(name: 'ad_end_date') DateTime? get adEndDate;@JsonKey(name: 'show_remaining_time') bool get showRemainingTime;@JsonKey(name: 'target_screen') String get targetScreen;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'link_url') String? get linkUrl;@JsonKey(name: 'linked_website_id') String? get linkedWebsiteId;@JsonKey(name: 'detail_card_enabled') bool get detailCardEnabled;@JsonKey(name: 'detail_card_instructions') String? get detailCardInstructions;@JsonKey(name: 'detail_card_button_text') String? get detailCardButtonText;@JsonKey(name: 'detail_card_action_type') String get detailCardActionType;@JsonKey(name: 'detail_card_action_url') String? get detailCardActionUrl;
/// Create a copy of Advertisement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdvertisementCopyWith<Advertisement> get copyWith => _$AdvertisementCopyWithImpl<Advertisement>(this as Advertisement, _$identity);

  /// Serializes this Advertisement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Advertisement&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.textContent, textContent) || other.textContent == textContent)&&(identical(other.displayDurationSeconds, displayDurationSeconds) || other.displayDurationSeconds == displayDurationSeconds)&&(identical(other.adEndDate, adEndDate) || other.adEndDate == adEndDate)&&(identical(other.showRemainingTime, showRemainingTime) || other.showRemainingTime == showRemainingTime)&&(identical(other.targetScreen, targetScreen) || other.targetScreen == targetScreen)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.linkUrl, linkUrl) || other.linkUrl == linkUrl)&&(identical(other.linkedWebsiteId, linkedWebsiteId) || other.linkedWebsiteId == linkedWebsiteId)&&(identical(other.detailCardEnabled, detailCardEnabled) || other.detailCardEnabled == detailCardEnabled)&&(identical(other.detailCardInstructions, detailCardInstructions) || other.detailCardInstructions == detailCardInstructions)&&(identical(other.detailCardButtonText, detailCardButtonText) || other.detailCardButtonText == detailCardButtonText)&&(identical(other.detailCardActionType, detailCardActionType) || other.detailCardActionType == detailCardActionType)&&(identical(other.detailCardActionUrl, detailCardActionUrl) || other.detailCardActionUrl == detailCardActionUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,imageUrl,textContent,displayDurationSeconds,adEndDate,showRemainingTime,targetScreen,isActive,createdAt,linkUrl,linkedWebsiteId,detailCardEnabled,detailCardInstructions,detailCardButtonText,detailCardActionType,detailCardActionUrl);

@override
String toString() {
  return 'Advertisement(id: $id, title: $title, imageUrl: $imageUrl, textContent: $textContent, displayDurationSeconds: $displayDurationSeconds, adEndDate: $adEndDate, showRemainingTime: $showRemainingTime, targetScreen: $targetScreen, isActive: $isActive, createdAt: $createdAt, linkUrl: $linkUrl, linkedWebsiteId: $linkedWebsiteId, detailCardEnabled: $detailCardEnabled, detailCardInstructions: $detailCardInstructions, detailCardButtonText: $detailCardButtonText, detailCardActionType: $detailCardActionType, detailCardActionUrl: $detailCardActionUrl)';
}


}

/// @nodoc
abstract mixin class $AdvertisementCopyWith<$Res>  {
  factory $AdvertisementCopyWith(Advertisement value, $Res Function(Advertisement) _then) = _$AdvertisementCopyWithImpl;
@useResult
$Res call({
 String id, String title,@JsonKey(name: 'image_url') String imageUrl,@JsonKey(name: 'text_content') String? textContent,@JsonKey(name: 'display_duration_seconds') int displayDurationSeconds,@JsonKey(name: 'ad_end_date') DateTime? adEndDate,@JsonKey(name: 'show_remaining_time') bool showRemainingTime,@JsonKey(name: 'target_screen') String targetScreen,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'link_url') String? linkUrl,@JsonKey(name: 'linked_website_id') String? linkedWebsiteId,@JsonKey(name: 'detail_card_enabled') bool detailCardEnabled,@JsonKey(name: 'detail_card_instructions') String? detailCardInstructions,@JsonKey(name: 'detail_card_button_text') String? detailCardButtonText,@JsonKey(name: 'detail_card_action_type') String detailCardActionType,@JsonKey(name: 'detail_card_action_url') String? detailCardActionUrl
});




}
/// @nodoc
class _$AdvertisementCopyWithImpl<$Res>
    implements $AdvertisementCopyWith<$Res> {
  _$AdvertisementCopyWithImpl(this._self, this._then);

  final Advertisement _self;
  final $Res Function(Advertisement) _then;

/// Create a copy of Advertisement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? imageUrl = null,Object? textContent = freezed,Object? displayDurationSeconds = null,Object? adEndDate = freezed,Object? showRemainingTime = null,Object? targetScreen = null,Object? isActive = null,Object? createdAt = null,Object? linkUrl = freezed,Object? linkedWebsiteId = freezed,Object? detailCardEnabled = null,Object? detailCardInstructions = freezed,Object? detailCardButtonText = freezed,Object? detailCardActionType = null,Object? detailCardActionUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,textContent: freezed == textContent ? _self.textContent : textContent // ignore: cast_nullable_to_non_nullable
as String?,displayDurationSeconds: null == displayDurationSeconds ? _self.displayDurationSeconds : displayDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,adEndDate: freezed == adEndDate ? _self.adEndDate : adEndDate // ignore: cast_nullable_to_non_nullable
as DateTime?,showRemainingTime: null == showRemainingTime ? _self.showRemainingTime : showRemainingTime // ignore: cast_nullable_to_non_nullable
as bool,targetScreen: null == targetScreen ? _self.targetScreen : targetScreen // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,linkUrl: freezed == linkUrl ? _self.linkUrl : linkUrl // ignore: cast_nullable_to_non_nullable
as String?,linkedWebsiteId: freezed == linkedWebsiteId ? _self.linkedWebsiteId : linkedWebsiteId // ignore: cast_nullable_to_non_nullable
as String?,detailCardEnabled: null == detailCardEnabled ? _self.detailCardEnabled : detailCardEnabled // ignore: cast_nullable_to_non_nullable
as bool,detailCardInstructions: freezed == detailCardInstructions ? _self.detailCardInstructions : detailCardInstructions // ignore: cast_nullable_to_non_nullable
as String?,detailCardButtonText: freezed == detailCardButtonText ? _self.detailCardButtonText : detailCardButtonText // ignore: cast_nullable_to_non_nullable
as String?,detailCardActionType: null == detailCardActionType ? _self.detailCardActionType : detailCardActionType // ignore: cast_nullable_to_non_nullable
as String,detailCardActionUrl: freezed == detailCardActionUrl ? _self.detailCardActionUrl : detailCardActionUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Advertisement].
extension AdvertisementPatterns on Advertisement {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Advertisement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Advertisement() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Advertisement value)  $default,){
final _that = this;
switch (_that) {
case _Advertisement():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Advertisement value)?  $default,){
final _that = this;
switch (_that) {
case _Advertisement() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'text_content')  String? textContent, @JsonKey(name: 'display_duration_seconds')  int displayDurationSeconds, @JsonKey(name: 'ad_end_date')  DateTime? adEndDate, @JsonKey(name: 'show_remaining_time')  bool showRemainingTime, @JsonKey(name: 'target_screen')  String targetScreen, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'link_url')  String? linkUrl, @JsonKey(name: 'linked_website_id')  String? linkedWebsiteId, @JsonKey(name: 'detail_card_enabled')  bool detailCardEnabled, @JsonKey(name: 'detail_card_instructions')  String? detailCardInstructions, @JsonKey(name: 'detail_card_button_text')  String? detailCardButtonText, @JsonKey(name: 'detail_card_action_type')  String detailCardActionType, @JsonKey(name: 'detail_card_action_url')  String? detailCardActionUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Advertisement() when $default != null:
return $default(_that.id,_that.title,_that.imageUrl,_that.textContent,_that.displayDurationSeconds,_that.adEndDate,_that.showRemainingTime,_that.targetScreen,_that.isActive,_that.createdAt,_that.linkUrl,_that.linkedWebsiteId,_that.detailCardEnabled,_that.detailCardInstructions,_that.detailCardButtonText,_that.detailCardActionType,_that.detailCardActionUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'text_content')  String? textContent, @JsonKey(name: 'display_duration_seconds')  int displayDurationSeconds, @JsonKey(name: 'ad_end_date')  DateTime? adEndDate, @JsonKey(name: 'show_remaining_time')  bool showRemainingTime, @JsonKey(name: 'target_screen')  String targetScreen, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'link_url')  String? linkUrl, @JsonKey(name: 'linked_website_id')  String? linkedWebsiteId, @JsonKey(name: 'detail_card_enabled')  bool detailCardEnabled, @JsonKey(name: 'detail_card_instructions')  String? detailCardInstructions, @JsonKey(name: 'detail_card_button_text')  String? detailCardButtonText, @JsonKey(name: 'detail_card_action_type')  String detailCardActionType, @JsonKey(name: 'detail_card_action_url')  String? detailCardActionUrl)  $default,) {final _that = this;
switch (_that) {
case _Advertisement():
return $default(_that.id,_that.title,_that.imageUrl,_that.textContent,_that.displayDurationSeconds,_that.adEndDate,_that.showRemainingTime,_that.targetScreen,_that.isActive,_that.createdAt,_that.linkUrl,_that.linkedWebsiteId,_that.detailCardEnabled,_that.detailCardInstructions,_that.detailCardButtonText,_that.detailCardActionType,_that.detailCardActionUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'text_content')  String? textContent, @JsonKey(name: 'display_duration_seconds')  int displayDurationSeconds, @JsonKey(name: 'ad_end_date')  DateTime? adEndDate, @JsonKey(name: 'show_remaining_time')  bool showRemainingTime, @JsonKey(name: 'target_screen')  String targetScreen, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'link_url')  String? linkUrl, @JsonKey(name: 'linked_website_id')  String? linkedWebsiteId, @JsonKey(name: 'detail_card_enabled')  bool detailCardEnabled, @JsonKey(name: 'detail_card_instructions')  String? detailCardInstructions, @JsonKey(name: 'detail_card_button_text')  String? detailCardButtonText, @JsonKey(name: 'detail_card_action_type')  String detailCardActionType, @JsonKey(name: 'detail_card_action_url')  String? detailCardActionUrl)?  $default,) {final _that = this;
switch (_that) {
case _Advertisement() when $default != null:
return $default(_that.id,_that.title,_that.imageUrl,_that.textContent,_that.displayDurationSeconds,_that.adEndDate,_that.showRemainingTime,_that.targetScreen,_that.isActive,_that.createdAt,_that.linkUrl,_that.linkedWebsiteId,_that.detailCardEnabled,_that.detailCardInstructions,_that.detailCardButtonText,_that.detailCardActionType,_that.detailCardActionUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Advertisement implements Advertisement {
  const _Advertisement({required this.id, required this.title, @JsonKey(name: 'image_url') required this.imageUrl, @JsonKey(name: 'text_content') this.textContent, @JsonKey(name: 'display_duration_seconds') this.displayDurationSeconds = 5, @JsonKey(name: 'ad_end_date') this.adEndDate, @JsonKey(name: 'show_remaining_time') this.showRemainingTime = false, @JsonKey(name: 'target_screen') this.targetScreen = 'both', @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'link_url') this.linkUrl, @JsonKey(name: 'linked_website_id') this.linkedWebsiteId, @JsonKey(name: 'detail_card_enabled') this.detailCardEnabled = false, @JsonKey(name: 'detail_card_instructions') this.detailCardInstructions, @JsonKey(name: 'detail_card_button_text') this.detailCardButtonText, @JsonKey(name: 'detail_card_action_type') this.detailCardActionType = 'support_chat', @JsonKey(name: 'detail_card_action_url') this.detailCardActionUrl});
  factory _Advertisement.fromJson(Map<String, dynamic> json) => _$AdvertisementFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey(name: 'image_url') final  String imageUrl;
@override@JsonKey(name: 'text_content') final  String? textContent;
@override@JsonKey(name: 'display_duration_seconds') final  int displayDurationSeconds;
@override@JsonKey(name: 'ad_end_date') final  DateTime? adEndDate;
@override@JsonKey(name: 'show_remaining_time') final  bool showRemainingTime;
@override@JsonKey(name: 'target_screen') final  String targetScreen;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'link_url') final  String? linkUrl;
@override@JsonKey(name: 'linked_website_id') final  String? linkedWebsiteId;
@override@JsonKey(name: 'detail_card_enabled') final  bool detailCardEnabled;
@override@JsonKey(name: 'detail_card_instructions') final  String? detailCardInstructions;
@override@JsonKey(name: 'detail_card_button_text') final  String? detailCardButtonText;
@override@JsonKey(name: 'detail_card_action_type') final  String detailCardActionType;
@override@JsonKey(name: 'detail_card_action_url') final  String? detailCardActionUrl;

/// Create a copy of Advertisement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdvertisementCopyWith<_Advertisement> get copyWith => __$AdvertisementCopyWithImpl<_Advertisement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdvertisementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Advertisement&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.textContent, textContent) || other.textContent == textContent)&&(identical(other.displayDurationSeconds, displayDurationSeconds) || other.displayDurationSeconds == displayDurationSeconds)&&(identical(other.adEndDate, adEndDate) || other.adEndDate == adEndDate)&&(identical(other.showRemainingTime, showRemainingTime) || other.showRemainingTime == showRemainingTime)&&(identical(other.targetScreen, targetScreen) || other.targetScreen == targetScreen)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.linkUrl, linkUrl) || other.linkUrl == linkUrl)&&(identical(other.linkedWebsiteId, linkedWebsiteId) || other.linkedWebsiteId == linkedWebsiteId)&&(identical(other.detailCardEnabled, detailCardEnabled) || other.detailCardEnabled == detailCardEnabled)&&(identical(other.detailCardInstructions, detailCardInstructions) || other.detailCardInstructions == detailCardInstructions)&&(identical(other.detailCardButtonText, detailCardButtonText) || other.detailCardButtonText == detailCardButtonText)&&(identical(other.detailCardActionType, detailCardActionType) || other.detailCardActionType == detailCardActionType)&&(identical(other.detailCardActionUrl, detailCardActionUrl) || other.detailCardActionUrl == detailCardActionUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,imageUrl,textContent,displayDurationSeconds,adEndDate,showRemainingTime,targetScreen,isActive,createdAt,linkUrl,linkedWebsiteId,detailCardEnabled,detailCardInstructions,detailCardButtonText,detailCardActionType,detailCardActionUrl);

@override
String toString() {
  return 'Advertisement(id: $id, title: $title, imageUrl: $imageUrl, textContent: $textContent, displayDurationSeconds: $displayDurationSeconds, adEndDate: $adEndDate, showRemainingTime: $showRemainingTime, targetScreen: $targetScreen, isActive: $isActive, createdAt: $createdAt, linkUrl: $linkUrl, linkedWebsiteId: $linkedWebsiteId, detailCardEnabled: $detailCardEnabled, detailCardInstructions: $detailCardInstructions, detailCardButtonText: $detailCardButtonText, detailCardActionType: $detailCardActionType, detailCardActionUrl: $detailCardActionUrl)';
}


}

/// @nodoc
abstract mixin class _$AdvertisementCopyWith<$Res> implements $AdvertisementCopyWith<$Res> {
  factory _$AdvertisementCopyWith(_Advertisement value, $Res Function(_Advertisement) _then) = __$AdvertisementCopyWithImpl;
@override @useResult
$Res call({
 String id, String title,@JsonKey(name: 'image_url') String imageUrl,@JsonKey(name: 'text_content') String? textContent,@JsonKey(name: 'display_duration_seconds') int displayDurationSeconds,@JsonKey(name: 'ad_end_date') DateTime? adEndDate,@JsonKey(name: 'show_remaining_time') bool showRemainingTime,@JsonKey(name: 'target_screen') String targetScreen,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'link_url') String? linkUrl,@JsonKey(name: 'linked_website_id') String? linkedWebsiteId,@JsonKey(name: 'detail_card_enabled') bool detailCardEnabled,@JsonKey(name: 'detail_card_instructions') String? detailCardInstructions,@JsonKey(name: 'detail_card_button_text') String? detailCardButtonText,@JsonKey(name: 'detail_card_action_type') String detailCardActionType,@JsonKey(name: 'detail_card_action_url') String? detailCardActionUrl
});




}
/// @nodoc
class __$AdvertisementCopyWithImpl<$Res>
    implements _$AdvertisementCopyWith<$Res> {
  __$AdvertisementCopyWithImpl(this._self, this._then);

  final _Advertisement _self;
  final $Res Function(_Advertisement) _then;

/// Create a copy of Advertisement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? imageUrl = null,Object? textContent = freezed,Object? displayDurationSeconds = null,Object? adEndDate = freezed,Object? showRemainingTime = null,Object? targetScreen = null,Object? isActive = null,Object? createdAt = null,Object? linkUrl = freezed,Object? linkedWebsiteId = freezed,Object? detailCardEnabled = null,Object? detailCardInstructions = freezed,Object? detailCardButtonText = freezed,Object? detailCardActionType = null,Object? detailCardActionUrl = freezed,}) {
  return _then(_Advertisement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,textContent: freezed == textContent ? _self.textContent : textContent // ignore: cast_nullable_to_non_nullable
as String?,displayDurationSeconds: null == displayDurationSeconds ? _self.displayDurationSeconds : displayDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,adEndDate: freezed == adEndDate ? _self.adEndDate : adEndDate // ignore: cast_nullable_to_non_nullable
as DateTime?,showRemainingTime: null == showRemainingTime ? _self.showRemainingTime : showRemainingTime // ignore: cast_nullable_to_non_nullable
as bool,targetScreen: null == targetScreen ? _self.targetScreen : targetScreen // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,linkUrl: freezed == linkUrl ? _self.linkUrl : linkUrl // ignore: cast_nullable_to_non_nullable
as String?,linkedWebsiteId: freezed == linkedWebsiteId ? _self.linkedWebsiteId : linkedWebsiteId // ignore: cast_nullable_to_non_nullable
as String?,detailCardEnabled: null == detailCardEnabled ? _self.detailCardEnabled : detailCardEnabled // ignore: cast_nullable_to_non_nullable
as bool,detailCardInstructions: freezed == detailCardInstructions ? _self.detailCardInstructions : detailCardInstructions // ignore: cast_nullable_to_non_nullable
as String?,detailCardButtonText: freezed == detailCardButtonText ? _self.detailCardButtonText : detailCardButtonText // ignore: cast_nullable_to_non_nullable
as String?,detailCardActionType: null == detailCardActionType ? _self.detailCardActionType : detailCardActionType // ignore: cast_nullable_to_non_nullable
as String,detailCardActionUrl: freezed == detailCardActionUrl ? _self.detailCardActionUrl : detailCardActionUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
