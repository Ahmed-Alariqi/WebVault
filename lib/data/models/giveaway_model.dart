import 'package:flutter/foundation.dart';

@immutable
class Giveaway {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String prizeType;
  final DateTime? startsAt;
  final DateTime endsAt;
  final int? maxEntries;
  final String status; // active, ended, drawn
  final String? winnerId; // legacy single winner
  final List<String> winnerIds; // multiple winners
  final int winnerCount; // how many winners to draw
  final DateTime? winnerAnnouncedAt;
  final String? entryFieldLabel; // label for user-input field (null = disabled)
  final String? createdBy;
  final DateTime createdAt;
  final int entryCount; // computed from join
  final bool hasEntered; // computed: did current user enter

  const Giveaway({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.prizeType = 'other',
    this.startsAt,
    required this.endsAt,
    this.maxEntries,
    this.status = 'active',
    this.winnerId,
    this.winnerIds = const [],
    this.winnerCount = 1,
    this.winnerAnnouncedAt,
    this.entryFieldLabel,
    this.createdBy,
    required this.createdAt,
    this.entryCount = 0,
    this.hasEntered = false,
  });

  bool get isActive => status == 'active' && DateTime.now().isBefore(endsAt);
  bool get isEnded =>
      status == 'ended' || (!isDrawn && DateTime.now().isAfter(endsAt));
  bool get isDrawn => status == 'drawn';
  bool get isFull => maxEntries != null && entryCount >= maxEntries!;
  bool get hasEntryField =>
      entryFieldLabel != null && entryFieldLabel!.isNotEmpty;

  Duration get timeRemaining => endsAt.difference(DateTime.now());

  Giveaway copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? prizeType,
    DateTime? startsAt,
    DateTime? endsAt,
    int? maxEntries,
    String? status,
    String? winnerId,
    List<String>? winnerIds,
    int? winnerCount,
    DateTime? winnerAnnouncedAt,
    String? entryFieldLabel,
    String? createdBy,
    DateTime? createdAt,
    int? entryCount,
    bool? hasEntered,
  }) {
    return Giveaway(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      prizeType: prizeType ?? this.prizeType,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      maxEntries: maxEntries ?? this.maxEntries,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      winnerIds: winnerIds ?? this.winnerIds,
      winnerCount: winnerCount ?? this.winnerCount,
      winnerAnnouncedAt: winnerAnnouncedAt ?? this.winnerAnnouncedAt,
      entryFieldLabel: entryFieldLabel ?? this.entryFieldLabel,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      entryCount: entryCount ?? this.entryCount,
      hasEntered: hasEntered ?? this.hasEntered,
    );
  }

  factory Giveaway.fromJson(
    Map<String, dynamic> json, {
    int entryCount = 0,
    bool hasEntered = false,
  }) {
    // Parse winner_ids from JSONB
    List<String> ids = [];
    if (json['winner_ids'] != null) {
      ids = (json['winner_ids'] as List).map((e) => e.toString()).toList();
    }

    return Giveaway(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      prizeType: json['prize_type'] as String? ?? 'other',
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'])
          : null,
      endsAt: DateTime.parse(json['ends_at']),
      maxEntries: json['max_entries'] as int?,
      status: json['status'] as String? ?? 'active',
      winnerId: json['winner_id'] as String?,
      winnerIds: ids,
      winnerCount: json['winner_count'] as int? ?? 1,
      winnerAnnouncedAt: json['winner_announced_at'] != null
          ? DateTime.parse(json['winner_announced_at'])
          : null,
      entryFieldLabel: json['entry_field_label'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      entryCount: entryCount,
      hasEntered: hasEntered,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'prize_type': prizeType,
      'starts_at': startsAt?.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'max_entries': maxEntries,
      'status': status,
      'winner_id': winnerId,
      'winner_ids': winnerIds,
      'winner_count': winnerCount,
      'winner_announced_at': winnerAnnouncedAt?.toIso8601String(),
      'entry_field_label': entryFieldLabel,
    };
  }
}

@immutable
class GiveawayEntry {
  final String id;
  final String giveawayId;
  final String userId;
  final DateTime enteredAt;
  final String? userName; // from profiles join
  final String? userEmail; // from profiles join
  final String? entryValue; // user-submitted value

  const GiveawayEntry({
    required this.id,
    required this.giveawayId,
    required this.userId,
    required this.enteredAt,
    this.userName,
    this.userEmail,
    this.entryValue,
  });

  factory GiveawayEntry.fromJson(Map<String, dynamic> json) {
    String? name;
    String? email;
    if (json['profiles'] is Map) {
      name = json['profiles']['full_name'] as String?;
      email = json['profiles']['email'] as String?;
    }
    return GiveawayEntry(
      id: json['id'] as String,
      giveawayId: json['giveaway_id'] as String,
      userId: json['user_id'] as String,
      enteredAt: DateTime.parse(json['entered_at']),
      userName: name,
      userEmail: email,
      entryValue: json['entry_value'] as String?,
    );
  }
}
