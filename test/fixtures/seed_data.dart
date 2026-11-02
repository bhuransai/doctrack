import 'package:doctrack/models/document.dart';

/// Sample documents used as fixture data for tests (one expired, two
/// expiring soon, two safe), reanchored to whatever "today" a test passes in.
/// Not part of the shipped app — DocTrack starts empty for real users.
List<DocRecord> buildSeedDocuments(DateTime today) {
  DateTime d(int offsetDays) => DateTime(today.year, today.month, today.day)
      .add(Duration(days: offsetDays));

  return [
    DocRecord(
      id: 1,
      type: DocType.vehicleRc,
      name: 'Honda City — RC',
      number: 'KA05 MJ 1123',
      issued: DateTime(today.year - 15, today.month, today.day),
      expiry: d(-8),
    ),
    DocRecord(
      id: 2,
      type: DocType.drivingLicence,
      name: 'Driving licence',
      number: 'KA05 2019 0084512',
      issued: DateTime(today.year - 7, 2, 11),
      expiry: d(15),
    ),
    DocRecord(
      id: 3,
      type: DocType.insurance,
      name: 'Car insurance — comprehensive',
      number: 'POL-88431299',
      issued: DateTime(today.year - 1, 8, 26),
      expiry: d(30),
    ),
    DocRecord(
      id: 4,
      type: DocType.idCard,
      name: 'Employee ID — Northwind',
      number: 'NW-4471',
      issued: DateTime(today.year - 3, 1, 5),
      expiry: DateTime(today.year + 1, 1, 5),
    ),
    DocRecord(
      id: 5,
      type: DocType.passport,
      name: 'Passport — Aarav Rao',
      number: 'Z4482910',
      issued: DateTime(today.year - 5, 3, 14),
      expiry: DateTime(today.year + 5, 3, 14),
    ),
  ];
}
