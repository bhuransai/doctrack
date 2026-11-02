import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';

enum DocType { passport, drivingLicence, insurance, vehicleRc, idCard, custom }

extension DocTypeMeta on DocType {
  String get label {
    switch (this) {
      case DocType.passport:
        return 'Passport';
      case DocType.drivingLicence:
        return 'Driving licence';
      case DocType.insurance:
        return 'Insurance';
      case DocType.vehicleRc:
        return 'Vehicle RC';
      case DocType.idCard:
        return 'ID card';
      case DocType.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case DocType.passport:
        return Icons.menu_book_rounded;
      case DocType.drivingLicence:
        return Icons.badge_rounded;
      case DocType.insurance:
        return Icons.verified_user_rounded;
      case DocType.vehicleRc:
        return Icons.directions_car_filled_rounded;
      case DocType.idCard:
        return Icons.contact_page_rounded;
      case DocType.custom:
        return Icons.insert_drive_file_rounded;
    }
  }
}

/// A single tracked document. [expiry] is the only required field — everything
/// else is optional so adding a document takes under 15 seconds.
class DocRecord {
  final int id;
  final DocType type;
  final String name;
  final String number;
  final DateTime issued;
  final DateTime expiry;
  final String? photoPath;
  final List<int> reminderDays;
  final bool remindersEnabled;

  const DocRecord({
    required this.id,
    required this.type,
    required this.name,
    this.number = '—',
    required this.issued,
    required this.expiry,
    this.photoPath,
    this.reminderDays = const [30, 7, 1],
    this.remindersEnabled = true,
  });

  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  DocRecord copyWith({
    DocType? type,
    String? name,
    String? number,
    DateTime? issued,
    DateTime? expiry,
    String? photoPath,
    bool clearPhoto = false,
    List<int>? reminderDays,
    bool? remindersEnabled,
  }) {
    return DocRecord(
      id: id,
      type: type ?? this.type,
      name: name ?? this.name,
      number: number ?? this.number,
      issued: issued ?? this.issued,
      expiry: expiry ?? this.expiry,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      reminderDays: reminderDays ?? this.reminderDays,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }

  int daysLeft(DateTime today) => daysBetween(expiry, today);

  DocStatus status(DateTime today) {
    final dl = daysLeft(today);
    if (dl < 0) return DocStatus.urgent;
    if (dl <= 30) return DocStatus.soon;
    return DocStatus.safe;
  }

  StatusPalette palette(DateTime today) => kStatusPalettes[status(today)]!;

  String daysText(DateTime today) {
    final dl = daysLeft(today);
    if (dl < 0) return '${dl.abs()}d ago';
    if (dl == 0) return 'Today';
    return '${dl}d left';
  }

  String daysLong(DateTime today) {
    final dl = daysLeft(today);
    if (dl < 0) return 'Expired ${dl.abs()} days ago';
    return '$dl days remaining';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'number': number,
        'issued': issued.toIso8601String(),
        'expiry': expiry.toIso8601String(),
        'photoPath': photoPath,
        'reminderDays': reminderDays,
        'remindersEnabled': remindersEnabled,
      };

  factory DocRecord.fromJson(Map<String, dynamic> json) {
    return DocRecord(
      id: json['id'] as int,
      type: DocType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DocType.custom,
      ),
      name: json['name'] as String,
      number: json['number'] as String? ?? '—',
      issued: DateTime.parse(json['issued'] as String),
      expiry: DateTime.parse(json['expiry'] as String),
      photoPath: json['photoPath'] as String?,
      reminderDays: (json['reminderDays'] as List<dynamic>? ?? const [30, 7, 1])
          .map((e) => e as int)
          .toList(),
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
    );
  }
}
