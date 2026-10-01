import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';

/// A themed form field. With [isPassword] the text is hidden and a toggle is
/// shown to reveal it.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
    this.isPassword = false,
  });

  final TextEditingController controller;
  final String hintText;
  final Widget? prefixIcon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final bool isPassword;

  /// Decoration shared with other form controls, such as dropdowns.
  static InputDecoration decoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon == null
          ? null
          : Padding(
              padding: const EdgeInsetsDirectional.only(start: 14, end: 10),
              child: prefixIcon,
            ),
      prefixIconConstraints: const BoxConstraints(),
      suffixIcon: suffixIcon,
    );
  }

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onFieldSubmitted,
      obscureText: widget.isPassword && _obscured,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: AppTextField.decoration(
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.isPassword ? _visibilityToggle() : null,
      ),
    );
  }

  Widget _visibilityToggle() {
    return IconButton(
      tooltip: _obscured ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
      onPressed: () => setState(() => _obscured = !_obscured),
      icon: SvgPicture.asset(
        AppAssets.eyeIcon,
        width: 20,
        height: 20,
        // The design has a single eye icon; it turns green while the
        // password is visible.
        colorFilter: _obscured
            ? null
            : const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
      ),
    );
  }
}
