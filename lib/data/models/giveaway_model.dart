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
  final String? winnerId;
  final DateTime? winnerAnnouncedAt;
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
    this.winnerAnnouncedAt,
    this.createdBy,
    required this.createdAt,
    this.entryCount = 0,
    this.hasEntered = false,
  });

  bool get isActive => status == 'active' && DateTime.now().isBefore(endsAt);
  bool get isEnded => status == 'ended' || (!isDrawn && DateTime.now().isAfter(endsAt));
  bool get isDrawn => status == 'drawn';
  bool get isFull => maxEntries != null && entryCount >= maxEntries!;

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
    DateTime? winnerAnnouncedAt,
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
      winnerAnnouncedAt: winnerAnnouncedAt ?? this.winnerAnnouncedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      entryCount: entryCount ?? this.entryCount,
      hasEntered: hasEntered ?? this.hasEntered,
    );
  }

  factory Giveaway.fromJson(Map<String, dynamic> json, {int entryCount = 0, bool hasEntered = false}) {
    return Giveaway(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      prizeType: json['prize_type'] as String? ?? 'other',
      startsAt: json['starts_at'] != null ? DateTime.parse(json['starts_at']) : null,
      endsAt: DateTime.parse(json['ends_at']),
      maxEntries: json['max_entries'] as int?,
      status: json['status'] as String? ?? 'active',
      winnerId: json['winner_id'] as String?,
      winnerAnnouncedAt: json['winner_announced_at'] != null
          ? DateTime.parse(json['winner_announced_at'])
          : null,
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
      'winner_announced_at': winnerAnnouncedAt?.toIso8601String(),
    };
  }
}

@immutable
class GiveawayEntry {
  final String id;
  final String giveawayId;
  final String userId;
  final DateTime enteredAt;
  final String? userName; // from join

  const GiveawayEntry({
    required this.id,
    required this.giveawayId,
    required this.userId,
    required this.enteredAt,
    this.userName,
  });

  factory GiveawayEntry.fromJson(Map<String, dynamic> json) {
    String? name;
    if (json['profiles'] is Map) {
      name = json['profiles']['display_name'] as String?;
    }
    return GiveawayEntry(
      id: json['id'] as String,
      giveawayId: json['giveaway_id'] as String,
      userId: json['user_id'] as String,
      enteredAt: DateTime.parse(json['entered_at']),
      userName: name,
    );
  }
}
