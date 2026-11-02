import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/document.dart';
import '../services/photo_service.dart';
import '../state/doc_store.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';

/// Add-a-document form. Pass [existing] to reuse this screen for editing —
/// the header, save button and submit action adapt accordingly.
class AddDocumentScreen extends StatefulWidget {
  final DocRecord? existing;
  const AddDocumentScreen({super.key, this.existing});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _photoService = PhotoService();

  late DocType _type;
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  DateTime? _expiry;
  late DateTime _issued;
  String? _photoPath;
  late final String? _originalPhotoPath;
  bool _photoBusy = false;
  bool _saved = false;
  late Set<int> _reminders;
  late DateTime _month;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final store = context.read<DocStore>();
    final today = store.today;
    final existing = widget.existing;

    _type = existing?.type ?? DocType.insurance;
    _nameController.text = existing?.name ?? '';
    _numberController.text = (existing != null && existing.number != '—') ? existing.number : '';
    _expiry = existing?.expiry;
    _issued = existing?.issued ?? today;
    _photoPath = existing?.photoPath;
    _originalPhotoPath = existing?.photoPath;
    _reminders = (existing?.reminderDays ?? store.settings.defaultReminderDays).toSet();
    _month = DateTime((_expiry ?? today).year, (_expiry ?? today).month, 1);
  }

  @override
  void dispose() {
    // Leaving without saving: a photo picked in this session was copied into
    // app storage but never attached to a document, so remove it.
    final picked = _photoPath;
    if (!_saved && picked != null && picked != _originalPhotoPath) {
      unawaited(_photoService.delete(picked));
    }
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  bool get _ready => _expiry != null && _nameController.text.trim().isNotEmpty;

  Future<void> _pickIssuedDate(DateTime today) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issued,
      firstDate: DateTime(today.year - 50),
      lastDate: today,
    );
    if (picked != null) setState(() => _issued = picked);
  }

  Future<void> _pickPhoto() async {
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
            if (_photoPath != null)
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
    if (action == null || !mounted) return;
    // Only delete the outgoing file immediately if it was picked earlier in
    // this same session (never persisted) — the original document's photo,
    // if any, is left alone until Save actually commits the change.
    final oldPath = _photoPath;
    final oldPathIsTransient = oldPath != null && oldPath != _originalPhotoPath;
    if (action == 'remove') {
      setState(() => _photoPath = null);
      if (oldPathIsTransient) unawaited(_photoService.delete(oldPath));
      return;
    }

    setState(() => _photoBusy = true);
    try {
      final path = await _photoService.pickAndStore(fromCamera: action == 'camera');
      if (path != null && mounted) {
        setState(() => _photoPath = path);
        if (oldPathIsTransient) unawaited(_photoService.delete(oldPath));
      } else if (path != null) {
        // Screen closed while the picker was open — nothing will keep it.
        unawaited(_photoService.delete(path));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access camera/gallery.')),
        );
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  void _save() {
    if (!_ready) return;
    final store = context.read<DocStore>();
    final reminderDays = _reminders.toList()..sort((a, b) => b.compareTo(a));
    _saved = true;

    if (_isEdit) {
      store.updateDocument(widget.existing!.copyWith(
        type: _type,
        name: _nameController.text,
        number: _numberController.text.trim().isEmpty ? '—' : _numberController.text.trim(),
        issued: _issued,
        expiry: _expiry,
        photoPath: _photoPath,
        clearPhoto: _photoPath == null,
        reminderDays: reminderDays,
      ));
      if (_originalPhotoPath != null && _originalPhotoPath != _photoPath) {
        unawaited(_photoService.delete(_originalPhotoPath));
      }
    } else {
      store.addDocument(
        type: _type,
        name: _nameController.text,
        number: _numberController.text,
        issued: _issued,
        expiry: _expiry!,
        photoPath: _photoPath,
        reminderDays: reminderDays,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final today = context.watch<DocStore>().today;
    final saveColor = _ready ? AppColors.accent : AppColors.chevron;
    final saveBg = _ready ? AppColors.inkStrong : AppColors.chevron;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 14),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: AppText.sans(size: 13.5, weight: FontWeight.w600, color: AppColors.textMuted)),
                ),
                Text(_isEdit ? 'Edit document' : 'Add document', style: AppText.sans(size: 15.5, weight: FontWeight.w700)),
                GestureDetector(
                  onTap: _save,
                  child: Text('Save', style: AppText.sans(size: 13.5, weight: FontWeight.w700, color: saveColor)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
              children: [
                _SectionLabel('1 · DOCUMENT TYPE'),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.05,
                  children: [
                    for (final t in DocType.values) _TypeTile(type: t, selected: t == _type, onTap: () => setState(() => _type = t)),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionLabel('2 · NAME'),
                const SizedBox(height: 10),
                _TextField(
                  controller: _nameController,
                  hint: 'e.g. Passport — Aarav Rao',
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _SectionLabel('3 · DOCUMENT NUMBER '),
                    Text('OPTIONAL', style: AppText.mono(size: 10, weight: FontWeight.w600, color: AppColors.chevron, letterSpacing: 1.4)),
                  ],
                ),
                const SizedBox(height: 10),
                _TextField(
                  controller: _numberController,
                  hint: 'e.g. Z4482910',
                  mono: true,
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _SectionLabel('4 · ISSUED ON '),
                        Text('OPTIONAL', style: AppText.mono(size: 10, weight: FontWeight.w600, color: AppColors.chevron, letterSpacing: 1.4)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _pickIssuedDate(today),
                      child: Row(
                        children: [
                          Text(fmtDate(_issued), style: AppText.mono(size: 12, weight: FontWeight.w600, color: AppColors.ink)),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_calendar_outlined, size: 14, color: AppColors.accent),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionLabel('5 · EXPIRY DATE'),
                    Text(
                      _expiry != null ? fmtDate(_expiry!) : 'not set',
                      style: AppText.mono(size: 12, weight: FontWeight.w600, color: _expiry != null ? AppColors.ink : AppColors.chevron),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _Calendar(
                  month: _month,
                  today: today,
                  selected: _expiry,
                  onPrev: () => setState(() => _month = DateTime(_month.year, _month.month - 1, 1)),
                  onNext: () => setState(() => _month = DateTime(_month.year, _month.month + 1, 1)),
                  onPick: (d) => setState(() => _expiry = d),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _SectionLabel('6 · PHOTO '),
                    Text('OPTIONAL', style: AppText.mono(size: 10, weight: FontWeight.w600, color: AppColors.chevron, letterSpacing: 1.4)),
                  ],
                ),
                const SizedBox(height: 10),
                _PhotoTile(photoPath: _photoPath, busy: _photoBusy, onTap: _pickPhoto),
                const SizedBox(height: 22),
                _SectionLabel('7 · REMIND ME BEFORE'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final n in [30, 7, 1]) ...[
                      Expanded(
                        child: _ReminderChip(
                          n: n,
                          on: _reminders.contains(n),
                          onTap: () => setState(() {
                            if (_reminders.contains(n)) {
                              _reminders.remove(n);
                            } else {
                              _reminders.add(n);
                            }
                          }),
                        ),
                      ),
                      if (n != 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: saveBg, borderRadius: BorderRadius.circular(15)),
                    alignment: Alignment.center,
                    child: Text(_isEdit ? 'Save changes' : 'Save document', style: AppText.sans(size: 14.5, weight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool mono;
  final VoidCallback? onChanged;
  const _TextField({required this.controller, required this.hint, this.mono = false, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final style = mono
        ? AppText.mono(size: 13.5, weight: FontWeight.w600)
        : AppText.sans(size: 14, weight: FontWeight.w600);
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged?.call(),
      style: style,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.sans(size: 14, weight: FontWeight.w600, color: AppColors.textDisabled),
        filled: true,
        fillColor: AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: AppColors.borderInput, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: AppColors.borderInput, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: AppColors.accent, width: 1.5)),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  final DocType type;
  final bool selected;
  final VoidCallback onTap;
  const _TypeTile({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 13, 8, 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          border: Border.all(color: selected ? AppColors.accent : AppColors.borderCard, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type.icon, size: 22, color: selected ? AppColors.accent : AppColors.textFaint),
            const SizedBox(height: 8),
            Text(
              type.label,
              textAlign: TextAlign.center,
              style: AppText.sans(size: 11, weight: FontWeight.w600, color: selected ? AppColors.accent : AppColors.textSlate, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  final DateTime month;
  final DateTime today;
  final DateTime? selected;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onPick;

  const _Calendar({
    required this.month,
    required this.today,
    required this.selected,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final lead = (first.weekday + 6) % 7; // Monday-first grid
    final count = DateTime(month.year, month.month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.borderCard),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundIconButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
              Text('${kMonthNames[month.month - 1]} ${month.year}', style: AppText.sans(size: 13.5, weight: FontWeight.w700)),
              _RoundIconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final w in kWeekdayInitials)
                Expanded(
                  child: Center(child: Text(w, style: AppText.mono(size: 9.5, weight: FontWeight.w600, color: AppColors.textDisabled))),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              for (var i = 0; i < lead; i++) const SizedBox.shrink(),
              for (var n = 1; n <= count; n++) _dayCell(n),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayCell(int n) {
    final date = DateTime(month.year, month.month, n);
    final isSelected = selected != null && dateOnly(selected!) == dateOnly(date);
    final past = daysBetween(date, today) < 0;

    return GestureDetector(
      onTap: past ? null : () => onPick(date),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          '$n',
          style: AppText.mono(
            size: 12.5,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (past ? AppColors.chevron : AppColors.ink),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderCard),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: AppColors.textSlate),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String? photoPath;
  final bool busy;
  final VoidCallback onTap;
  const _PhotoTile({required this.photoPath, required this.busy, required this.onTap});

  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final line = hasPhoto ? AppColors.accent : AppColors.borderDashed;
    final bg = hasPhoto ? AppColors.accentSoft : AppColors.surfaceRaised;
    final tile = hasPhoto ? AppColors.accentTint : AppColors.borderFaint;
    final iconColor = hasPhoto ? AppColors.accent : AppColors.textDisabled;

    String subtitle = 'Camera or files · stays on device';
    if (hasPhoto) {
      try {
        final bytes = File(photoPath!).lengthSync();
        subtitle = 'Stored on device only · ${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      } catch (_) {
        subtitle = 'Stored on device only';
      }
    }

    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: line, width: 1.5, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 38,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: tile, borderRadius: BorderRadius.circular(9)),
              alignment: Alignment.center,
              child: hasPhoto
                  ? Image.file(File(photoPath!), fit: BoxFit.cover, width: 52, height: 38)
                  : Icon(Icons.camera_alt_outlined, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasPhoto ? 'Photo attached' : 'Attach a photo of the document',
                    style: AppText.sans(size: 13, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppText.sans(size: 11.5, weight: FontWeight.w500, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (busy)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Text(hasPhoto ? 'Change' : 'Upload', style: AppText.sans(size: 11.5, weight: FontWeight.w700, color: AppColors.accent)),
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
