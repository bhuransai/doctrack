import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/app_shell.dart';
import 'screens/welcome_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'state/doc_store.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  final notifications = NotificationService.instance;
  await notifications.init();

  final today = DateTime.now();
  final docs = await storage.loadDocuments() ?? [];
  final settings = await storage.loadSettings();

  final store = DocStore(
    initialDocs: docs,
    settings: settings,
    storage: storage,
    notifications: notifications,
    today: today,
  );

  if (settings.notificationsEnabled) {
    final granted = await notifications.requestPermission();
    if (granted) {
      // ignore: unawaited_futures
      notifications.rescheduleAll(docs, userName: settings.userName);
    }
  }

  runApp(DocTrackApp(store: store));
}

class DocTrackApp extends StatelessWidget {
  final DocStore store;
  const DocTrackApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DocStore>.value(
      value: store,
      child: const _AppRoot(),
    );
  }
}

/// Separate from [DocTrackApp] so it can sit *below* the [DocStore] provider
/// and watch it — a theme-mode change (in Settings) calls
/// `DocStore.notifyListeners()`, which needs to rebuild this widget so
/// [MaterialApp.themeMode] and every [AppColors] getter picked up during
/// this rebuild reflect the new choice.
///
/// It also refreshes [DocStore.today] whenever the app returns to the
/// foreground, so countdowns don't go stale overnight.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<DocStore>().refreshToday(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DocStore>();
    return MaterialApp(
      title: 'DocTrack',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeController.instance.flutterMode,
      home: store.settings.onboardingComplete ? const AppShell() : const WelcomeScreen(),
      // DocTrack's screens are laid out for a phone-width column. On wide
      // windows (desktop, web) cap content to that width and centre it,
      // rather than stretching cards, grids and dialogs edge to edge.
      builder: (context, child) => ColoredBox(
        color: AppColors.canvas,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
    );
  }
}
