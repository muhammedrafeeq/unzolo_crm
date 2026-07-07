import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists each data table as a JSON list in SharedPreferences.
/// This is the local source of truth for offline-first operation.
class LocalCache {
  LocalCache._();

  static String _key(String table) => 'cache_$table';

  static Future<List<Map<String, dynamic>>> load(String table) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(table));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(String table, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(table), jsonEncode(data));
  }

  static Future<void> clear(String table) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(table));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final t in ['trips', 'deleted_trips', 'bookings', 'deactivated_bookings', 'expenses', 'customers', 'enquiries']) {
      await prefs.remove(_key(t));
    }
  }
}
