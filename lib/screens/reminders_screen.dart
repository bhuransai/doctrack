import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/doc_store.dart';
import '../theme/app_theme.dart';
import '../widgets/doc_icon_tile.dart';
import 'document_detail_screen.dart';
import 'settings_screen.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DocStore>(
      builder: (context, store, _) {
        final groups = store.reminderGroups;
        final today = store.today;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.borderCard)),
              ),
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${store.reminderFeed.length} SCHEDULED',
                        style: AppText.mono(size: 10, weight: FontWeight.w500, color: AppColors.textFaint, letterSpacing: 1.4),
                      ),
                      const SizedBox(height: 5),
                      Text('Reminders', style: AppText.sans(size: 27, weight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.borderFaint, borderRadius: BorderRadius.circular(10)),
                      child: Text('Settings', style: AppText.sans(size: 11.5, weight: FontWeight.w700, color: AppColors.textSlate)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: groups.isEmpty
                  ? Center(
                      child: Text('No reminders scheduled', style: AppText.sans(size: 13, weight: FontWeight.w500, color: AppColors.textMuted)),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      children: [
                        for (final entry in groups.entries) ...[
                          Text(entry.key, style: AppText.mono(size: 10, weight: FontWeight.w600, color: AppColors.textFaint, letterSpacing: 1.4)),
                          const SizedBox(height: 9),
                          for (final item in entry.value) ...[
                            _ReminderRow(
                              item: item,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => DocumentDetailScreen(docId: item.doc.id)),
                              ),
                              today: today,
                            ),
                            const SizedBox(height: 9),
                          ],
                          const SizedBox(height: 11),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final ReminderEntry item;
  final VoidCallback onTap;
  final DateTime today;
  const _ReminderRow({required this.item, required this.onTap, required this.today});

  @override
  Widget build(BuildContext context) {
    final palette = item.doc.palette(today);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderCard),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Color(0x0A101728), blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Row(
          children: [
            DocIconTile(type: item.doc.type, tint: palette.tint, strong: palette.strong, size: 38, iconSize: 19, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sans(size: 13.5, weight: FontWeight.w700, height: 1.25)),
                  const SizedBox(height: 4),
                  Text(item.sub, style: AppText.sans(size: 11.5, weight: FontWeight.w500, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(item.tag, style: AppText.mono(size: 10.5, weight: FontWeight.w600, color: palette.fg)),
          ],
        ),
      ),
    );
  }
}
