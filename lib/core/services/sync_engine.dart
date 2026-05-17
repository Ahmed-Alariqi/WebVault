import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../constants.dart';
import '../../data/models/sync_action.dart';
import '../../data/models/page_model.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/clipboard_item_model.dart';
import '../../data/repositories/settings_repository.dart';

class SyncEngine {
  final SupabaseClient _supabase;
  final SettingsRepository _settings;
  final Box _queueBox;

  bool _isProcessing = false;

  SyncEngine(this._supabase, this._settings) : _queueBox = Hive.box(kSyncQueueBox) {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        drainQueue();
      }
    });
  }

  bool get isSyncEnabled => _settings.isCloudSyncEnabled();

  // ─────────────────────────────────────────────────────────
  // PUSH (Local → Cloud)
  // ─────────────────────────────────────────────────────────

  Future<void> pushUpsert(String table, String recordId, Map<String, dynamic> data) async {
    if (!isSyncEnabled) return;
    
    // Check 5000 chars limit for clipboard specifically
    if (table == 'user_clipboard' && data['value'] != null) {
      if ((data['value'] as String).length > kMaxSyncValueLength) {
        debugPrint('[SyncEngine] Item exceeds max sync length. Skipping sync.');
        return;
      }
    }

    final action = SyncAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      table: table,
      operation: SyncOperation.upsert,
      recordId: recordId,
      data: data,
      timestamp: DateTime.now(),
    );

    await _enqueueAction(action);
    await drainQueue();
  }

  Future<void> pushDelete(String table, String recordId) async {
    if (!isSyncEnabled) return;

    final action = SyncAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      table: table,
      operation: SyncOperation.delete,
      recordId: recordId,
      timestamp: DateTime.now(),
    );

    await _enqueueAction(action);
    await drainQueue();
  }

  Future<void> _enqueueAction(SyncAction action) async {
    await _queueBox.put(action.id, action.toJson());
  }

  Future<void> drainQueue() async {
    if (_isProcessing) return;
    if (!isSyncEnabled) return;
    
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.every((r) => r == ConnectivityResult.none)) return;

    _isProcessing = true;

    try {
      final keys = _queueBox.keys.toList();
      keys.sort((a, b) {
        final actionA = SyncAction.fromJson(Map<String, dynamic>.from(_queueBox.get(a) as Map));
        final actionB = SyncAction.fromJson(Map<String, dynamic>.from(_queueBox.get(b) as Map));
        return actionA.timestamp.compareTo(actionB.timestamp);
      });

      for (final key in keys) {
        final rawData = _queueBox.get(key);
        if (rawData == null) continue;
        
        final action = SyncAction.fromJson(Map<String, dynamic>.from(rawData as Map));
        
        bool success = false;
        
        try {
          if (action.operation == SyncOperation.upsert) {
            final payload = _buildSupabasePayload(action.table, action.data!);
            payload['user_id'] = userId;
            
            await _supabase
                .from(action.table)
                .upsert(payload);
                
          } else if (action.operation == SyncOperation.delete) {
            await _supabase
                .from(action.table)
                .delete()
                .eq('id', action.recordId)
                .eq('user_id', userId);
          }
          success = true;
        } catch (e) {
          debugPrint('[SyncEngine] Failed to process action ${action.id}: $e');
          break;
        }

        if (success) {
          await _queueBox.delete(key);
        }
      }

      // Update last sync time on success
      if (_queueBox.isEmpty) {
        await _settings.setLastSyncTime(DateTime.now().toIso8601String());
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Converts local model JSON to Supabase-compatible payload.
  /// Uses dedicated toSupabaseJson() for clipboard items which have
  /// field name mismatches (value↔content, type int↔text).
  Map<String, dynamic> _buildSupabasePayload(String table, Map<String, dynamic> rawData) {
    if (table == 'user_clipboard') {
      final item = ClipboardItemModel.fromJson(rawData);
      return item.toSupabaseJson();
    }
    if (table == 'user_clipboard_groups') {
      final group = ClipboardGroupModel.fromJson(rawData);
      return group.toSupabaseJson();
    }
    // For pages and folders, use generic snake_case conversion
    final payload = _toSnakeCaseMap(Map<String, dynamic>.from(rawData));
    payload.remove('sync_enabled');
    return payload;
  }

  Map<String, dynamic> _toSnakeCaseMap(Map<String, dynamic> input) {
    final Map<String, dynamic> output = {};
    input.forEach((key, value) {
      final snakeKey = key.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
        return '_${match.group(0)!.toLowerCase()}';
      });
      output[snakeKey] = value;
    });
    return output;
  }

  // ─────────────────────────────────────────────────────────
  // PULL (Cloud → Local) — Restore
  // ─────────────────────────────────────────────────────────

  /// Returns the count of items stored in the cloud for the current user.
  /// Used by the welcome/restore screen to show what's available.
  Future<Map<String, int>> getCloudItemCounts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {'pages': 0, 'folders': 0, 'clipboard': 0, 'groups': 0};

    try {
      final results = await Future.wait([
        _supabase.from('user_pages').select('id').eq('user_id', userId),
        _supabase.from('user_folders').select('id').eq('user_id', userId),
        _supabase.from('user_clipboard').select('id').eq('user_id', userId),
        _supabase.from('user_clipboard_groups').select('id').eq('user_id', userId),
      ]);

      return {
        'pages': (results[0] as List).length,
        'folders': (results[1] as List).length,
        'clipboard': (results[2] as List).length,
        'groups': (results[3] as List).length,
      };
    } catch (e) {
      debugPrint('[SyncEngine] Failed to get cloud counts: $e');
      return {'pages': 0, 'folders': 0, 'clipboard': 0, 'groups': 0};
    }
  }

  /// Pulls all user data from cloud and merges into local Hive boxes.
  /// Existing local items with the same ID are overwritten by cloud data.
  /// Returns total number of items restored.
  Future<int> pullAllFromCloud() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    int totalRestored = 0;

    try {
      // ── 1. Folders (restore first because pages reference folder_id) ──
      final foldersData = await _supabase
          .from('user_folders')
          .select()
          .eq('user_id', userId);
      
      final foldersBox = Hive.box(kFoldersBox);
      await foldersBox.clear();
      for (final row in (foldersData as List)) {
        final folder = FolderModel.fromSupabaseJson(Map<String, dynamic>.from(row));
        await foldersBox.put(folder.id, folder.toJson());
        totalRestored++;
      }

      // ── 2. Pages ──
      final pagesData = await _supabase
          .from('user_pages')
          .select()
          .eq('user_id', userId);
      
      final pagesBox = Hive.box(kPagesBox);
      await pagesBox.clear();
      for (final row in (pagesData as List)) {
        final page = PageModel.fromSupabaseJson(Map<String, dynamic>.from(row));
        await pagesBox.put(page.id, page.toJson());
        totalRestored++;
      }

      // ── 3. Clipboard Groups (restore before items because items reference group_id) ──
      final groupsData = await _supabase
          .from('user_clipboard_groups')
          .select()
          .eq('user_id', userId);
      
      final groupsBox = Hive.box(kClipboardGroupsBox);
      await groupsBox.clear();
      for (final row in (groupsData as List)) {
        final group = ClipboardGroupModel.fromSupabaseJson(Map<String, dynamic>.from(row));
        await groupsBox.put(group.id, group.toJson());
        totalRestored++;
      }

      // ── 4. Clipboard Items ──
      final clipboardData = await _supabase
          .from('user_clipboard')
          .select()
          .eq('user_id', userId);
      
      final clipboardBox = Hive.box(kClipboardBox);
      await clipboardBox.clear();
      for (final row in (clipboardData as List)) {
        final item = ClipboardItemModel.fromSupabaseJson(Map<String, dynamic>.from(row));
        await clipboardBox.put(item.id, item.toJson());
        totalRestored++;
      }

      debugPrint('[SyncEngine] Restored $totalRestored items from cloud.');
      
      // Clear pending queue so dummy data isn't pushed later
      await _queueBox.clear();
      
      await _settings.setLastSyncTime(DateTime.now().toIso8601String());

    } catch (e) {
      debugPrint('[SyncEngine] pullAllFromCloud failed: $e');
    }

    return totalRestored;
  }

  int get queueCount => _queueBox.length;
}
