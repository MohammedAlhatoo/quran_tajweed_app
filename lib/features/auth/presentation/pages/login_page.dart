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
import '../../../../router/route_names.dart';
import '../state/auth_cubit.dart';
import '../state/auth_state.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  void _resetPassword() {
    final email = _emailController.text;
    if (Validators.email(email) != null) {
      showAppSnackBar(
        context,
        'اكتب بريدك الإلكتروني في الحقل أولًا لإرسال رابط إعادة التعيين.',
        isError: true,
      );
      return;
    }
    context.read<AuthCubit>().sendPasswordResetEmail(email);
  }

  void _onAuthState(BuildContext context, AuthState state) {
    // The page stays mounted under the registration page; only react while
    // it is the visible one.
    if (ModalRoute.of(context)?.isCurrent != true) return;

    switch (state) {
      case AuthError(:final message):
        showAppSnackBar(context, message, isError: true);
      case AuthPasswordResetSent():
        showAppSnackBar(
          context,
          'إن كان البريد مسجّلًا، فسيصلك رابط إعادة تعيين كلمة المرور.',
        );
      case AuthAuthenticated():
        // Role-based navigation is added in the routing step.
        showAppSnackBar(context, 'تم تسجيل الدخول بنجاح.');
      case AuthInitial() || AuthLoading():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: _onAuthState,
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AuthLayout(
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthBrandHeader(),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _emailController,
                    hintText: 'البريد الإلكتروني',
                    prefixIcon: SvgPicture.asset(
                      AppAssets.mailIcon,
                      width: 20,
                      height: 20,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    hintText: 'كلمة المرور',
                    prefixIcon: SvgPicture.asset(
                      AppAssets.lockIcon,
                      width: 20,
                      height: 20,
                    ),
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: Validators.loginPassword,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'تسجيل الدخول',
                    isLoading: isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 20),
                  const _OrDivider(),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'إنشاء حساب جديد',
                    secondary: true,
                    isLoading: isLoading,
                    onPressed: () => context.push(RouteNames.register),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: isLoading ? null : _resetPassword,
                      child: Text(
                        'نسيت كلمة المرور؟',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'أو',
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
