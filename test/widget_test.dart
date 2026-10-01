import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/main.dart';

void main() {
  testWidgets('shows the Arabic student registration form', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('تسجيل الطالب'), findsWidgets);
    expect(find.text('الاسم الكامل'), findsOneWidget);
    expect(find.text('رقم الهاتف'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('تأكيد كلمة المرور'), findsOneWidget);
  });
}
