import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doctrack/models/app_settings.dart';
import 'package:doctrack/models/document.dart';
import 'package:doctrack/services/notification_service.dart';
import 'package:doctrack/services/storage_service.dart';
import 'package:doctrack/state/doc_store.dart';
import 'package:doctrack/theme/app_theme.dart';
import 'package:doctrack/utils/date_utils.dart';

import 'fixtures/seed_data.dart';

DocStore _buildStore({List<DocRecord>? docs, DateTime? today}) {
  final t = today ?? DateTime(2026, 7, 29);
  return DocStore(
    initialDocs: docs ?? buildSeedDocuments(t),
    settings: AppSettings.defaults(),
    storage: StorageService(),
    notifications: NotificationService.instance,
    today: t,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('add / update / delete', () {
    test('addDocument assigns an id above any existing seed id and persists fields', () {
      final store = _buildStore();
      final before = store.totalCount;
      store.addDocument(
        type: DocType.custom,
        name: 'Gym membership',
        number: 'GYM-1',
        expiry: DateTime(2026, 12, 1),
      );
      expect(store.totalCount, before + 1);
      final added = store.sortedDocs.firstWhere((d) => d.name == 'Gym membership');
      expect(added.number, 'GYM-1');
      expect(added.id, greaterThanOrEqualTo(100));
    });

    test('updateDocument mutates the matching record only', () {
      final store = _buildStore();
      final doc = store.sortedDocs.first;
      store.updateDocument(doc.copyWith(name: 'Renamed'));
      expect(store.byId(doc.id)!.name, 'Renamed');
      expect(store.totalCount, buildSeedDocuments(store.today).length);
    });

    test('deleteDocument removes the record', () {
      final store = _buildStore();
      final doc = store.sortedDocs.first;
      store.deleteDocument(doc.id);
      expect(store.byId(doc.id), isNull);
    });

    test('toggleReminders flips remindersEnabled and reminderFeed excludes disabled docs', () {
      final store = _buildStore();
      final doc = store.sortedDocs.first;
      expect(doc.remindersEnabled, isTrue);
      store.toggleReminders(doc.id);
      expect(store.byId(doc.id)!.remindersEnabled, isFalse);
      expect(store.reminderFeed.any((e) => e.doc.id == doc.id), isFalse);
    });

    test('clearAllDocuments empties the store', () {
      final store = _buildStore();
      store.clearAllDocuments();
      expect(store.isEmpty, isTrue);
      expect(store.totalCount, 0);
    });
  });

  group('search / filter / sort', () {
    test('setSearchQuery filters by name, number and type label', () {
      final store = _buildStore();
      store.setSearchQuery('passport');
      expect(store.visibleDocs, hasLength(1));
      expect(store.visibleDocs.first.type, DocType.passport);

      store.setSearchQuery('KA05');
      expect(store.visibleDocs.length, greaterThanOrEqualTo(1));
      expect(store.visibleDocs.every((d) => d.number.contains('KA05') || d.name.contains('KA05')), isTrue);

      store.setSearchQuery('');
      expect(store.visibleDocs.length, store.totalCount);
    });

    test('setFilterStatus narrows by status and toggles off when reapplied', () {
      final store = _buildStore();
      final urgentCount = store.statusCounts[DocStatus.urgent] ?? 0;
      store.setFilterStatus(DocStatus.urgent);
      expect(store.visibleDocs, hasLength(urgentCount));
      expect(store.visibleDocs.every((d) => d.status(store.today) == DocStatus.urgent), isTrue);

      store.setFilterStatus(DocStatus.urgent);
      expect(store.filterStatus, isNull);
      expect(store.visibleDocs.length, store.totalCount);
    });

    test('setSortOption reorders visibleDocs', () {
      final store = _buildStore();
      store.setSortOption(SortOption.name);
      final names = store.visibleDocs.map((d) => d.name.toLowerCase()).toList();
      final sorted = [...names]..sort();
      expect(names, sorted);

      store.setSortOption(SortOption.expiry);
      final days = store.visibleDocs.map((d) => d.daysLeft(store.today)).toList();
      final sortedDays = [...days]..sort();
      expect(days, sortedDays);
    });
  });

  group('settings', () {
    test('setDefaultReminderDays updates settings used by new documents', () {
      final store = _buildStore();
      store.setDefaultReminderDays([14, 3]);
      expect(store.settings.defaultReminderDays, [14, 3]);
      store.addDocument(type: DocType.custom, name: 'New doc', expiry: DateTime(2027, 1, 1));
      final added = store.sortedDocs.firstWhere((d) => d.name == 'New doc');
      expect(added.reminderDays, [14, 3]);
    });

    test('setNotificationsEnabled(false) persists the preference', () async {
      final store = _buildStore();
      await store.setNotificationsEnabled(false);
      expect(store.settings.notificationsEnabled, isFalse);
    });
  });

  group('profile / onboarding / theme', () {
    test('completeOnboarding records the name and marks onboarding done', () {
      final store = _buildStore();
      expect(store.settings.onboardingComplete, isFalse);
      store.completeOnboarding('Aarav Rao');
      expect(store.settings.onboardingComplete, isTrue);
      expect(store.settings.userName, 'Aarav Rao');
    });

    test('completeOnboarding with an empty name still finishes onboarding', () {
      final store = _buildStore();
      store.completeOnboarding('   ');
      expect(store.settings.onboardingComplete, isTrue);
      expect(store.settings.userName, isEmpty);
    });

    test('setUserName updates and persists the display name', () {
      final store = _buildStore();
      store.setUserName('  Priya  ');
      expect(store.settings.userName, 'Priya');
    });

    test('setThemeMode updates settings and ThemeController together', () {
      final store = _buildStore();
      store.setThemeMode(AppThemeMode.dark);
      expect(store.settings.themeMode, 'dark');
      expect(ThemeController.instance.mode, AppThemeMode.dark);
      // Reset so later tests in this run see the default light/system theme.
      store.setThemeMode(AppThemeMode.system);
    });
  });

  group('persistence round-trip', () {
    test('DocRecord toJson/fromJson preserves all fields', () {
      final doc = DocRecord(
        id: 42,
        type: DocType.insurance,
        name: 'Health cover',
        number: 'POL-1',
        issued: DateTime(2020, 1, 1),
        expiry: DateTime(2027, 1, 1),
        photoPath: '/tmp/x.jpg',
        reminderDays: const [14, 2],
        remindersEnabled: false,
      );
      final restored = DocRecord.fromJson(doc.toJson());
      expect(restored.id, doc.id);
      expect(restored.type, doc.type);
      expect(restored.name, doc.name);
      expect(restored.number, doc.number);
      expect(restored.issued, doc.issued);
      expect(restored.expiry, doc.expiry);
      expect(restored.photoPath, doc.photoPath);
      expect(restored.reminderDays, doc.reminderDays);
      expect(restored.remindersEnabled, doc.remindersEnabled);
    });

    test('StorageService saves and reloads documents', () async {
      final storage = StorageService();
      final docs = buildSeedDocuments(DateTime(2026, 7, 29));
      await storage.saveDocuments(docs);
      final reloaded = await storage.loadDocuments();
      expect(reloaded, isNotNull);
      expect(reloaded!.length, docs.length);
      expect(reloaded.map((d) => d.id), docs.map((d) => d.id));
    });

    test('StorageService returns null when nothing has been saved yet', () async {
      final storage = StorageService();
      expect(await storage.loadDocuments(), isNull);
    });
  });

  group('today', () {
    test('refreshToday moves to the new date and notifies listeners', () {
      final store = _buildStore(today: DateTime(2026, 7, 29));
      final doc = store.sortedDocs.first;
      final before = doc.daysLeft(store.today);
      var notified = 0;
      store.addListener(() => notified++);

      store.refreshToday(DateTime(2026, 7, 31, 8, 15));
      expect(store.today, DateTime(2026, 7, 31));
      expect(store.byId(doc.id)!.daysLeft(store.today), before - 2);
      expect(notified, 1);
    });

    test('refreshToday on the same date does not notify', () {
      final store = _buildStore(today: DateTime(2026, 7, 29));
      var notified = 0;
      store.addListener(() => notified++);
      store.refreshToday(DateTime(2026, 7, 29, 23, 59));
      expect(notified, 0);
    });
  });

  group('date utils', () {
    test('shiftDays crosses month and year boundaries by calendar day', () {
      expect(shiftDays(DateTime(2026, 3, 1), 1), DateTime(2026, 2, 28));
      expect(shiftDays(DateTime(2027, 1, 5), 30), DateTime(2026, 12, 6));
    });

    test('daysBetween counts calendar days regardless of time of day', () {
      expect(daysBetween(DateTime(2026, 3, 30, 0, 5), DateTime(2026, 3, 28, 23, 50)), 2);
      expect(daysBetween(DateTime(2026, 11, 2), DateTime(2026, 10, 25)), 8);
      expect(daysBetween(DateTime(2026, 1, 1), DateTime(2026, 1, 2)), -1);
    });
  });
}
