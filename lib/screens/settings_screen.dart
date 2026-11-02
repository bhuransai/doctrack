import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../state/doc_store.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmClearAll(BuildContext context, DocStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all documents?'),
        content: const Text('Every tracked document and its reminders will be permanently deleted. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Clear all', style: TextStyle(color: AppColors.urgentFg)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      store.clearAllDocuments();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All documents cleared.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocStore>(
      builder: (context, store, _) {
        final settings = store.settings;
        return Scaffold(
          backgroundColor: AppColors.screenBg,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
                    ),
                    const SizedBox(width: 14),
                    Text('Settings', style: AppText.sans(size: 17, weight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
                  children: [
                    _SectionLabel('PROFILE'),
                    const SizedBox(height: 6),
                    Text('Your name personalises expiry reminders — "Hi Aarav, your passport expires soon."',
                        style: AppText.sans(size: 11.5, weight: FontWeight.w500, color: AppColors.textMuted)),
                    const SizedBox(height: 10),
                    _NameField(initialName: settings.userName, onSaved: store.setUserName),
                    const SizedBox(height: 22),
                    _SectionLabel('APPEARANCE'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final mode in AppThemeMode.values) ...[
                          Expanded(
                            child: _ThemeChip(
                              mode: mode,
                              on: AppThemeModeCodec.fromKey(settings.themeMode) == mode,
                              onTap: () => store.setThemeMode(mode),
                            ),
                          ),
                          if (mode != AppThemeMode.dark) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel('NOTIFICATIONS'),
                    const SizedBox(height: 10),
                    _Card(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Expiry reminders', style: AppText.sans(size: 13.5, weight: FontWeight.w700)),
                                    const SizedBox(height: 3),
                                    Text('Alerts on this device before a document expires', style: AppText.sans(size: 11.5, weight: FontWeight.w500, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: settings.notificationsEnabled,
                                activeThumbColor: AppColors.accent,
                                onChanged: (v) => store.setNotificationsEnabled(v),
                              ),
                            ],
                          ),
                          if (settings.notificationsEnabled && !NotificationService.instance.permissionGranted) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(color: AppColors.soonTint, borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                'Notification permission was not granted. Reminders will still show in the Reminders tab, but won\'t appear as system alerts. Allow notifications for DocTrack in your device settings to enable them.',
                                style: AppText.sans(size: 11.5, weight: FontWeight.w500, color: AppColors.soonFg, height: 1.4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel('DEFAULT REMINDER SCHEDULE'),
                    const SizedBox(height: 6),
                    Text('Applied to new documents — each one can still be customised.', style: AppText.sans(size: 11.5, weight: FontWeight.w500, color: AppColors.textMuted)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final n in [30, 7, 1]) ...[
                          Expanded(
                            child: _ReminderChip(
                              n: n,
                              on: settings.defaultReminderDays.contains(n),
                              onTap: () {
                                final days = Set<int>.from(settings.defaultReminderDays);
                                if (days.contains(n)) {
                                  days.remove(n);
                                } else {
                                  days.add(n);
                                }
                                store.setDefaultReminderDays(days.toList()..sort((a, b) => b.compareTo(a)));
                              },
                            ),
                          ),
                          if (n != 1) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel('DATA'),
                    const SizedBox(height: 10),
                    _ActionRow(
                      icon: Icons.delete_sweep_outlined,
                      label: 'Clear all documents',
                      danger: true,
                      onTap: () => _confirmClearAll(context, store),
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel('ABOUT'),
                    const SizedBox(height: 10),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DocTrack', style: AppText.sans(size: 13.5, weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Version 1.0.0 · documents stored only on this device — never uploaded, never shared.',
                              style: AppText.sans(size: 11.5, weight: FontWeight.w500, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.mono(size: 10, weight: FontWeight.w600, color: AppColors.textFaint, letterSpacing: 1.4));
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderCard),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// Name input with its own controller (so typing doesn't get clobbered by
/// [DocStore] rebuilds) — saved on submit or when the field loses focus.
class _NameField extends StatefulWidget {
  final String initialName;
  final ValueChanged<String> onSaved;
  const _NameField({required this.initialName, required this.onSaved});

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) widget.onSaved(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textCapitalization: TextCapitalization.words,
      onSubmitted: widget.onSaved,
      style: AppText.sans(size: 14, weight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'Your name',
        hintStyle: AppText.sans(size: 14, weight: FontWeight.w600, color: AppColors.textDisabled),
        filled: true,
        fillColor: AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.all(14),
        prefixIcon: Icon(Icons.person_outline_rounded, size: 19, color: AppColors.textFaint),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: AppColors.borderInput, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: AppColors.borderInput, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: AppColors.accent, width: 1.5)),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final AppThemeMode mode;
  final bool on;
  final VoidCallback onTap;
  const _ThemeChip({required this.mode, required this.on, required this.onTap});

  IconData get _icon {
    switch (mode) {
      case AppThemeMode.system:
        return Icons.brightness_auto_rounded;
      case AppThemeMode.light:
        return Icons.light_mode_rounded;
      case AppThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }

  String get _label {
    switch (mode) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: on ? AppColors.accentSoft : AppColors.surface,
          border: Border.all(color: on ? AppColors.accent : AppColors.borderCard, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(_icon, size: 18, color: on ? AppColors.accent : AppColors.textDisabled),
            const SizedBox(height: 5),
            Text(_label, style: AppText.sans(size: 11, weight: FontWeight.w600, color: on ? AppColors.accentMuted : AppColors.textDisabled)),
          ],
        ),
      ),
    );
  }
}

class _ReminderChip extends StatelessWidget {
  final int n;
  final bool on;
  final VoidCallback onTap;
  const _ReminderChip({required this.n, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: on ? AppColors.accentSoft : AppColors.surface,
          border: Border.all(color: on ? AppColors.accent : AppColors.borderCard, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('$n', style: AppText.mono(size: 15, weight: FontWeight.w700, color: on ? AppColors.accent : AppColors.textDisabled)),
            const SizedBox(height: 3),
            Text('days before', style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: on ? AppColors.accentMuted : AppColors.textDisabled)),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _ActionRow({required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.urgentFg : AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderCard),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppText.sans(size: 13, weight: FontWeight.w700, color: color))),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }
}
