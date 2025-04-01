import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:scan_ml_text_kit/collect_registration/collect_registration.dart';
import 'package:scan_ml_text_kit/login/login_page.dart';

var logger = Logger(
  printer: PrettyPrinter(),
  filter: null,
  output: null,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collect Assist Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CollectRegistration(email: 'email'),
    );
  }
}
