import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doctrack/main.dart';
import 'package:doctrack/models/app_settings.dart';
import 'package:doctrack/services/notification_service.dart';
import 'package:doctrack/services/storage_service.dart';
import 'package:doctrack/state/doc_store.dart';

import 'fixtures/seed_data.dart';

DocStore _buildTestStore() {
  final today = DateTime.now();
  return DocStore(
    initialDocs: buildSeedDocuments(today),
    settings: AppSettings.defaults(),
    storage: StorageService(),
    notifications: NotificationService.instance,
    today: today,
  );
}

/// Pumps [DocTrackApp] on a tall-enough surface that every screen's content
/// (DocTrack's phone-width column, capped by the app's own layout) renders
/// without needing a scroll first — matching a real phone's aspect ratio
/// rather than the default short/wide test window.
Future<void> _pumpApp(WidgetTester tester, DocStore store) async {
  tester.view.physicalSize = const Size(480, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(DocTrackApp(store: store));
  await tester.pumpAndSettle();

  // Land on the welcome screen first; move past it into the Documents tab.
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Welcome screen shows first and leads into Documents', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(480, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(DocTrackApp(store: _buildTestStore()));
    await tester.pumpAndSettle();

    expect(find.text('DocTrack'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Documents'), findsNothing);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Documents'), findsWidgets);
  });

  testWidgets('Name entered on the welcome screen personalises the You tab', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(480, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(DocTrackApp(store: _buildTestStore()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Priya Sharma');
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();

    expect(find.text('Hi Priya'), findsOneWidget);
    expect(find.text('PS'), findsOneWidget);
  });

  testWidgets('DocTrack home screen shows seed documents', (WidgetTester tester) async {
    await _pumpApp(tester, _buildTestStore());

    expect(find.text('Documents'), findsWidgets);
    expect(find.text('Passport — Aarav Rao'), findsOneWidget);
  });

  testWidgets('Tapping Add opens the add-document flow', (WidgetTester tester) async {
    await _pumpApp(tester, _buildTestStore());

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Add document'), findsOneWidget);
  });

  testWidgets('Search narrows the documents list', (WidgetTester tester) async {
    await _pumpApp(tester, _buildTestStore());

    expect(find.text('Honda City — RC'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Passport');
    await tester.pumpAndSettle();

    expect(find.text('Passport — Aarav Rao'), findsOneWidget);
    expect(find.text('Honda City — RC'), findsNothing);
  });

  testWidgets('Vault tab shows a grid of all documents', (WidgetTester tester) async {
    await _pumpApp(tester, _buildTestStore());

    await tester.tap(find.byIcon(Icons.folder_outlined));
    await tester.pumpAndSettle();

    expect(find.textContaining('TOTAL'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('You tab shows stats and links to Settings', (WidgetTester tester) async {
    await _pumpApp(tester, _buildTestStore());

    // The home header avatar also falls back to a person icon when no name
    // is set, so target the bottom nav tab by its label instead.
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();

    expect(find.text('Your vault'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Expiry reminders'), findsOneWidget);
  });

  testWidgets('Settings is reachable from the Reminders tab too', (WidgetTester tester) async {
    await _pumpApp(tester, _buildTestStore());

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Expiry reminders'), findsOneWidget);
  });

  testWidgets('Edit updates a document', (WidgetTester tester) async {
    await _pumpApp(tester, _buildTestStore());

    await tester.tap(find.text('Car insurance — comprehensive'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit document'), findsOneWidget);
  });

  testWidgets('Reminder ON/OFF badge toggles', (WidgetTester tester) async {
    await _pumpApp(tester, _buildTestStore());

    await tester.tap(find.text('Car insurance — comprehensive'));
    await tester.pumpAndSettle();

    expect(find.text('ON'), findsOneWidget);
    await tester.tap(find.text('ON'));
    await tester.pumpAndSettle();

    expect(find.text('OFF'), findsOneWidget);
    expect(find.text('Reminders are off for this document.'), findsOneWidget);
  });

  testWidgets('Delete removes a document after confirmation', (WidgetTester tester) async {
    await _pumpApp(tester, _buildTestStore());

    await tester.tap(find.text('Honda City — RC'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete document?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Honda City — RC'), findsNothing);
  });
}
