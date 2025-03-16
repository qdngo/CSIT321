import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:email_validator/email_validator.dart';
import 'package:http/http.dart' as http;
import 'package:sample_assist/utils/consts.dart';

import '../gen/assets.gen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final _formkey = GlobalKey<FormState>();

  bool _obscuredPassword = true;
  bool _obscuredConfirmPassword = true;

  void _toggleObscuredPassword() {
    setState(() {
      _obscuredPassword = !_obscuredPassword;
    });
  }

  void _toggleObscuredConfirmPassword() {
    setState(() {
      _obscuredConfirmPassword = !_obscuredConfirmPassword;
    });
  }

  Future<void> _signup() async {
    if (_formkey.currentState?.validate() != true) {
      return;
    }

    final String email = _email.text.trim();
    final String password = _password.text.trim();

    try {
      // API call using http
      final http.Response response = await http.post(
        Uri.parse(registerUri),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Success!"),
            content: Text(data['message'] ?? 'Sign Up Successful!'),
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pop(); // Close success dialog
          Navigator.of(context).pop(); // Return to the previous screen
        });
      } else {
        final data = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error!"),
            content: Text(data['error'] ?? 'Sign Up Failed!'),
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error!"),
          content: const Text("Failed to connect to the server. Please try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1448),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formkey,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Assets.images.bg1.path),
                fit: BoxFit.fill,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.9),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Gap(30),
                          Image.asset(
                            Assets.images.logo.path,
                            width: 160,
                            height: 160,
                          ),
                          TextFormField(
                            controller: _email,
                            style: const TextStyle(
                              color: Color(0xFF1A1448),
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email, color: Color(0xFF1A1448)),
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                color: Color(0xFF1A1448),
                                fontSize: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF1A1448), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF01B4D2), width: 1.5),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF1A1448), width: 1.5),
                              ),
                            ),
                            validator: (text) {
                              if (text?.isNotEmpty == true &&
                                  EmailValidator.validate(text!)) {
                                return null;
                              } else {
                                return 'Invalid Email!';
                              }
                            },
                          ),
                          const Gap(15),
                          TextFormField(
                            controller: _password,
                            style: const TextStyle(
                              color: Color(0xFF1A1448),
                              fontSize: 16,
                            ),
                            obscureText: _obscuredPassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock, color: Color(0xFF1A1448)),
                              suffixIcon: IconButton(
                                onPressed: _toggleObscuredPassword,
                                icon: Icon(
                                  _obscuredPassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  size: 20,
                                ),
                              ),
                              labelText: 'Password',
                              labelStyle: const TextStyle(
                                color: Color(0xFF1A1448),
                                fontSize: 16,
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF1A1448), width: 1.5),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF01B4D2), width: 1.5),
                              ),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF1A1448), width: 1.5),
                              ),
                            ),
                            validator: (text) {
                              if (text?.isNotEmpty == true && text!.length > 6) {
                                return null;
                              } else {
                                return 'Invalid Password!';
                              }
                            },
                          ),
                          const Gap(15),
                          TextFormField(
                            controller: _confirmPassword,
                            style: const TextStyle(
                              color: Color(0xFF1A1448),
                              fontSize: 16,
                            ),
                            obscureText: _obscuredConfirmPassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock, color: Color(0xFF1A1448)),
                              suffixIcon: IconButton(
                                onPressed: _toggleObscuredConfirmPassword,
                                icon: Icon(
                                  _obscuredConfirmPassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  size: 20,
                                ),
                              ),
                              labelText: 'Confirm Password',
                              labelStyle: const TextStyle(
                                color: Color(0xFF1A1448),
                                fontSize: 16,
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF1A1448), width: 1.5),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF01B4D2), width: 1.5),
                              ),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF1A1448), width: 1.5),
                              ),
                            ),
                            validator: (text) {
                              if (text?.isNotEmpty == true &&
                                  _confirmPassword.text == _password.text) {
                                return null;
                              } else if (text?.isNotEmpty == true &&
                                  _confirmPassword.text != _password.text) {
                                return 'Password does not match!';
                              } else {
                                return 'Confirmed Password is invalid!';
                              }
                            },
                          ),
                          const Gap(7),
                          ElevatedButton(
                            onPressed: _signup,
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(fontSize: 20),
                              backgroundColor: const Color(0xFF1A1448),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}