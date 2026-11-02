import 'package:flutter/material.dart';
import '../models/document.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import 'doc_icon_tile.dart';

class DocumentCard extends StatelessWidget {
  final DocRecord doc;
  final DateTime today;
  final VoidCallback onTap;

  const DocumentCard({
    super.key,
    required this.doc,
    required this.today,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = doc.palette(today);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderCard),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x0D101728), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: palette.strong),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    children: [
                      DocIconTile(type: doc.type, tint: palette.tint, strong: palette.strong),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              doc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.sans(size: 14.5, weight: FontWeight.w700, height: 1.25),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    doc.type.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.sans(size: 11, weight: FontWeight.w500, color: AppColors.textMuted),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Container(width: 3, height: 3, decoration: BoxDecoration(color: AppColors.dotMuted, shape: BoxShape.circle)),
                                const SizedBox(width: 7),
                                Text(fmtDate(doc.expiry), style: AppText.mono(size: 11, weight: FontWeight.w500, color: AppColors.textSlate)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(color: palette.tint, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          doc.daysText(today),
                          style: AppText.sans(size: 10.5, weight: FontWeight.w700, color: palette.fg),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.chevron),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
