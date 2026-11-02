import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/document.dart';
import '../services/photo_service.dart';
import '../state/doc_store.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/status_badge.dart';
import 'add_document_screen.dart';

class DocumentDetailScreen extends StatelessWidget {
  final int docId;
  const DocumentDetailScreen({super.key, required this.docId});

  Future<void> _confirmDelete(BuildContext context, DocStore store, DocRecord doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('"${doc.name}" and its reminders will be permanently removed. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: AppColors.urgentFg)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      store.deleteDocument(doc.id);
      if (context.mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
  }

  Future<void> _replacePhoto(BuildContext context, DocStore store, DocRecord doc) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (doc.hasPhoto)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.urgentFg),
                title: Text('Remove photo', style: TextStyle(color: AppColors.urgentFg)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
    if (action == null) return;
    final photoService = PhotoService();
    if (action == 'remove') {
      store.updateDocument(doc.copyWith(clearPhoto: true));
      unawaited(photoService.delete(doc.photoPath));
      return;
    }
    final String? path;
    try {
      path = await photoService.pickAndStore(fromCamera: action == 'camera');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access camera/gallery.')),
        );
      }
      return;
    }
    if (path != null) {
      store.updateDocument(doc.copyWith(photoPath: path));
      unawaited(photoService.delete(doc.photoPath));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocStore>(
      builder: (context, store, _) {
        final doc = store.byId(docId);
        if (doc == null) {
          // Deleted while viewing — pop back to the list.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final today = store.today;
        final palette = doc.palette(today);

        return Scaffold(
          backgroundColor: AppColors.screenBg,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: palette.tint,
                padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 12, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PillButton(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.ink),
                        ),
                        Row(
                          children: [
                            _PillButton(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => AddDocumentScreen(existing: doc)),
                              ),
                              child: Text('Edit', style: AppText.sans(size: 12, weight: FontWeight.w700, color: AppColors.ink)),
                            ),
                            const SizedBox(width: 8),
                            _PillButton(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                              onTap: () => _confirmDelete(context, store, doc),
                              child: Text('Delete', style: AppText.sans(size: 12, weight: FontWeight.w700, color: AppColors.urgentFg)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: const [BoxShadow(color: Color(0x12101728), blurRadius: 12, offset: Offset(0, 4))],
                          ),
                          alignment: Alignment.center,
                          child: Icon(doc.type.icon, color: palette.strong, size: 27),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                doc.name,
                                style: AppText.sans(size: 19, weight: FontWeight.w800, color: AppColors.ink, height: 1.2, letterSpacing: -0.15),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  StatusBadge(palette: palette, solid: true),
                                  const SizedBox(width: 7),
                                  Text(doc.daysLong(today), style: AppText.mono(size: 11.5, weight: FontWeight.w600, color: palette.fg)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    _Card(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _replacePhoto(context, store, doc),
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceRaised,
                                border: Border(bottom: BorderSide(color: AppColors.borderCard)),
                              ),
                              alignment: Alignment.center,
                              child: doc.hasPhoto
                                  ? Image.file(File(doc.photoPath!), fit: BoxFit.cover, width: double.infinity, height: 150)
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_a_photo_outlined, size: 26, color: AppColors.textDisabled),
                                        const SizedBox(height: 8),
                                        Text('No scan attached · tap to add', style: AppText.sans(size: 11, weight: FontWeight.w600, color: AppColors.textFaint)),
                                      ],
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  doc.hasPhoto ? '1 attachment · stored on device' : 'No attachment',
                                  style: AppText.sans(size: 11.5, weight: FontWeight.w600, color: AppColors.textSlate),
                                ),
                                GestureDetector(
                                  onTap: () => _replacePhoto(context, store, doc),
                                  child: Text(doc.hasPhoto ? 'Replace' : 'Add photo', style: AppText.sans(size: 11.5, weight: FontWeight.w700, color: AppColors.accent)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          _InfoRow(k: 'Type', v: doc.type.label, showDivider: true),
                          _InfoRow(k: 'Number', v: doc.number, showDivider: true),
                          _InfoRow(k: 'Issued', v: fmtDate(doc.issued), showDivider: true),
                          _InfoRow(k: 'Expires', v: fmtDate(doc.expiry), showDivider: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Reminder schedule', style: AppText.sans(size: 13, weight: FontWeight.w700)),
                              GestureDetector(
                                onTap: () => store.toggleReminders(doc.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: doc.remindersEnabled ? AppColors.safeTint : AppColors.borderFaint,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    doc.remindersEnabled ? 'ON' : 'OFF',
                                    style: AppText.mono(
                                      size: 10,
                                      weight: FontWeight.w700,
                                      color: doc.remindersEnabled ? AppColors.safeFg : AppColors.textFaint,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (!doc.remindersEnabled)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text('Reminders are off for this document.', style: AppText.sans(size: 12, weight: FontWeight.w500, color: AppColors.textMuted)),
                            ),
                          Opacity(
                            opacity: doc.remindersEnabled ? 1 : 0.4,
                            child: Column(
                              children: [
                                for (var i = 0; i < doc.reminderDays.length; i++)
                                  _ScheduleRow(
                                    n: doc.reminderDays[i],
                                    doc: doc,
                                    today: today,
                                    palette: palette,
                                    isLast: i == doc.reminderDays.length - 1,
                                  ),
                              ],
                            ),
                          ),
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

class _PillButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  const _PillButton({required this.child, this.onTap, this.padding = const EdgeInsets.all(9)});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(11)),
        child: child,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(15)});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderCard),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      padding: padding,
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String k;
  final String v;
  final bool showDivider;
  const _InfoRow({required this.k, required this.v, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: showDivider ? Border(bottom: BorderSide(color: AppColors.borderFaint)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: AppText.sans(size: 12.5, weight: FontWeight.w600, color: AppColors.textMuted)),
          Text(v, style: AppText.mono(size: 13, weight: FontWeight.w600, color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final int n;
  final DocRecord doc;
  final DateTime today;
  final StatusPalette palette;
  final bool isLast;

  const _ScheduleRow({
    required this.n,
    required this.doc,
    required this.today,
    required this.palette,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final when = shiftDays(doc.expiry, n);
    final past = daysBetween(when, today) < 0;
    final dot = past ? AppColors.chevron : palette.strong;
    final ring = past ? AppColors.borderFaint : palette.tint;
    final fg = past ? AppColors.textFaint : AppColors.ink;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                const SizedBox(height: 3),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle, border: Border.all(color: ring, width: 2.5)),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: AppColors.borderFaint)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      '$n day${n == 1 ? '' : 's'} before expiry',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(size: 12.5, weight: FontWeight.w600, color: fg),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fmtDate(when) + (past ? ' · sent' : ''),
                    style: AppText.mono(size: 11.5, weight: FontWeight.w500, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
