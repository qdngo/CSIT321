import 'dart:developer';

import 'package:dio/dio.dart';

class RegisterRequest {
  late Dio dio;
  RegisterRequest() {
    dio = Dio(
        BaseOptions(
          baseUrl: "path"
        )
    );
  }
  Future<void> saveRegister({
    required String email,
    required String password,
  }) async {
    final result = await dio.post(
      "path",
      data: {
        "email": email,
        "password": password,
      },
    );
    log("${result.data}");
  }
}