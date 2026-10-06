import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../exams/presentation/state/exam_result_cubit.dart';
import '../../domain/entities/certificate.dart';

/// The certificate of one passed examination, shown to its student.
class CertificatePage extends StatelessWidget {
  const CertificatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final studentName = authState is AuthAuthenticated
        ? authState.user.name
        : '';

    return Scaffold(
      backgroundColor: AppColors.mushafBackground,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('الشهادة'),
      ),
      body: BlocBuilder<ExamResultCubit, ExamResultState>(
        builder: (context, state) => switch (state) {
          ExamResultLoading() => const AppLoadingView(),
          ExamResultError(:final message) => AppMessageView(
            message: message,
            onRetry: context.read<ExamResultCubit>().load,
          ),
          ExamResultLoaded(:final certificate?, :final course) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _DownloadableCertificate(
                certificate: certificate,
                studentName: studentName,
                courseName: course?.name ?? 'التجويد',
              ),
            ),
          ),
          ExamResultLoaded() => const AppMessageView(
            message: 'لا توجد شهادة لهذا الاختبار.',
          ),
        },
      ),
    );
  }
}

/// The certificate sheet with the button that saves it as a PDF file.
class _DownloadableCertificate extends StatefulWidget {
  const _DownloadableCertificate({
    required this.certificate,
    required this.studentName,
    required this.courseName,
  });

  final Certificate certificate;
  final String studentName;
  final String courseName;

  @override
  State<_DownloadableCertificate> createState() =>
      _DownloadableCertificateState();
}

class _DownloadableCertificateState extends State<_DownloadableCertificate> {
  final _sheetKey = GlobalKey();
  bool _isExporting = false;

  /// Captures the sheet as an image, puts it on one PDF page and opens the
  /// share sheet of the system.
  Future<void> _downloadPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final boundary =
          _sheetKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      final sheet = pw.MemoryImage(data!.buffer.asUint8List());
      final document = pw.Document()
        ..addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (_) =>
                pw.Center(child: pw.Image(sheet, fit: pw.BoxFit.contain)),
          ),
        );

      await Printing.sharePdf(
        bytes: await document.save(),
        filename: 'certificate_${widget.certificate.certificateNumber}.pdf',
      );
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'تعذّر إنشاء ملف PDF.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: _sheetKey,
          child: _CertificateSheet(
            certificate: widget.certificate,
            studentName: widget.studentName,
            courseName: widget.courseName,
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'تحميل PDF',
          isLoading: _isExporting,
          onPressed: _downloadPdf,
        ),
      ],
    );
  }
}

class _CertificateSheet extends StatelessWidget {
  const _CertificateSheet({
    required this.certificate,
    required this.studentName,
    required this.courseName,
  });

  final Certificate certificate;
  final String studentName;
  final String courseName;

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final issuedAt = certificate.issuedAt;
    TextStyle text(double size, FontWeight weight, Color color) =>
        AppTextStyles.cairo(
          size: size,
          weight: weight,
          color: color,
          lineHeight: size * 1.7,
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.mushafPage,
        border: Border.all(color: AppColors.mushafBorder, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.mushafInnerBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              size: 48,
              color: AppColors.mushafCorner,
            ),
            const SizedBox(height: 8),
            Text(
              'شهادة اجتياز',
              style: text(22, FontWeight.w700, AppColors.examHeader),
            ),
            Text(
              AppConstants.appName,
              textAlign: TextAlign.center,
              style: text(12, FontWeight.w600, AppColors.mushafPageNumber),
            ),
            const SizedBox(height: 20),
            Text(
              'تشهد المنصة بأن الطالب',
              style: text(13, FontWeight.w500, AppColors.bodyText),
            ),
            Text(
              studentName,
              textAlign: TextAlign.center,
              style: text(20, FontWeight.w700, AppColors.ink),
            ),
            Text(
              'قد اجتاز اختبار دورة',
              style: text(13, FontWeight.w500, AppColors.bodyText),
            ),
            Text(
              courseName,
              textAlign: TextAlign.center,
              style: text(18, FontWeight.w700, AppColors.examHeader),
            ),
            const SizedBox(height: 12),
            Text(
              'بدرجة ${certificate.finalScore} من 100',
              style: text(15, FontWeight.w700, AppColors.optionSelectedText),
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.mushafOutline),
            const SizedBox(height: 12),
            Text(
              'رقم الشهادة',
              style: text(11, FontWeight.w500, AppColors.muted),
            ),
            Text(
              certificate.certificateNumber,
              textDirection: TextDirection.ltr,
              style: text(14, FontWeight.w700, AppColors.title),
            ),
            if (issuedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'تاريخ الإصدار',
                style: text(11, FontWeight.w500, AppColors.muted),
              ),
              Text(
                _formatDate(issuedAt),
                textDirection: TextDirection.ltr,
                style: text(14, FontWeight.w700, AppColors.title),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
