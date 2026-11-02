import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/document.dart';

/// Persists documents and preferences to on-device storage so nothing is
/// lost when the app restarts.
class StorageService {
  static const _docsKey = 'doctrack_docs_v1';
  static const _settingsKey = 'doctrack_settings_v1';

  Future<List<DocRecord>?> loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_docsKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => DocRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDocuments(List<DocRecord> docs) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(docs.map((d) => d.toJson()).toList());
    await prefs.setString(_docsKey, raw);
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return AppSettings.defaults();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

}
