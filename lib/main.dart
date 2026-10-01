import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const QuranTajweedApp());
}

class QuranTajweedApp extends StatelessWidget {
  const QuranTajweedApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme and routing are added in their own implementation steps.
    return const MaterialApp(home: Scaffold());
  }
}
