import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../state/mosque_name_cubit.dart';

/// The student's account details. View only: the mosque, square and region
/// cannot be changed by the student.
class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  static const String _missing = '—';

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('معلومات شخصية'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lineSoft),
            ),
            child: Column(
              children: [
                _InfoRow(label: 'الاسم', value: user?.name ?? _missing),
                const Divider(color: AppColors.lineSoft),
                _InfoRow(
                  label: 'البريد الإلكتروني',
                  value: user?.email ?? _missing,
                ),
                const Divider(color: AppColors.lineSoft),
                _InfoRow(
                  label: 'رقم الهاتف',
                  value: user?.phone ?? _missing,
                  isLtrValue: true,
                ),
                const Divider(color: AppColors.lineSoft),
                BlocBuilder<MosqueNameCubit, MosqueNameState>(
                  builder: (context, state) => _InfoRow(
                    label: 'المسجد',
                    value: switch (state) {
                      MosqueNameLoading() => '...',
                      MosqueNameLoaded(:final name) => name ?? _missing,
                      MosqueNameError(:final message) => message,
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLtrValue = false,
  });

  final String label;
  final String value;
  final bool isLtrValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.cairo(
              size: 12,
              weight: FontWeight.w500,
              color: AppColors.muted,
              lineHeight: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: isLtrValue ? TextDirection.ltr : null,
              style: AppTextStyles.cairo(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.title,
                lineHeight: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
