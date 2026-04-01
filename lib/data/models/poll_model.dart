import 'package:flutter/foundation.dart';

@immutable
class Poll {
  final String id;
  final String question;
  final String? description;
  final String? imageUrl;
  final List<String> options;
  final DateTime endsAt;
  final String status; // active, ended
  final bool allowMultiple;
  final String? createdBy;
  final DateTime createdAt;
  final Map<int, int> voteCounts; // optionIndex → count
  final int totalVotes;
  final Set<int> userVotes; // which options current user voted for

  const Poll({
    required this.id,
    required this.question,
    this.description,
    this.imageUrl,
    required this.options,
    required this.endsAt,
    this.status = 'active',
    this.allowMultiple = false,
    this.createdBy,
    required this.createdAt,
    this.voteCounts = const {},
    this.totalVotes = 0,
    this.userVotes = const {},
  });

  bool get isActive => status == 'active' && DateTime.now().isBefore(endsAt);
  bool get isEnded => !isActive;
  bool get hasVoted => userVotes.isNotEmpty;
  Duration get timeRemaining => endsAt.difference(DateTime.now());

  double votePercentage(int optionIndex) {
    if (totalVotes == 0) return 0;
    return (voteCounts[optionIndex] ?? 0) / totalVotes;
  }

  int get winningOptionIndex {
    if (voteCounts.isEmpty) return 0;
    int maxVotes = 0;
    int winner = 0;
    for (final entry in voteCounts.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        winner = entry.key;
      }
    }
    return winner;
  }

  Poll copyWith({
    String? id,
    String? question,
    String? description,
    String? imageUrl,
    List<String>? options,
    DateTime? endsAt,
    String? status,
    bool? allowMultiple,
    String? createdBy,
    DateTime? createdAt,
    Map<int, int>? voteCounts,
    int? totalVotes,
    Set<int>? userVotes,
  }) {
    return Poll(
      id: id ?? this.id,
      question: question ?? this.question,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      options: options ?? this.options,
      endsAt: endsAt ?? this.endsAt,
      status: status ?? this.status,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      voteCounts: voteCounts ?? this.voteCounts,
      totalVotes: totalVotes ?? this.totalVotes,
      userVotes: userVotes ?? this.userVotes,
    );
  }

  factory Poll.fromJson(
    Map<String, dynamic> json, {
    Map<int, int> voteCounts = const {},
    int totalVotes = 0,
    Set<int> userVotes = const {},
  }) {
    final optionsRaw = json['options'];
    List<String> opts = [];
    if (optionsRaw is List) {
      opts = optionsRaw.map((e) => e.toString()).toList();
    }

    return Poll(
      id: json['id'] as String,
      question: json['question'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      options: opts,
      endsAt: DateTime.parse(json['ends_at']),
      status: json['status'] as String? ?? 'active',
      allowMultiple: json['allow_multiple'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      voteCounts: voteCounts,
      totalVotes: totalVotes,
      userVotes: userVotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'description': description,
      'image_url': imageUrl,
      'options': options,
      'ends_at': endsAt.toIso8601String(),
      'status': status,
      'allow_multiple': allowMultiple,
    };
  }
}
