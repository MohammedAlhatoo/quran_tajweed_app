import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/features/exams/data/seed/exam_segments_seed.dart';
import 'package:quran_tajweed_app/features/quran/data/repositories/asset_quran_repository.dart';
import 'package:quran_tajweed_app/features/quran/domain/repositories/quran_repository.dart';

/// Checks the examination segments against the bundled Quran data. A segment
/// that does not match is reported, never corrected here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = AssetQuranRepository();

  test('there are 201 examination segments', () {
    expect(examSegmentSeeds, hasLength(201));
  });

  test('every segment lies whole on its recorded page', () async {
    final mismatches = <String>[];

    for (final seed in examSegmentSeeds) {
      final pages = <String>[];
      var matches = true;
      for (var ayah = seed.ayahFrom; ayah <= seed.ayahTo; ayah++) {
        try {
          final found = await repository.ayah(seed.surah, ayah);
          pages.add('$ayah→${found.page}');
          if (found.page != seed.page) matches = false;
        } on QuranDataException {
          pages.add('$ayah→missing');
          matches = false;
        }
      }
      if (!matches) {
        mismatches.add(
          '${seed.id}: recorded page ${seed.page}, '
          'pages in the data (ayah→page): ${pages.join(', ')}',
        );
      }
    }

    expect(
      mismatches,
      isEmpty,
      reason:
          '${mismatches.length} of ${examSegmentSeeds.length} segments do '
          'not match the Quran data:\n${mismatches.join('\n')}',
    );
  });
}
