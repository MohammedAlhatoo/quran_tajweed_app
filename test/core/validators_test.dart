import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/utils/validators.dart';

void main() {
  test('email accepts a valid address and rejects invalid ones', () {
    expect(Validators.email('student@example.com'), isNull);
    expect(Validators.email('  student@example.com '), isNull);
    expect(Validators.email(''), isNotNull);
    expect(Validators.email('0599123456'), isNotNull);
    expect(Validators.email('student@example'), isNotNull);
  });

  test('phone accepts digits with an optional plus sign', () {
    expect(Validators.phone('0599123456'), isNull);
    expect(Validators.phone('+970599123456'), isNull);
    expect(Validators.phone(''), isNotNull);
    expect(Validators.phone('12345'), isNotNull);
    expect(Validators.phone('05991abc56'), isNotNull);
  });

  test('name requires at least three characters', () {
    expect(Validators.name('محمد أحمد'), isNull);
    expect(Validators.name('  '), isNotNull);
    expect(Validators.name('مح'), isNotNull);
  });

  test('new password requires the minimum length', () {
    expect(Validators.newPassword('123456'), isNull);
    expect(Validators.newPassword('12345'), isNotNull);
    expect(Validators.newPassword(''), isNotNull);
  });

  test('confirm password must match the password', () {
    expect(Validators.confirmPassword('123456', '123456'), isNull);
    expect(Validators.confirmPassword('123457', '123456'), isNotNull);
    expect(Validators.confirmPassword('', '123456'), isNotNull);
  });
}
