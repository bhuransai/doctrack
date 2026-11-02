/// User-configurable app preferences, persisted separately from documents.
class AppSettings {
  final bool notificationsEnabled;
  final List<int> defaultReminderDays;
  final String userName;
  final String themeMode; // AppThemeMode.name: 'system' | 'light' | 'dark'
  final bool onboardingComplete;

  const AppSettings({
    this.notificationsEnabled = true,
    this.defaultReminderDays = const [30, 7, 1],
    this.userName = '',
    this.themeMode = 'system',
    this.onboardingComplete = false,
  });

  factory AppSettings.defaults() => const AppSettings();

  AppSettings copyWith({
    bool? notificationsEnabled,
    List<int>? defaultReminderDays,
    String? userName,
    String? themeMode,
    bool? onboardingComplete,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultReminderDays: defaultReminderDays ?? this.defaultReminderDays,
      userName: userName ?? this.userName,
      themeMode: themeMode ?? this.themeMode,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  Map<String, dynamic> toJson() => {
        'notificationsEnabled': notificationsEnabled,
        'defaultReminderDays': defaultReminderDays,
        'userName': userName,
        'themeMode': themeMode,
        'onboardingComplete': onboardingComplete,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        defaultReminderDays: (json['defaultReminderDays'] as List<dynamic>? ?? const [30, 7, 1])
            .map((e) => e as int)
            .toList(),
        userName: json['userName'] as String? ?? '',
        themeMode: json['themeMode'] as String? ?? 'system',
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      );
}
