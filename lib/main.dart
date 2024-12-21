import 'package:flutter/material.dart';
import 'package:sample_assist/collect_registration/collect_registration.dart';
import 'package:sample_assist/login/login_page.dart';
import 'package:sample_assist/register/register_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collect Assist Demo',
      theme: ThemeData(
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CollectRegistration(),
    );
  }
}
