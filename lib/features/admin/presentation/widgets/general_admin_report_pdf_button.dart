import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../domain/entities/exam_report.dart';
import '../pdf/general_admin_report_pdf.dart';

/// Saves [report], the report of the whole system, as a PDF file through the
/// share sheet of the system.
class GeneralAdminReportPdfButton extends StatefulWidget {
  const GeneralAdminReportPdfButton({super.key, required this.report});

  final ExamReport report;

  @override
  State<GeneralAdminReportPdfButton> createState() =>
      _GeneralAdminReportPdfButtonState();
}

class _GeneralAdminReportPdfButtonState
    extends State<GeneralAdminReportPdfButton> {
  bool _isExporting = false;

  Future<void> _downloadPdf() async {
    if (_isExporting) return;
    final authState = context.read<AuthCubit>().state;
    final userName = authState is AuthAuthenticated ? authState.user.name : '';
    setState(() => _isExporting = true);
    try {
      final generatedAt = DateTime.now();
      final bytes = await GeneralAdminReportPdf.build(
        report: widget.report,
        userName: userName,
        generatedAt: generatedAt,
        regularFont: await rootBundle.load(
          GeneralAdminReportPdf.regularFontAsset,
        ),
        boldFont: await rootBundle.load(GeneralAdminReportPdf.boldFontAsset),
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: GeneralAdminReportPdf.fileName(generatedAt),
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
