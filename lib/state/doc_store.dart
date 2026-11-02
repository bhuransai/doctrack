import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/document.dart';
import '../services/notification_service.dart';
import '../services/photo_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';

class ReminderEntry {
  final DocRecord doc;
  /// True for the "has expired" alert, as opposed to an upcoming reminder.
  final bool overdue;
  final DateTime when;
  final String title;
  final String sub;
  final String tag;
  const ReminderEntry({
    required this.doc,
    required this.when,
    required this.title,
    required this.sub,
    required this.tag,
    this.overdue = false,
  });
}

enum SortOption { expiry, name, type, recentlyAdded }

extension SortOptionMeta on SortOption {
  String get label {
    switch (this) {
      case SortOption.expiry:
        return 'Expiry';
      case SortOption.name:
        return 'Name';
      case SortOption.type:
        return 'Type';
      case SortOption.recentlyAdded:
        return 'Recently added';
    }
  }
}

/// Holds the document list and exposes derived data (summary counts,
/// reminder feed) the way the design doc's `renderVals()` computed it.
/// Documents and preferences are persisted via [StorageService]; expiry
/// reminders are scheduled as real OS notifications via [NotificationService].
class DocStore extends ChangeNotifier {
  DateTime _today;
  final StorageService storage;
  final NotificationService notifications;
  final PhotoService _photoService = PhotoService();
  late int _nextId;
  List<DocRecord> _docs;
  AppSettings settings;

  SortOption _sortOption = SortOption.expiry;
  String _searchQuery = '';
  DocStatus? _filterStatus;

  DocStore({
    required List<DocRecord> initialDocs,
    required this.settings,
    required this.storage,
    required this.notifications,
    DateTime? today,
  })  : _today = dateOnly(today ?? DateTime.now()),
        _docs = initialDocs {
    _nextId = _computeNextId();
    ThemeController.instance.setMode(AppThemeModeCodec.fromKey(settings.themeMode));
  }

  int _computeNextId() {
    if (_docs.isEmpty) return 100;
    final maxId = _docs.map((d) => d.id).reduce((a, b) => a > b ? a : b);
    return maxId + 1 > 100 ? maxId + 1 : 100;
  }

  /// The date every status, countdown and reminder is computed against.
  DateTime get today => _today;

  /// Moves [today] forward to [now] (default: the current time) if the
  /// calendar date has changed — called when the app returns to the
  /// foreground, since a backgrounded app can stay alive for days.
  void refreshToday([DateTime? now]) {
    final date = dateOnly(now ?? DateTime.now());
    if (date == _today) return;
    _today = date;
    notifyListeners();
  }

  SortOption get sortOption => _sortOption;
  String get searchQuery => _searchQuery;
  DocStatus? get filterStatus => _filterStatus;

  List<DocRecord> get _allByExpiry {
    final list = List<DocRecord>.from(_docs);
    list.sort((a, b) => a.daysLeft(today).compareTo(b.daysLeft(today)));
    return list;
  }

  /// Documents for the Documents tab: search + status filter applied, then
  /// sorted per [sortOption].
  List<DocRecord> get visibleDocs {
    var list = List<DocRecord>.from(_docs);
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list
          .where((d) =>
              d.name.toLowerCase().contains(q) ||
              d.number.toLowerCase().contains(q) ||
              d.type.label.toLowerCase().contains(q))
          .toList();
    }
    if (_filterStatus != null) {
      list = list.where((d) => d.status(today) == _filterStatus).toList();
    }
    switch (_sortOption) {
      case SortOption.expiry:
        list.sort((a, b) => a.daysLeft(today).compareTo(b.daysLeft(today)));
        break;
      case SortOption.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.type:
        list.sort((a, b) => a.type.label.compareTo(b.type.label));
        break;
      case SortOption.recentlyAdded:
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
    }
    return list;
  }

  /// Kept for callers that want the full, unfiltered list ordered by expiry
  /// (e.g. the Vault screen).
  List<DocRecord> get sortedDocs => _allByExpiry;

  bool get isEmpty => _docs.isEmpty;
  int get totalCount => _docs.length;

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void setFilterStatus(DocStatus? status) {
    _filterStatus = (_filterStatus == status) ? null : status;
    notifyListeners();
  }

  DocRecord? byId(int id) {
    for (final d in _docs) {
      if (d.id == id) return d;
    }
    return null;
  }

  Map<DocStatus, int> get statusCounts {
    final counts = {DocStatus.urgent: 0, DocStatus.soon: 0, DocStatus.safe: 0};
    for (final d in _docs) {
      counts[d.status(today)] = (counts[d.status(today)] ?? 0) + 1;
    }
    return counts;
  }

  int get withPhotoCount => _docs.where((d) => d.hasPhoto).length;

  void addDocument({
    required DocType type,
    required String name,
    required DateTime expiry,
    String number = '—',
    DateTime? issued,
    String? photoPath,
    List<int>? reminderDays,
  }) {
    final id = _nextId++;
    final doc = DocRecord(
      id: id,
      type: type,
      name: name.trim(),
      number: number.trim().isEmpty ? '—' : number.trim(),
      issued: issued ?? today,
      expiry: expiry,
      photoPath: photoPath,
      reminderDays: reminderDays ?? settings.defaultReminderDays,
    );
    _docs.add(doc);
    notifyListeners();
    _persist();
    _scheduleFor(doc);
  }

  void updateDocument(DocRecord updated) {
    final index = _docs.indexWhere((d) => d.id == updated.id);
    if (index == -1) return;
    _docs[index] = updated;
    notifyListeners();
    _persist();
    _scheduleFor(updated);
  }

  void toggleReminders(int id) {
    final doc = byId(id);
    if (doc == null) return;
    updateDocument(doc.copyWith(remindersEnabled: !doc.remindersEnabled));
  }

  void deleteDocument(int id) {
    final doc = byId(id);
    _docs.removeWhere((d) => d.id == id);
    notifyListeners();
    _persist();
    notifications.cancelForDocument(id);
    if (doc != null) unawaited(_photoService.delete(doc.photoPath));
  }

  void clearAllDocuments() {
    for (final d in _docs) {
      notifications.cancelForDocument(d.id);
      if (d.hasPhoto) unawaited(_photoService.delete(d.photoPath));
    }
    _docs = [];
    notifyListeners();
    _persist();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    settings = settings.copyWith(notificationsEnabled: enabled);
    notifyListeners();
    unawaited(storage.saveSettings(settings));
    if (enabled) {
      final granted = await notifications.requestPermission();
      if (granted) _rescheduleAll();
      // Settings shows a "permission not granted" notice; refresh it now
      // that the prompt has been answered.
      notifyListeners();
    } else {
      await notifications.cancelAll();
    }
  }

  /// Re-checks the OS notification permission without prompting — at launch
  /// and whenever the app returns to the foreground, since the user may have
  /// allowed (or blocked) DocTrack in system settings meanwhile. Reminders
  /// are (re)scheduled when permission is found granted.
  Future<void> refreshNotificationPermission() async {
    if (!settings.notificationsEnabled) return;
    final wasGranted = notifications.permissionGranted;
    final granted = await notifications.checkPermission();
    // Only on a change: at launch (starts ungranted) or after the user
    // allowed notifications in system settings — not on every resume.
    if (granted && !wasGranted) _rescheduleAll();
    if (granted != wasGranted) notifyListeners();
  }

  /// Called when the OS switches between light and dark. In "System" theme
  /// mode every [AppColors] getter now resolves differently, so rebuild all
  /// listening screens — the same path [setThemeMode] relies on.
  void onPlatformBrightnessChanged() {
    if (ThemeController.instance.mode == AppThemeMode.system) notifyListeners();
  }

  void setDefaultReminderDays(List<int> days) {
    settings = settings.copyWith(defaultReminderDays: days);
    notifyListeners();
    unawaited(storage.saveSettings(settings));
  }

  /// Sets the display name used to personalise reminder notifications
  /// (e.g. "Hi Aarav — Passport expires in 7 days"). Existing reminders are
  /// re-scheduled so already-queued notifications pick up the new greeting.
  void setUserName(String name) {
    settings = settings.copyWith(userName: name.trim());
    notifyListeners();
    unawaited(storage.saveSettings(settings));
    _rescheduleAll();
  }

  void setThemeMode(AppThemeMode mode) {
    settings = settings.copyWith(themeMode: mode.key);
    ThemeController.instance.setMode(mode);
    notifyListeners();
    unawaited(storage.saveSettings(settings));
  }

  /// Called once, from the welcome screen's "Get started" — records the
  /// (optional) name and marks onboarding done so the app opens straight
  /// into Documents on every later launch.
  ///
  /// This is also where notification permission is first requested, so the
  /// prompt appears after the user has seen what DocTrack is for rather
  /// than over a blank launch screen.
  void completeOnboarding(String name) {
    settings = settings.copyWith(userName: name.trim(), onboardingComplete: true);
    notifyListeners();
    unawaited(storage.saveSettings(settings));
    if (settings.notificationsEnabled) {
      unawaited(notifications.requestPermission().then((granted) {
        if (granted) _rescheduleAll();
        notifyListeners();
      }));
    }
  }

  void _persist() {
    unawaited(storage.saveDocuments(_docs));
  }

  void _scheduleFor(DocRecord doc) {
    if (!settings.notificationsEnabled) return;
    unawaited(notifications.scheduleForDocument(doc, userName: settings.userName));
  }

  void _rescheduleAll() {
    if (!settings.notificationsEnabled) return;
    unawaited(notifications.rescheduleAll(_docs, userName: settings.userName));
  }

  /// Reminder feed: an overdue alert for expired docs, plus 30/7/1-day
  /// look-ahead reminders, sorted by date and bucketed for the Reminders tab.
  List<ReminderEntry> get reminderFeed {
    final items = <ReminderEntry>[];
    for (final d in _allByExpiry) {
      if (!d.remindersEnabled) continue;
      final dl = d.daysLeft(today);
      if (dl < 0) {
        items.add(ReminderEntry(
          doc: d,
          when: today,
          title: '${d.name} has expired',
          sub: 'Expired ${fmtDate(d.expiry)} · renew now',
          tag: 'Now',
          overdue: true,
        ));
      }
      for (final n in d.reminderDays) {
        final when = shiftDays(d.expiry, n);
        final diff = daysBetween(when, today);
        if (diff >= 0) {
          items.add(ReminderEntry(
            doc: d,
            when: when,
            title: '$n-day reminder · ${d.type.label}',
            sub: '${d.name} expires ${fmtDate(d.expiry)}',
            tag: diff == 0 ? 'Today' : 'in ${diff}d',
          ));
        }
      }
    }
    items.sort((a, b) => a.when.compareTo(b.when));
    return items;
  }

  Map<String, List<ReminderEntry>> get reminderGroups {
    final feed = reminderFeed;
    final buckets = <String, bool Function(int)>{
      'TODAY': (n) => n == 0,
      'THIS WEEK': (n) => n > 0 && n <= 7,
      'THIS MONTH': (n) => n > 7 && n <= 31,
      'LATER': (n) => n > 31,
    };
    final result = <String, List<ReminderEntry>>{};
    buckets.forEach((label, test) {
      final matches = feed
          .where((i) => test(daysBetween(i.when, today)))
          .take(4)
          .toList();
      if (matches.isNotEmpty) result[label] = matches;
    });
    return result;
  }
}
