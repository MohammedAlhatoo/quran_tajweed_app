import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../widgets/user_avatar.dart';

/// The student's profile tab.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final name = authState is AuthAuthenticated ? authState.user.name : '';

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('الملف الشخصي'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          const Center(
            child: Stack(
              children: [
                UserAvatar(size: 80, iconSize: 44),
                PositionedDirectional(
                  bottom: 4,
                  start: 4,
                  child: _ActiveBadge(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: AppTextStyles.cairo(
              size: 18,
              weight: FontWeight.w700,
              color: AppColors.ink,
              lineHeight: 28,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'طالب',
            textAlign: TextAlign.center,
            style: AppTextStyles.cairo(
              size: 12,
              weight: FontWeight.w500,
              color: AppColors.muted,
              lineHeight: 16,
            ),
          ),
          const SizedBox(height: 24),
          _MenuItem(
            icon: AppAssets.profileInfoIcon,
            label: 'معلومات شخصية',
            onTap: () => context.push(RouteNames.studentPersonalInfo),
          ),
          const SizedBox(height: 10),
          _MenuItem(
            icon: AppAssets.profileHistoryIcon,
            label: 'سجل الاختبارات',
            onTap: () => context.go(RouteNames.studentExams),
          ),
          const SizedBox(height: 10),
          _MenuItem(
            icon: AppAssets.profileCertificatesIcon,
            label: 'الشهادات',
            onTap: () => context.push(RouteNames.studentCertificates),
          ),
          const SizedBox(height: 32),
          _SignOutButton(
            isLoading: authState is AuthLoading,
            onPressed: context.read<AuthCubit>().signOut,
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.lineSoft),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.iconTileBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(icon, width: 16, height: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.cairo(
                    size: 14,
                    weight: FontWeight.w500,
                    color: AppColors.title,
                    lineHeight: 20,
                  ),
                ),
              ),
              SvgPicture.asset(AppAssets.chevronIcon, width: 16, height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Material(
      color: AppColors.dangerBackground,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.dangerBorder),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: isLoading ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.danger,
              ),
              const SizedBox(width: 8),
              Text(
                'تسجيل الخروج',
                style: AppTextStyles.cairo(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.danger,
                  lineHeight: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
