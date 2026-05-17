import 'dart:convert';

enum SyncOperation { upsert, delete }

class SyncAction {
  final String id;
  final String table;
  final SyncOperation operation;
  final String recordId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  SyncAction({
    required this.id,
    required this.table,
    required this.operation,
    required this.recordId,
    this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table': table,
      'operation': operation.name,
      'recordId': recordId,
      'data': data != null ? jsonEncode(data) : null,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SyncAction.fromJson(Map<String, dynamic> json) {
    return SyncAction(
      id: json['id'] as String,
      table: json['table'] as String,
      operation: SyncOperation.values.firstWhere((e) => e.name == json['operation']),
      recordId: json['recordId'] as String,
      data: json['data'] != null ? jsonDecode(json['data'] as String) as Map<String, dynamic> : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
