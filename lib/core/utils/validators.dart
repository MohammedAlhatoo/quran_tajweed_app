import '../constants/app_constants.dart';

/// Form field validators. Each returns an Arabic error message, or null when
/// the value is valid.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phone = RegExp(r'^\+?[0-9]{7,15}$');

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'أدخل الاسم';
    if (value.trim().length < 3) return 'الاسم قصير جدًا';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'أدخل البريد الإلكتروني';
    if (!_email.hasMatch(value.trim())) return 'البريد الإلكتروني غير صحيح';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'أدخل رقم الهاتف';
    if (!_phone.hasMatch(value.trim())) return 'رقم الهاتف غير صحيح';
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'أدخل كلمة المرور';
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'أدخل كلمة المرور';
    if (value.length < AppConstants.minPasswordLength) {
      return 'كلمة المرور يجب ألا تقل عن ${AppConstants.minPasswordLength} أحرف';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'أكّد كلمة المرور';
    if (value != password) return 'كلمتا المرور غير متطابقتين';
    return null;
  }
}
