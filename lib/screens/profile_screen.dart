import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/doc_store.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';
import 'settings_screen.dart';

/// The "You" tab: an at-a-glance summary of what's being tracked plus the
/// entry point into Settings. DocTrack has no cloud account — everything
/// here is derived from what's stored on this device.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DocStore>(
      builder: (context, store, _) {
        final counts = store.statusCounts;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.borderCard)),
              ),
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: AppColors.inkStrong, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: initialsFor(store.settings.userName).isEmpty
                        ? const Icon(Icons.person_outline_rounded, color: Colors.white, size: 26)
                        : Text(initialsFor(store.settings.userName), style: AppText.sans(size: 18, weight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstNameOf(store.settings.userName).isEmpty ? 'Your vault' : 'Hi ${firstNameOf(store.settings.userName)}',
                          style: AppText.sans(size: 20, weight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${store.totalCount} documents tracked on this device',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(size: 12, weight: FontWeight.w500, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              _StatTile(count: counts[DocStatus.urgent] ?? 0, label: 'Expired', color: AppColors.urgentFg),
                              const SizedBox(width: 8),
                              _StatTile(count: counts[DocStatus.soon] ?? 0, label: 'Expiring soon', color: AppColors.soonFg),
                              const SizedBox(width: 8),
                              _StatTile(count: counts[DocStatus.safe] ?? 0, label: 'All good', color: AppColors.safeFg),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _StatTile(count: store.withPhotoCount, label: 'With photo', color: AppColors.accent),
                              const SizedBox(width: 8),
                              _StatTile(count: store.reminderFeed.length, label: 'Reminders set', color: AppColors.accent),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _MenuRow(
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            sub: 'Notifications, reminder defaults, data',
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    child: Text(
                      'DocTrack keeps everything — documents, photos and reminders — only on this device. There is no cloud account or sync.',
                      style: AppText.sans(size: 11.5, weight: FontWeight.w500, color: AppColors.textFaint, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _StatTile({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderCard),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count', style: AppText.mono(size: 20, weight: FontWeight.w700, color: color)),
            const SizedBox(height: 3),
            Text(label, style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _MenuRow({required this.icon, required this.label, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderCard),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AppColors.accentTint, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Icon(icon, size: 19, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppText.sans(size: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(sub, style: AppText.sans(size: 11, weight: FontWeight.w500, color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }
}
