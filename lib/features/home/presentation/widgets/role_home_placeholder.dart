import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';

/// Temporary landing screen for a role, used until the role's real screens are
/// implemented. Shows who is signed in and lets them sign out.
class RoleHomePlaceholder extends StatelessWidget {
  const RoleHomePlaceholder({super.key, required this.roleLabel});

  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final name = state is AuthAuthenticated ? state.user.name : '';

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'مرحبًا $name',
                        style: AppTextStyles.heading,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        roleLabel,
                        style: AppTextStyles.subtitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'شاشة مؤقتة — واجهات هذا الدور قيد التنفيذ.',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'تسجيل الخروج',
                        secondary: true,
                        isLoading: state is AuthLoading,
                        onPressed: context.read<AuthCubit>().signOut,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
