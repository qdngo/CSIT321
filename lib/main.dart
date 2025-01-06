import 'package:flutter/material.dart';
import 'package:sample_assist/collect_registration/collect_registration.dart';
import 'package:sample_assist/login/login_page.dart';
import 'package:sample_assist/register/register_page.dart';
import 'package:sample_assist/id_card_scanner_page.dart'; // Import the new scanner page

void main() {
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
      initialRoute: '/login', // Define the initial route
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/collect_registration': (context) => const CollectRegistration(),
        '/id_card_scanner': (context) => const IDCardScannerPage(), // Add the scanner route
      },
    );
  }
}
