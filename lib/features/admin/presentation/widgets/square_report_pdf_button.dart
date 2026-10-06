import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../domain/entities/exam_report.dart';
import '../pdf/square_report_pdf.dart';

/// Saves [report] as a PDF file through the share sheet of the system.
class SquareReportPdfButton extends StatefulWidget {
  const SquareReportPdfButton({super.key, required this.report});

  final ExamReport report;

  @override
  State<SquareReportPdfButton> createState() => _SquareReportPdfButtonState();
}

class _SquareReportPdfButtonState extends State<SquareReportPdfButton> {
  bool _isExporting = false;

  Future<void> _downloadPdf() async {
    if (_isExporting) return;
    final authState = context.read<AuthCubit>().state;
    final supervisorName = authState is AuthAuthenticated
        ? authState.user.name
        : '';
    setState(() => _isExporting = true);
    try {
      final generatedAt = DateTime.now();
      final bytes = await SquareReportPdf.build(
        report: widget.report,
        supervisorName: supervisorName,
        generatedAt: generatedAt,
        regularFont: await rootBundle.load(SquareReportPdf.regularFontAsset),
        boldFont: await rootBundle.load(SquareReportPdf.boldFontAsset),
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: SquareReportPdf.fileName(generatedAt),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppButton(
        label: 'تحميل PDF',
        isLoading: _isExporting,
        onPressed: _downloadPdf,
      ),
    );
  }
}
