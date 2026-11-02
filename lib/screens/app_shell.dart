import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/doc_store.dart';
import '../theme/app_theme.dart';
import '../widgets/doctrack_bottom_bar.dart';
import 'add_document_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';
import 'vault_screen.dart';

/// Root shell: Documents / Reminders / Vault / You live behind the bottom
/// tab bar, Add is a modal sheet, Detail is pushed on top.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  void _openAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddDocumentScreen(), fullscreenDialog: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DocStore>();
    final reminderCount = store.reminderFeed.length;
    final showTabBar = !(_tab == 0 && store.isEmpty);

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      extendBody: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(onAdd: _openAdd),
            const RemindersScreen(),
            const VaultScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: showTabBar
          ? DocTrackBottomBar(
              currentIndex: _tab,
              reminderCount: reminderCount,
              onHome: () => setState(() => _tab = 0),
              onReminders: () => setState(() => _tab = 1),
              onVault: () => setState(() => _tab = 2),
              onYou: () => setState(() => _tab = 3),
              onAdd: _openAdd,
            )
          : null,
    );
  }
}
