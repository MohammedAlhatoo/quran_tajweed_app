import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on the device whether the onboarding has been shown.
class OnboardingStore {
  OnboardingStore(this._preferences);

  static const String _seenKey = 'onboarding_seen';

  final SharedPreferences _preferences;

  bool get isSeen => _preferences.getBool(_seenKey) ?? false;

  /// [isSeen] is true as soon as this is called; the write to the device
  /// finishes later.
  Future<void> markSeen() => _preferences.setBool(_seenKey, true);
}
