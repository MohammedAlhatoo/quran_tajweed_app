import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/features/admin/domain/entities/exam_report.dart';
import 'package:quran_tajweed_app/features/admin/presentation/pdf/region_report_pdf.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';

ByteData _font(String asset) =>
    ByteData.sublistView(File(asset).readAsBytesSync());

const _noTotals = ReportTotals(
  exams: 0,
  inProgress: 0,
  awaitingReview: 0,
  approved: 0,
  passed: 0,
  failed: 0,
  averageScore: null,
);

ExamReport _report(int exams, {int squares = 2}) {
  const totals = ReportTotals(
    exams: 3,
    inProgress: 1,
    awaitingReview: 0,
    approved: 2,
    passed: 1,
    failed: 1,
    averageScore: 75,
  );
  return ExamReport(
    scopeName: 'المنطقة الشمالية',
    students: 2,
    totals: exams == 0 ? _noTotals : totals,
    byCourse: exams == 0
        ? const []
        : const [ReportGroup(label: 'دورة أحكام التجويد', totals: totals)],
    byUnit: exams == 0
        ? const []
        : [
            for (var i = 0; i < squares; i++)
              ReportGroup(label: 'المربع ${i + 1}', totals: totals),
            // A square with no approved result has no rate and no average.
            const ReportGroup(label: 'غير معروف', totals: _noTotals),
          ],
    unitTitle: 'حسب المربع',
    exams: [
      for (var i = 0; i < exams; i++)
        switch (i % 3) {
          0 => ReportExam(
            examId: 'e$i',
            studentName: 'أحمد داود آدم',
            courseName: 'دورة أحكام التجويد',
            status: ExamStatus.approved,
            recitationScore: 72,
            theoryScore: 18,
            finalScore: 90,
            passed: true,
            date: DateTime(2026, 9, 1),
          ),
          1 => ReportExam(
            examId: 'e$i',
            studentName: 'Omar زرارة',
            courseName: 'دورة غير متاحة',
            status: ExamStatus.approved,
            recitationScore: 45,
            theoryScore: 15,
            finalScore: 60,
            passed: false,
            date: DateTime(2026, 9, 2),
          ),
          _ => ReportExam(
            examId: 'e$i',
            studentName: 'طالب غير معروف',
            courseName: 'دورة أحكام التجويد',
            status: ExamStatus.inProgress,
          ),
        },
    ],
  );
}

/// Builds the file and returns it with what the PDF library printed, which
/// is where it reports a character that no font can draw.
Future<(Uint8List, List<String>)> _build(
  ExamReport report, {
  String officerName = 'المسؤول خالد',
}) async {
  final printed = <String>[];
  final bytes = await runZoned(
    () => RegionReportPdf.build(
      report: report,
      officerName: officerName,
      generatedAt: DateTime(2026, 10, 6),
      regularFont: _font(RegionReportPdf.regularFontAsset),
      boldFont: _font(RegionReportPdf.boldFontAsset),
    ),
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, line) => printed.add(line),
    ),
  );
  return (bytes, printed);
}

int _pages(Uint8List bytes) =>
    RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)).length;

void main() {
  test('names the file after the day it was created', () {
    expect(
      RegionReportPdf.fileName(DateTime(2026, 3, 7, 23, 59)),
      'region_report_2026-03-07.pdf',
    );
  });

  test('builds a PDF whose every character the Cairo fonts draw', () async {
    final (bytes, printed) = await _build(_report(6));

    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
    // The Arabic text is drawn with the embedded Cairo fonts, and the
    // library reported no character it could not draw.
    expect(latin1.decode(bytes), contains('Cairo'));
    expect(printed, isEmpty);
    // The section by square takes the examinations onto a second page.
    expect(_pages(bytes), 2);
  });

  test('continues the examinations over as many pages as needed', () async {
    final (bytes, printed) = await _build(_report(400));

    expect(printed, isEmpty);
    expect(_pages(bytes), greaterThan(5));
  });

  test('continues a long list of squares on the next page', () async {
    final (bytes, printed) = await _build(_report(3, squares: 80));

    expect(printed, isEmpty);
    expect(_pages(bytes), greaterThan(1));
  });

  test('builds the report of a region without examinations', () async {
    final (bytes, printed) = await _build(_report(0), officerName: '');

    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(printed, isEmpty);
    expect(_pages(bytes), 1);
  });
}
