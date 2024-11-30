import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sample_assist/api/api_client.dart';
import 'package:sample_assist/register/register_page.dart';
import '../collect_registration/collect_registration.dart';
import '../gen/assets.gen.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  final ApiClient apiClient;

  const LoginPage({super.key, required this.apiClient});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final _formkey = GlobalKey<FormState>();

  bool _isPasswordVisible = false; // State variable for password visibility
  bool _isLoading = false; // State variable for loading indicator

  Future<void> _login() async {
    if (_formkey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the API client to send a login request
      final response = await widget.apiClient.login({
        "email": _email.text,
        "password": _password.text,
      });

      // Handle successful login
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Success!"),
          content: Text("Log In Successful!"),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.of(context).pop(); // Dismiss the dialog
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const CollectRegistration(),
        ));
      });
    } catch (e) {
      // Handle login failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login Failed: $e"),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
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
                        Text(
                          "Welcome!",
                          style: GoogleFonts.lobster(
                            textStyle: const TextStyle(
                              color: Color(0xFF1A1448),
                              fontSize: 65,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
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
                            if (text?.isNotEmpty == true && EmailValidator.validate(text!)) {
                              return null;
                            } else {
                              return 'Invalid Email!';
                            }
                          },
                        ),
                        const Gap(15),
                        TextFormField(
                          controller: _password,
                          obscureText: !_isPasswordVisible, // Toggle password visibility
                          style: const TextStyle(
                            color: Color(0xFF1A1448),
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock, color: Color(0xFF1A1448)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xFF1A1448),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
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
                        const Gap(7),
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(fontSize: 20),
                              backgroundColor: const Color(0xFF1A1448),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Log In",
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
    );
  }
}
