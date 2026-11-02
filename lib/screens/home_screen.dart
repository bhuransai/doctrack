import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/doc_store.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/text_utils.dart';
import '../widgets/ad_banner_placeholder.dart';
import '../widgets/document_card.dart';
import '../widgets/summary_card.dart';
import 'document_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onAdd;
  const HomeScreen({super.key, required this.onAdd});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: context.read<DocStore>().searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocStore>(
      builder: (context, store, _) {
        if (store.isEmpty) {
          return _EmptyState(onAdd: widget.onAdd);
        }
        final today = store.today;
        final docs = store.visibleDocs;
        final counts = store.statusCounts;
        final filtering = store.filterStatus != null || store.searchQuery.trim().isNotEmpty;

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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _headerDate(today).toUpperCase(),
                              style: AppText.mono(size: 10, weight: FontWeight.w500, color: AppColors.textFaint, letterSpacing: 1.4),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Documents',
                              style: AppText.sans(size: 27, weight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppColors.inkStrong, borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.center,
                          child: initialsFor(store.settings.userName).isEmpty
                              ? const Icon(Icons.person_outline_rounded, color: Colors.white, size: 19)
                              : Text(initialsFor(store.settings.userName), style: AppText.sans(size: 13, weight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: store.setSearchQuery,
                    style: AppText.sans(size: 13, weight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search by name, number or type',
                      hintStyle: AppText.sans(size: 13, weight: FontWeight.w500, color: AppColors.textDisabled),
                      prefixIcon: Icon(Icons.search_rounded, size: 19, color: AppColors.textFaint),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                store.setSearchQuery('');
                              },
                              child: Icon(Icons.close_rounded, size: 17, color: AppColors.textFaint),
                            ),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surfaceRaised,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderInput)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderInput)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accent)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SummaryCard(
                        count: counts[DocStatus.urgent] ?? 0,
                        label: 'Expired',
                        fg: AppColors.urgentFg,
                        bg: AppColors.urgentTint,
                        line: AppColors.urgentLine,
                        active: store.filterStatus == DocStatus.urgent,
                        onTap: () => store.setFilterStatus(DocStatus.urgent),
                      ),
                      const SizedBox(width: 8),
                      SummaryCard(
                        count: counts[DocStatus.soon] ?? 0,
                        label: 'Expiring soon',
                        fg: AppColors.soonFg,
                        bg: AppColors.soonTint,
                        line: AppColors.soonLine,
                        active: store.filterStatus == DocStatus.soon,
                        onTap: () => store.setFilterStatus(DocStatus.soon),
                      ),
                      const SizedBox(width: 8),
                      SummaryCard(
                        count: counts[DocStatus.safe] ?? 0,
                        label: 'All good',
                        fg: AppColors.safeFg,
                        bg: AppColors.safeTint,
                        line: AppColors.safeLine,
                        active: store.filterStatus == DocStatus.safe,
                        onTap: () => store.setFilterStatus(DocStatus.safe),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: docs.isEmpty
                  ? _NoResults(
                      onClear: () {
                        _searchController.clear();
                        store.setSearchQuery('');
                        if (store.filterStatus != null) store.setFilterStatus(store.filterStatus);
                      },
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                filtering ? '${docs.length} MATCH${docs.length == 1 ? '' : 'ES'}' : 'ALL DOCUMENTS · ${docs.length}',
                                style: AppText.mono(size: 10, weight: FontWeight.w600, color: AppColors.textFaint, letterSpacing: 1.4),
                              ),
                              _SortMenu(current: store.sortOption, onChanged: store.setSortOption),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final doc in docs) ...[
                          DocumentCard(
                            doc: doc,
                            today: today,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => DocumentDetailScreen(docId: doc.id)),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (!filtering) ...[
                          _AddAnotherCard(onAdd: widget.onAdd),
                          const SizedBox(height: 14),
                          // Not const: its colours depend on the live theme
                          // (see AdBannerPlaceholder's doc comment).
                          AdBannerPlaceholder(),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  String _headerDate(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${kMonthNames[d.month - 1]} ${d.year}';
  }
}

class _SortMenu extends StatelessWidget {
  final SortOption current;
  final ValueChanged<SortOption> onChanged;
  const _SortMenu({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      initialValue: current,
      onSelected: onChanged,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        for (final option in SortOption.values)
          PopupMenuItem(
            value: option,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(option.label, style: AppText.sans(size: 13, weight: FontWeight.w600)),
                if (option == current) Icon(Icons.check_rounded, size: 16, color: AppColors.accent),
              ],
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sort: ${current.label}', style: AppText.sans(size: 11, weight: FontWeight.w600, color: AppColors.accent)),
          const SizedBox(width: 2),
          Icon(Icons.expand_more_rounded, size: 15, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final VoidCallback onClear;
  const _NoResults({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 30, color: AppColors.textDisabled),
          const SizedBox(height: 10),
          Text('No documents match', style: AppText.sans(size: 13.5, weight: FontWeight.w700, color: AppColors.textSlate)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onClear,
            child: Text('Clear search & filters', style: AppText.sans(size: 12, weight: FontWeight.w700, color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

class _AddAnotherCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _AddAnotherCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderDashed, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.accentTint, borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: Text('+', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add another document', style: AppText.sans(size: 12.5, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Insurance, RC, ID card or custom', style: AppText.sans(size: 11, weight: FontWeight.w500, color: AppColors.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: AppColors.inkStrong, borderRadius: BorderRadius.circular(9)),
              child: Text('Add', style: AppText.sans(size: 11.5, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 12),
          child: Text('Documents', style: AppText.sans(size: 27, weight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(34, 0, 34, 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Not const: reads theme-dependent colours.
                _EmptyIllustration(),
                const SizedBox(height: 22),
                Text(
                  'Nothing expires on your watch',
                  textAlign: TextAlign.center,
                  style: AppText.sans(size: 21, weight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.2),
                ),
                const SizedBox(height: 9),
                Text(
                  'Add your passport, licence or insurance and DocTrack will remind you 30, 7 and 1 day before it runs out.',
                  textAlign: TextAlign.center,
                  style: AppText.sans(size: 13.5, weight: FontWeight.w500, color: AppColors.textDim, height: 1.6),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.inkStrong,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [BoxShadow(color: Color(0x2E101728), blurRadius: 22, offset: Offset(0, 10))],
                      ),
                      alignment: Alignment.center,
                      child: Text('Add your first document', style: AppText.sans(size: 14.5, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                AdBannerPlaceholder(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyIllustration extends StatelessWidget {
  // Not const — see AdBannerPlaceholder's doc comment: build() reads the
  // live theme, so a const instance would never repaint on a theme switch.
  // ignore: prefer_const_constructors_in_immutables
  _EmptyIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 132,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 14,
            top: 26,
            child: Transform.rotate(
              angle: -0.12,
              child: Container(
                width: 118,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.borderCard),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x0F101728), blurRadius: 18, offset: Offset(0, 8))],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 18,
            child: Transform.rotate(
              angle: 0.07,
              child: Container(
                width: 112,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.borderCard),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x0F101728), blurRadius: 18, offset: Offset(0, 8))],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 10,
            child: Container(
              width: 118,
              height: 82,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.inkStrong,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Color(0x2E101728), blurRadius: 26, offset: Offset(0, 14))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 22, height: 22, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7))),
                      const SizedBox(width: 8),
                      Expanded(child: Container(height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(6)))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(width: 70, height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6))),
                  const Spacer(),
                  Row(
                    children: [
                      Container(width: 26, height: 9, decoration: BoxDecoration(color: AppColors.safeStrong, borderRadius: BorderRadius.circular(5))),
                      const SizedBox(width: 5),
                      Container(width: 16, height: 9, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(13),
                boxShadow: const [BoxShadow(color: Color(0x572F5FE0), blurRadius: 20, offset: Offset(0, 10))],
              ),
              alignment: Alignment.center,
              child: const Text('+', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }
}
