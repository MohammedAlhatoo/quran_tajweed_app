import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_segment.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/exams_repository.dart';
import 'package:quran_tajweed_app/features/exams/presentation/pages/exam_segment_page.dart';
import 'package:quran_tajweed_app/features/exams/presentation/state/exam_cubit.dart';
import 'package:quran_tajweed_app/features/exams/presentation/widgets/mushaf_frame.dart';
import 'package:quran_tajweed_app/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran_tajweed_app/features/quran/domain/repositories/quran_repository.dart';
import 'package:quran_tajweed_app/features/quran/presentation/widgets/segment_text.dart';

/// Submitted, so the screen shows the segment without the recording bar and
/// the questions, which have their own cubits and tests.
const _exam = Exam(
  id: 'exam-1',
  studentId: 'uid-1',
  courseId: 'course-1',
  segmentId: 'segment-1',
  status: ExamStatus.submitted,
  mosqueId: 'mosque-1',
  squareId: 'square-1',
  regionId: 'region-1',
);

const _segment = ExamSegment(
  id: 'segment-1',
  surah: 2,
  ayahFrom: 1,
  ayahTo: 3,
  page: 2,
  ruleIds: ['rule-a'],
  courseIds: ['course-1'],
  ruleDensity: 1,
  isActive: true,
);

class _FakeExamsRepository implements ExamsRepository {
  @override
  Future<Exam?> fetchExam(String examId) async => _exam;

  @override
  Future<ExamSegment?> fetchSegment(String segmentId) async => _segment;

  @override
  Future<Exam> startExam({
    required AppUser student,
    required String courseId,
  }) => throw const AppFailure('not used');

  @override
  Future<List<Exam>> fetchStudentExams(String studentId) async => const [];
}

class _FakeQuranRepository implements QuranRepository {
  QuranDataException? failure;

  @override
  Future<List<QuranAyah>> ayahsOf(int surah, int from, int to) async {
    if (failure case final failure?) throw failure;
    return [
      for (var ayah = from; ayah <= to; ayah++)
        QuranAyah(
          surah: surah,
          ayah: ayah,
          page: 2,
          juz: 1,
          lineStart: 2 + ayah,
          lineEnd: 2 + ayah,
          text: 'text $surah:$ayah',
          textEmlaey: 'plain $surah:$ayah',
        ),
    ];
  }

  @override
  Future<QuranAyah> ayah(int surah, int ayah) => throw UnimplementedError();

  @override
  Future<List<QuranAyah>> ayahsOfPage(int page) => throw UnimplementedError();
}

Future<void> _pump(WidgetTester tester, _FakeQuranRepository quran) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider(
          create: (_) =>
              ExamCubit(_FakeExamsRepository(), quran, 'exam-1')..load(),
          child: const ExamSegmentPage(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // The Cairo font is not fetched in a test.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows the ayahs of the segment inside the Mushaf frame', (
    tester,
  ) async {
    await _pump(tester, _FakeQuranRepository());

    final text = tester.widget<SegmentText>(
      find.descendant(
        of: find.byType(MushafFrame),
        matching: find.byType(SegmentText),
      ),
    );
    expect(
      [for (final ayah in text.ayahs) ayah.text],
      ['text 2:1', 'text 2:2', 'text 2:3'],
    );
    expect(find.textContaining('نص المقطع غير متاح بعد'), findsNothing);
    expect(tester.widget<MushafFrame>(find.byType(MushafFrame)).page, 2);
  });

  testWidgets('shows a message and a retry when the Quran data fails', (
    tester,
  ) async {
    final quran = _FakeQuranRepository()
      ..failure = const QuranDataException('no file');
    await _pump(tester, quran);

    expect(tester.takeException(), isNull);
    expect(find.text('تعذّر تحميل نص المقطع.'), findsOneWidget);
    expect(find.byType(SegmentText), findsNothing);

    quran.failure = null;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SegmentText), findsOneWidget);
    expect(find.text('تعذّر تحميل نص المقطع.'), findsNothing);
  });
}
