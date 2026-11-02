/// Up to 2 uppercase initials from a display name, for avatar chips.
/// Falls back to an empty string when no name is set (callers should show a
/// generic person icon instead in that case).
String initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

/// First name (or the given name as-is if it's a single word), for greetings
/// like "Hi Aarav". Empty when no name is set.
String firstNameOf(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).first;
}
