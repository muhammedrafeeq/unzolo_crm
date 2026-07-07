import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kQueueKey = 'offline_queue';
const _kMaxRetries = 5;

class QueuedOp {
  final String id;
  final String table;
  final String operation; // 'insert' | 'update' | 'delete'
  final Map<String, dynamic> data;
  final String? matchColumn;
  final String? matchValue;
  final int retries;
  final int timestamp;

  const QueuedOp({
    required this.id,
    required this.table,
    required this.operation,
    required this.data,
    this.matchColumn,
    this.matchValue,
    this.retries = 0,
    required this.timestamp,
  });

  QueuedOp withRetry() => QueuedOp(
        id: id,
        table: table,
        operation: operation,
        data: data,
        matchColumn: matchColumn,
        matchValue: matchValue,
        retries: retries + 1,
        timestamp: timestamp,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'table': table,
        'operation': operation,
        'data': data,
        'matchColumn': matchColumn,
        'matchValue': matchValue,
        'retries': retries,
        'timestamp': timestamp,
      };

  factory QueuedOp.fromJson(Map<String, dynamic> j) => QueuedOp(
        id: j['id'] as String,
        table: j['table'] as String,
        operation: j['operation'] as String,
        data: Map<String, dynamic>.from(j['data'] as Map),
        matchColumn: j['matchColumn'] as String?,
        matchValue: j['matchValue'] as String?,
        retries: j['retries'] as int? ?? 0,
        timestamp: j['timestamp'] as int,
      );
}

class OfflineQueue {
  OfflineQueue._();

  static Future<List<QueuedOp>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kQueueKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => QueuedOp.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<void> _save(List<QueuedOp> ops) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kQueueKey, jsonEncode(ops.map((o) => o.toJson()).toList()));
  }

  static Future<void> enqueue(QueuedOp op) async {
    final ops = await _load();
    ops.add(op);
    await _save(ops);
  }

  static Future<int> pendingCount() async {
    final ops = await _load();
    return ops.length;
  }

  /// Executes all queued ops against Supabase.
  /// Returns the number of successfully flushed operations.
  static Future<int> flush() async {
    final db = Supabase.instance.client;
    final ops = await _load();
    if (ops.isEmpty) return 0;

    final remaining = <QueuedOp>[];
    int flushed = 0;

    for (final op in ops) {
      if (op.retries >= _kMaxRetries) continue; // drop after max retries
      try {
        switch (op.operation) {
          case 'insert':
            await db.from(op.table).insert(op.data);
            break;
          case 'update':
            if (op.matchColumn != null && op.matchValue != null) {
              await db.from(op.table).update(op.data).eq(op.matchColumn!, op.matchValue!);
            }
            break;
          case 'upsert':
            await db.from(op.table).upsert(op.data);
            break;
          case 'delete':
            if (op.matchColumn != null && op.matchValue != null) {
              await db.from(op.table).delete().eq(op.matchColumn!, op.matchValue!);
            }
            break;
        }
        flushed++;
      } catch (_) {
        remaining.add(op.withRetry());
      }
    }

    await _save(remaining);
    return flushed;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kQueueKey);
  }
}
