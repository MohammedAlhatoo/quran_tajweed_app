import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../state/recording_cubit.dart';

/// The recording bar at the bottom of the examination screen: the timer and
/// the actions available for the current [RecordingStatus].
class RecordingControls extends StatelessWidget {
  const RecordingControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecordingCubit, RecordingState>(
      listenWhen: (previous, current) => current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        final uploaded = state.status == RecordingStatus.uploaded;

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.line)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 10),
                blurRadius: 15,
                spreadRadius: -3,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 9, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusRow(state),
                  if (_caption(state) case final caption?) ...[
                    const SizedBox(height: 8),
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cairo(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.muted,
                        lineHeight: 18,
                      ),
                    ),
                  ],
                  if (!uploaded) ...[
                    const SizedBox(height: 12),
                    _MainButton(state),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// What the student is told about the current recording.
  static String? _caption(RecordingState state) {
    return switch (state.status) {
      RecordingStatus.idle => null,
      RecordingStatus.recording => 'جارٍ تسجيل التلاوة...',
      RecordingStatus.recorded when state.hasUploaded =>
        'تسجيل جديد لم يُرفع بعد. ارفعه ليستبدل التسجيل المرفوع سابقًا.',
      RecordingStatus.recorded => 'التسجيل جاهز. استمع إليه ثم ارفعه.',
      RecordingStatus.playing => 'جارٍ تشغيل التسجيل...',
      RecordingStatus.uploading =>
        'جارٍ رفع التسجيل... ${(state.uploadProgress * 100).round()}%',
      RecordingStatus.uploaded => null,
    };
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow(this.state);

  final RecordingState state;

  Future<void> _reRecord(BuildContext context) async {
    final cubit = context.read<RecordingCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة التسجيل'),
        content: const Text(
          'سيُستبدل التسجيل الحالي بتسجيل جديد. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إعادة التسجيل'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.start();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecordingCubit>();
    final reRecord = _SideButton(
      icon: Icons.replay_rounded,
      label: 'إعادة',
      onPressed: () => _reRecord(context),
    );

    switch (state.status) {
      case RecordingStatus.idle || RecordingStatus.recording:
        return Center(child: _TimerPill(state.elapsed, showDot: true));
      case RecordingStatus.uploaded:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              SvgPicture.asset(AppAssets.checkIcon, width: 16, height: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تم رفع التسجيل بنجاح',
                  style: AppTextStyles.cairo(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.bodyText,
                    lineHeight: 20,
                  ),
                ),
              ),
              reRecord,
            ],
          ),
        );
      case RecordingStatus.recorded ||
          RecordingStatus.playing ||
          RecordingStatus.uploading:
        final playing = state.status == RecordingStatus.playing;
        final enabled = state.status == RecordingStatus.recorded;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              playing
                  ? _SideButton(
                      icon: Icons.stop_rounded,
                      label: 'إيقاف',
                      onPressed: cubit.stopPlayback,
                    )
                  : _SideButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'استماع',
                      onPressed: enabled ? cubit.play : null,
                    ),
              _TimerPill(state.elapsed, showDot: false),
              enabled
                  ? reRecord
                  : const _SideButton(
                      icon: Icons.replay_rounded,
                      label: 'إعادة',
                      onPressed: null,
                    ),
            ],
          ),
        );
    }
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill(this.elapsed, {required this.showDot});

  final Duration elapsed;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lineSoft,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // The design keeps the digits on the left of the dot.
        textDirection: TextDirection.ltr,
        children: [
          Text(
            '$minutes:$seconds',
            style: AppTextStyles.cairo(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.bodyText,
              lineHeight: 16,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          if (showDot) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null ? AppColors.faint : AppColors.muted;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.cairo(
                size: 10,
                weight: FontWeight.w500,
                color: color,
                lineHeight: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The round action button: record, stop, or upload the recording. It never
/// submits the examination.
class _MainButton extends StatelessWidget {
  const _MainButton(this.state);

  final RecordingState state;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecordingCubit>();
    final status = state.status;
    final (
      String label,
      VoidCallback? onPressed,
      Widget child,
    ) = switch (status) {
      RecordingStatus.recording => (
        'إيقاف التسجيل',
        cubit.stop,
        const Icon(Icons.stop_rounded, size: 28, color: AppColors.onPrimary),
      ),
      RecordingStatus.recorded || RecordingStatus.playing => (
        'رفع التلاوة',
        status == RecordingStatus.recorded ? cubit.upload : null,
        const _UploadLabel(),
      ),
      RecordingStatus.uploading => (
        'جارٍ رفع التسجيل',
        null,
        SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(
            // Spins until the first progress report arrives.
            value: state.uploadProgress > 0 ? state.uploadProgress : null,
            strokeWidth: 2.5,
            color: AppColors.onPrimary,
          ),
        ),
      ),
      _ => (
        'بدء التسجيل الصوتي للاختبار',
        cubit.start,
        SvgPicture.asset(AppAssets.micIcon, width: 28, height: 28),
      ),
    };

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onPressed,
          child: Opacity(
            opacity: status == RecordingStatus.playing ? 0.5 : 1,
            child: Container(
              // The glow ring around the button.
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.recordButtonGlow,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Container(
                height: _size,
                constraints: const BoxConstraints(minWidth: _size),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: AppColors.recordButtonGradient,
                  ),
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.recordButtonShadow,
                      offset: Offset(0, 10),
                      blurRadius: 15,
                      spreadRadius: -3,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadLabel extends StatelessWidget {
  const _UploadLabel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'رفع التلاوة',
            style: AppTextStyles.button.copyWith(color: AppColors.onPrimary),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_upward_rounded,
            size: 20,
            color: AppColors.onPrimary,
          ),
        ],
      ),
    );
  }
}
