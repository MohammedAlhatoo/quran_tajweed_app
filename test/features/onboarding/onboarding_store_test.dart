import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/features/onboarding/data/onboarding_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the onboarding is not seen on a first launch', () async {
    SharedPreferences.setMockInitialValues({});
    final store = OnboardingStore(await SharedPreferences.getInstance());

    expect(store.isSeen, isFalse);
  });

  test('remembers that the onboarding was seen', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final store = OnboardingStore(preferences);
    store.markSeen();
    // Seen at once, before the write finishes.
    expect(store.isSeen, isTrue);

    // A later launch reads the saved value.
    expect(OnboardingStore(preferences).isSeen, isTrue);
  });
}
