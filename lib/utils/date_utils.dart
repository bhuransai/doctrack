const List<String> kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> kMonthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> kWeekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

String fmtDate(DateTime d) => '${d.day} ${kMonthShort[d.month - 1]} ${d.year}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// [d]'s date moved back [n] calendar days. Built from date fields rather
/// than subtracting a [Duration], which lands on the wrong day when the span
/// crosses a daylight-saving change (a 23- or 25-hour day).
DateTime shiftDays(DateTime d, int n) => DateTime(d.year, d.month, d.day - n);

/// Whole calendar days from [b] to [a]. Compared as UTC dates so a
/// daylight-saving change in between can't make it come out one short.
int daysBetween(DateTime a, DateTime b) => DateTime.utc(a.year, a.month, a.day)
    .difference(DateTime.utc(b.year, b.month, b.day))
    .inDays;
