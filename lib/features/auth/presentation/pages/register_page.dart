import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../state/auth_cubit.dart';
import '../state/auth_state.dart';
import '../state/mosques_cubit.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_layout.dart';

/// Student registration. The role is never chosen here: every account created
/// from this page is a student.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _mosqueId;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final mosqueId = _mosqueId;
    if (mosqueId == null) {
      showAppSnackBar(context, 'اختر المسجد لإكمال التسجيل.', isError: true);
      return;
    }
    context.read<AuthCubit>().registerStudent(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      mosqueId: mosqueId,
    );
  }

  void _onAuthState(BuildContext context, AuthState state) {
    // A successful registration is handled by the router redirect.
    if (state case AuthError(:final message)) {
      showAppSnackBar(context, message, isError: true);
    }
  }

  static Widget _icon(IconData icon) =>
      Icon(icon, size: 20, color: AppColors.textHint);

  static Widget _svgIcon(String asset) =>
      SvgPicture.asset(asset, width: 20, height: 20);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: _onAuthState,
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AuthLayout(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthBrandHeader(
                  subtitle: 'إنشاء حساب طالب جديد',
                  logoSize: 72,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _nameController,
                  hintText: 'الاسم الكامل',
                  prefixIcon: _icon(Icons.person_outline),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailController,
                  hintText: 'البريد الإلكتروني',
                  prefixIcon: _svgIcon(AppAssets.mailIcon),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phoneController,
                  hintText: 'رقم الهاتف',
                  prefixIcon: _icon(Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  hintText: 'كلمة المرور',
                  prefixIcon: _svgIcon(AppAssets.lockIcon),
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: Validators.newPassword,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmPasswordController,
                  hintText: 'تأكيد كلمة المرور',
                  prefixIcon: _svgIcon(AppAssets.lockIcon),
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: 16),
                _MosqueField(
                  selectedId: _mosqueId,
                  prefixIcon: _icon(Icons.mosque_outlined),
                  onChanged: (id) => setState(() => _mosqueId = id),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'إنشاء الحساب',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: isLoading ? null : () => context.pop(),
                    child: Text(
                      'لديك حساب؟ تسجيل الدخول',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The mosque picker. Only the mosque is chosen; the square and region are
/// derived from it when the account is created.
class _MosqueField extends StatelessWidget {
  const _MosqueField({
    required this.selectedId,
    required this.prefixIcon,
    required this.onChanged,
  });

  final String? selectedId;
  final Widget prefixIcon;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MosquesCubit, MosquesState>(
      builder: (context, state) {
        switch (state) {
          case MosquesLoading():
            return InputDecorator(
              decoration: AppTextField.decoration(
                hintText: 'جارٍ تحميل المساجد...',
                prefixIcon: prefixIcon,
              ),
              isEmpty: true,
            );
          case MosquesError(:final message):
            return _MosquesMessage(
              message: message,
              onRetry: context.read<MosquesCubit>().load,
            );
          case MosquesLoaded(:final mosques) when mosques.isEmpty:
            return _MosquesMessage(
              message: 'لا توجد مساجد متاحة للتسجيل حاليًا.',
              onRetry: context.read<MosquesCubit>().load,
            );
          case MosquesLoaded(:final mosques):
            return DropdownButtonFormField<String>(
              initialValue: selectedId,
              isExpanded: true,
              style: AppTextStyles.body,
              borderRadius: BorderRadius.circular(12),
              decoration: AppTextField.decoration(
                hintText: 'اختر المسجد',
                prefixIcon: prefixIcon,
              ),
              items: [
                for (final mosque in mosques)
                  DropdownMenuItem(
                    value: mosque.id,
                    child: Text(mosque.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: onChanged,
              validator: (value) => value == null ? 'اختر المسجد' : null,
            );
        }
      },
    );
  }
}

class _MosquesMessage extends StatelessWidget {
  const _MosquesMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.subtitle.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
      ],
    );
  }
}
