import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../domain/entities/exam_report.dart';
import '../pdf/region_report_pdf.dart';

/// Saves the region's [report] as a PDF file through the share sheet of the
/// system.
class RegionReportPdfButton extends StatefulWidget {
  const RegionReportPdfButton({super.key, required this.report});

  final ExamReport report;

  @override
  State<RegionReportPdfButton> createState() => _RegionReportPdfButtonState();
}

class _RegionReportPdfButtonState extends State<RegionReportPdfButton> {
  bool _isExporting = false;

  Future<void> _downloadPdf() async {
    if (_isExporting) return;
    final authState = context.read<AuthCubit>().state;
    final officerName = authState is AuthAuthenticated
        ? authState.user.name
        : '';
    setState(() => _isExporting = true);
    try {
      final generatedAt = DateTime.now();
      final bytes = await RegionReportPdf.build(
        report: widget.report,
        officerName: officerName,
        generatedAt: generatedAt,
        regularFont: await rootBundle.load(RegionReportPdf.regularFontAsset),
        boldFont: await rootBundle.load(RegionReportPdf.boldFontAsset),
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: RegionReportPdf.fileName(generatedAt),
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
