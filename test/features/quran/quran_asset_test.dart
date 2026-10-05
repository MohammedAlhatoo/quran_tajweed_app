import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/constants/app_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Quran data file is bundled and not empty', () async {
    final data = await rootBundle.loadString(AppAssets.quranData);

    expect(data, isNotEmpty);
  });
}
