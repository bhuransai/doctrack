import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/document.dart';
import '../state/doc_store.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/status_badge.dart';
import 'document_detail_screen.dart';

/// Visual grid of every tracked document — the photo/scan view of the same
/// data the Documents list shows, so scans are quick to browse and pick from.
class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DocStore>(
      builder: (context, store, _) {
        final today = store.today;
        final docs = store.sortedDocs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.borderCard)),
              ),
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${store.withPhotoCount} WITH SCANS · ${docs.length} TOTAL',
                    style: AppText.mono(size: 10, weight: FontWeight.w500, color: AppColors.textFaint, letterSpacing: 1.4),
                  ),
                  const SizedBox(height: 5),
                  Text('Vault', style: AppText.sans(size: 27, weight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3)),
                ],
              ),
            ),
            Expanded(
              child: docs.isEmpty
                  ? Center(
                      child: Text('No documents yet', style: AppText.sans(size: 13, weight: FontWeight.w500, color: AppColors.textMuted)),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final doc = docs[i];
                        final palette = doc.palette(today);
                        return GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => DocumentDetailScreen(docId: doc.id)),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.borderCard),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [BoxShadow(color: Color(0x0D101728), blurRadius: 2, offset: Offset(0, 1))],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(color: palette.tint),
                                    alignment: Alignment.center,
                                    child: doc.hasPhoto
                                        ? Image.file(File(doc.photoPath!), fit: BoxFit.cover, width: double.infinity)
                                        : Icon(doc.type.icon, size: 30, color: palette.strong),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        doc.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.sans(size: 12.5, weight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          StatusBadge(palette: palette),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              fmtDate(doc.expiry),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppText.mono(size: 10, weight: FontWeight.w500, color: AppColors.textMuted),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
