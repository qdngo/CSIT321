import 'package:flutter/material.dart';
import 'package:sample_assist/login/login_page.dart';
import 'package:dio/dio.dart';
import 'package:sample_assist/api/api_client.dart';

void main() {
  // Initialize Dio and ApiClient
  final Dio dio = Dio();
  final ApiClient apiClient = ApiClient(dio);

  // Pass ApiClient to the app
  runApp(MyApp(apiClient: apiClient));
}

class MyApp extends StatelessWidget {
  final ApiClient apiClient;

  const MyApp({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collect Assist Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Pass ApiClient to the LoginPage
      home: LoginPage(apiClient: apiClient),
    );
  }
}
