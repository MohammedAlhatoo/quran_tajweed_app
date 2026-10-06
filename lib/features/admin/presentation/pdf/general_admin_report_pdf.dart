import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/exam_report.dart';
import 'square_report_pdf.dart';

/// Builds the PDF file of the report of the whole system: its header, the
/// totals, the breakdown by region and by course and the examinations, over
/// as many pages as needed.
///
/// It is laid out like [SquareReportPdf], which is left as it is: a label and
/// its number or date are always separate texts, so a line never mixes
/// right-to-left and left-to-right runs.
abstract final class GeneralAdminReportPdf {
  static const String regularFontAsset = SquareReportPdf.regularFontAsset;
  static const String boldFontAsset = SquareReportPdf.boldFontAsset;

  static const _primary = PdfColor.fromInt(0xFF0F8A5F);
  static const _title = PdfColor.fromInt(0xFF1F2937);
  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _danger = PdfColor.fromInt(0xFFEF4444);
  static const _line = PdfColor.fromInt(0xFFD1D5DB);
  static const _headerFill = PdfColor.fromInt(0xFFE7F5EF);
  static const _stripe = PdfColor.fromInt(0xFFF9FAFB);

  static const _empty = '—';

  static String _date(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  static String _number(double? value, {String suffix = ''}) =>
      value == null ? _empty : '${value.toStringAsFixed(1)}$suffix';

  static String fileName(DateTime generatedAt) =>
      'general_admin_report_${_date(generatedAt)}.pdf';

  /// [regularFont] and [boldFont] are the bytes of the Cairo font files.
  static Future<Uint8List> build({
    required ExamReport report,
    required String userName,
    required DateTime generatedAt,
    required ByteData regularFont,
    required ByteData boldFont,
  }) {
    final generatedOn = _date(generatedAt);
    final document = pw.Document()
      ..addPage(
        pw.MultiPage(
          // The default of 20 pages is too few for the whole system.
          maxPages: 1000,
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            textDirection: pw.TextDirection.rtl,
            theme: pw.ThemeData.withFont(
              base: pw.Font.ttf(regularFont),
              bold: pw.Font.ttf(boldFont),
            ),
          ),
          footer: (context) => _footer(context, generatedOn),
          build: (context) => [
            _header(userName, generatedOn),
            _sectionTitle('الملخص الإحصائي'),
            _summary(report),
            _sectionTitle('الإحصائيات حسب المنطقة'),
            if (report.byUnit.isEmpty)
              _note('لا توجد مناطق في هذا التقرير')
            else
              _groups('المنطقة', report.byUnit),
            _sectionTitle('الإحصائيات حسب الدورة'),
            if (report.byCourse.isEmpty)
              _note('لا توجد دورات في هذا التقرير')
            else
              _groups('الدورة', report.byCourse),
            _sectionTitle('الامتحانات'),
            if (report.exams.isEmpty)
              _note('لا توجد امتحانات في النظام')
            else
              _exams(report.exams),
          ],
        ),
      );
    return document.save();
  }

  static pw.Widget _text(
    String text, {
    double size = 9,
    bool bold = false,
    bool ltr = false,
    PdfColor color = _title,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Text(
      text,
      textAlign: align,
      textDirection: ltr ? pw.TextDirection.ltr : pw.TextDirection.rtl,
      style: pw.TextStyle(
        fontSize: size,
        color: color,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    );
  }

  static pw.Widget _cell(pw.Widget child) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: child,
  );

  /// A table whose [widths] and rows are given in reading order, from the
  /// right. `pw.Table` lays its columns out from the left whatever the text
  /// direction is, so [_row] and this reverse them.
  static pw.Widget _table({
    required List<double> widths,
    required List<pw.TableRow> rows,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      columnWidths: {
        for (final (index, width) in widths.reversed.indexed)
          index: pw.FlexColumnWidth(width),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  static pw.TableRow _row(
    List<pw.Widget> cells, {
    bool repeat = false,
    PdfColor? fill,
  }) {
    return pw.TableRow(
      repeat: repeat,
      decoration: fill == null ? null : pw.BoxDecoration(color: fill),
      children: cells.reversed.toList(),
    );
  }

  /// The row of [userName] is left out when the name is not known.
  static pw.Widget _header(String userName, String generatedOn) {
    pw.TableRow row(String label, String value, {bool ltr = false}) {
      return _row([
        _cell(_text(label, color: _muted, align: pw.TextAlign.right)),
        _cell(_text(value, bold: true, ltr: ltr, align: pw.TextAlign.right)),
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _text('تقرير أداء النظام', size: 20, bold: true, color: _primary),
        pw.SizedBox(height: 10),
        _table(
          widths: const [1, 3],
          rows: [
            if (userName.trim().isNotEmpty) row('المدير العام', userName),
            row('تاريخ إنشاء التقرير', generatedOn, ltr: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
    child: _text(text, size: 13, bold: true, align: pw.TextAlign.right),
  );

  static pw.Widget _note(String text) =>
      _text(text, color: _muted, align: pw.TextAlign.right);

  static pw.Widget _summary(ExamReport report) {
    final totals = report.totals;
    final tiles = [
      ('الطلاب', '${report.students}'),
      ('الامتحانات', '${totals.exams}'),
      ('قيد التنفيذ', '${totals.inProgress}'),
      ('بانتظار المراجعة', '${totals.awaitingReview}'),
      ('المعتمدة', '${totals.approved}'),
      ('الناجحة', '${totals.passed}'),
      ('الراسبة', '${totals.failed}'),
      ('نسبة النجاح', _number(totals.passRate, suffix: '%')),
      ('متوسط الدرجة', _number(totals.averageScore)),
    ];

    return _table(
      widths: const [1, 1, 1],
      rows: [
        for (var start = 0; start < tiles.length; start += 3)
          _row([
            for (final (label, value) in tiles.skip(start).take(3))
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Column(
                  children: [
                    _text(
                      value,
                      size: 15,
                      bold: true,
                      ltr: true,
                      color: _primary,
                    ),
                    _text(label, size: 8, color: _muted),
                  ],
                ),
              ),
          ]),
      ],
    );
  }

  static pw.Widget _head(String label, [String? unit]) => _cell(
    pw.Column(
      children: [
        _text(label, size: 8, bold: true),
        if (unit != null) _text(unit, size: 8, bold: true, ltr: true),
      ],
    ),
  );

  static pw.Widget _value(String text) => _cell(_text(text, ltr: true));

  static pw.Widget _name(String text) =>
      _cell(_text(text, align: pw.TextAlign.right));

  /// The totals of each region or course, under a first column named
  /// [unit].
  static pw.Widget _groups(String unit, List<ReportGroup> groups) {
    return _table(
      widths: const [3, 1.2, 1.2, 1.2, 1.2, 1.2, 1.2, 1.2],
      rows: [
        _row(repeat: true, fill: _headerFill, [
          _head(unit),
          _head('الامتحانات'),
          _head('بانتظار المراجعة'),
          _head('المعتمدة'),
          _head('ناجح'),
          _head('راسب'),
          _head('نسبة النجاح'),
          _head('متوسط الدرجة'),
        ]),
        for (final ReportGroup(:label, :totals) in groups)
          _row([
            _name(label),
            _value('${totals.exams}'),
            _value('${totals.awaitingReview}'),
            _value('${totals.approved}'),
            _value('${totals.passed}'),
            _value('${totals.failed}'),
            _value(_number(totals.passRate, suffix: '%')),
            _value(_number(totals.averageScore)),
          ]),
      ],
    );
  }

  static pw.Widget _exams(List<ReportExam> exams) {
    pw.Widget result(bool? passed) => switch (passed) {
      null => _value(_empty),
      true => _cell(_text('ناجح', bold: true, color: _primary)),
      false => _cell(_text('راسب', bold: true, color: _danger)),
    };

    return _table(
      widths: const [0.7, 3, 2.4, 1.7, 2, 1.2, 1.2, 1.2, 1.2],
      rows: [
        // Repeated at the top of every page the table continues on.
        _row(repeat: true, fill: _headerFill, [
          _head('م'),
          _head('الطالب'),
          _head('الدورة'),
          _head('التاريخ'),
          _head('الحالة'),
          _head('التلاوة', '/80'),
          _head('النظري', '/20'),
          _head('النهائي', '/100'),
          _head('النتيجة'),
        ]),
        for (final (index, exam) in exams.indexed)
          _row(fill: index.isOdd ? _stripe : null, [
            _value('${index + 1}'),
            _name(exam.studentName),
            _name(exam.courseName),
            _value(exam.date == null ? _empty : _date(exam.date!)),
            _cell(_text(exam.status.label)),
            _value('${exam.recitationScore ?? _empty}'),
            _value('${exam.theoryScore ?? _empty}'),
            _value('${exam.finalScore ?? _empty}'),
            result(exam.passed),
          ]),
      ],
    );
  }

  static pw.Widget _footer(pw.Context context, String generatedOn) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              _text('تاريخ إنشاء التقرير', size: 8, color: _muted),
              pw.SizedBox(width: 4),
              _text(generatedOn, size: 8, ltr: true, color: _muted),
            ],
          ),
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              _text('صفحة', size: 8, color: _muted),
              pw.SizedBox(width: 4),
              _text(
                '${context.pageNumber} / ${context.pagesCount}',
                size: 8,
                ltr: true,
                color: _muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
