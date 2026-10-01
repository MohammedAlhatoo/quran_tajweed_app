import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const QuranTajweedApp());
}

class QuranTajweedApp extends StatelessWidget {
  const QuranTajweedApp({super.key});

  static const Locale _arabic = Locale('ar');

  @override
  Widget build(BuildContext context) {
    // Routing is added in its own implementation step.
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light,
      // The Arabic locale makes the whole app RTL.
      locale: _arabic,
      supportedLocales: const [_arabic],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Scaffold(),
    );
  }
}
