// import 'package:email_validator/email_validator.dart';
// import 'package:flutter/material.dart';
// import 'package:gap/gap.dart';
// import 'package:sample_assist/register/register_page.dart';
// import '../collect_registration/collect_registration.dart';
// import '../gen/assets.gen.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final TextEditingController _email = TextEditingController();
//   final TextEditingController _password = TextEditingController();
//   final _formkey = GlobalKey<FormState>();
//
//   bool _isPasswordVisible = false; // State variable for password visibility
//
//   void _login() {
//     if (_formkey.currentState?.validate() != true) {
//       return;
//     } else {
//       showDialog(
//         context: context,
//         builder: (context) => const AlertDialog(
//           title: Text("Success!"),
//           content: Text("Log In Success!"),
//         ),
//       );
//       Future.delayed(const Duration(seconds: 2), () {
//         if (!mounted) return;
//         Navigator.of(context).pop(); // Dismiss the dialog
//         Navigator.of(context).push(MaterialPageRoute(
//           builder: (context) => const CollectRegistration(),
//         ));
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Form(
//         key: _formkey,
//         child: Container(
//           width: MediaQuery.of(context).size.width,
//           height: MediaQuery.of(context).size.height,
//           padding: const EdgeInsets.all(35),
//           decoration: BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage(Assets.images.bg1.path),
//               fit: BoxFit.fill,
//             ),
//           ),
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.transparent),
//                     borderRadius: BorderRadius.circular(16),
//                     color: Colors.white.withOpacity(0.9),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Column(
//                       children: [
//                         Text(
//                           "Welcome!",
//                           style: GoogleFonts.lobster(
//                             textStyle: const TextStyle(
//                               color: Color(0xFF1A1448),
//                               fontSize: 65,
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                         ),
//                         const Gap(30),
//                         Image.asset(
//                           Assets.images.logo.path,
//                           width: 160,
//                           height: 160,
//                         ),
//                         TextFormField(
//                           controller: _email,
//                           style: const TextStyle(
//                             color: Color(0xFF1A1448),
//                             fontSize: 16,
//                           ),
//                           decoration: const InputDecoration(
//                             prefixIcon: Icon(Icons.email, color: Color(0xFF1A1448)),
//                             labelText: 'Email',
//                             labelStyle: TextStyle(
//                               color: Color(0xFF1A1448),
//                               fontSize: 16,
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderSide: BorderSide(color: Color(0xFF1A1448), width: 1.5),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderSide: BorderSide(color: Color(0xFF01B4D2), width: 1.5),
//                             ),
//                             border: OutlineInputBorder(
//                               borderSide: BorderSide(color: Color(0xFF1A1448), width: 1.5),
//                             ),
//                           ),
//                           validator: (text) {
//                             if (text?.isNotEmpty == true && EmailValidator.validate(text!)) {
//                               return null;
//                             } else {
//                               return 'Invalid Email!';
//                             }
//                           },
//                         ),
//                         const Gap(15),
//                         TextFormField(
//                           controller: _password,
//                           obscureText: !_isPasswordVisible, // Toggle password visibility
//                           style: const TextStyle(
//                             color: Color(0xFF1A1448),
//                             fontSize: 16,
//                           ),
//                           decoration: InputDecoration(
//                             prefixIcon: const Icon(Icons.lock, color: Color(0xFF1A1448)),
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                 _isPasswordVisible
//                                     ? Icons.visibility
//                                     : Icons.visibility_off,
//                                 color: const Color(0xFF1A1448),
//                               ),
//                               onPressed: () {
//                                 setState(() {
//                                   _isPasswordVisible = !_isPasswordVisible;
//                                 });
//                               },
//                             ),
//                             labelText: 'Password',
//                             labelStyle: const TextStyle(
//                               color: Color(0xFF1A1448),
//                               fontSize: 16,
//                             ),
//                             enabledBorder: const OutlineInputBorder(
//                               borderSide: BorderSide(color: Color(0xFF1A1448), width: 1.5),
//                             ),
//                             focusedBorder: const OutlineInputBorder(
//                               borderSide: BorderSide(color: Color(0xFF01B4D2), width: 1.5),
//                             ),
//                             border: const OutlineInputBorder(
//                               borderSide: BorderSide(color: Color(0xFF1A1448), width: 1.5),
//                             ),
//                           ),
//                           validator: (text) {
//                             if (text?.isNotEmpty == true && text!.length > 6) {
//                               return null;
//                             } else {
//                               return 'Invalid Password!';
//                             }
//                           },
//                         ),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             const Spacer(),
//                             TextButton.icon(
//                               onPressed: () {
//                                 // Add forgot password logic here
//                               },
//                               label: const Text(
//                                 "Forgot Password?",
//                                 style: TextStyle(
//                                   color: Color(0xFF1A1448),
//                                   decoration: TextDecoration.underline,
//                                   decorationColor: Color(0xFF1A1448),
//                                   decorationThickness: 1.5,
//                                 ),
//                               ),
//                               style: TextButton.styleFrom(
//                                 padding: EdgeInsets.zero,
//                                 minimumSize: const Size(0, 0),
//                               ),
//                               icon: const Icon(Icons.lock_outline, color: Color(0xFF1A1448), size: 18),
//                             ),
//                           ],
//                         ),
//                         const Gap(7),
//                         ElevatedButton(
//                           onPressed: _login,
//                           style: ElevatedButton.styleFrom(
//                             textStyle: const TextStyle(fontSize: 20),
//                             backgroundColor: const Color(0xFF1A1448),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                           ),
//                           child: const Text(
//                             "Log In",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Text(
//                               "Don't have an account? ",
//                               style: TextStyle(
//                                 color: Color(0xFF1A1448),
//                                 fontSize: 16,
//                               ),
//                             ),
//                             TextButton(
//                               onPressed: () {
//                                 Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterPage()));
//                               },
//                               style: TextButton.styleFrom(
//                                 padding: EdgeInsets.zero,
//                                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                               ),
//                               child: const Text(
//                                 "Register",
//                                 style: TextStyle(
//                                   color: Color(0xFF01B4D2),
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sample_assist/collect_registration/collect_registration.dart';
import 'package:sample_assist/utils/consts.dart';
import '../gen/assets.gen.dart';
import '../register/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _email = TextEditingController(text: 'my@gmail.com');
  final TextEditingController _password = TextEditingController(text: '12345678');
  final _formKey = GlobalKey<FormState>();

  final FlutterSecureStorage _storage =
  const FlutterSecureStorage(); // Secure storage instance

  bool _isPasswordVisible = false;

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(loginUri),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _email.text,
          "password": _password.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Assuming the API response has a token field
        final String? token = data['access_token'];

        if (token != null) {
          // Print the access token to the console
          print("Access Token: $token");

          // Navigate to CollectRegistration on success
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
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) =>  CollectRegistration(email: _email.text,),
            ));
          });
        } else {
          _showErrorDialog("Failed to retrieve token.");
        }
      } else if (response.statusCode == 401) {
        _showErrorDialog("Invalid email or password.");
      } else {
        _showErrorDialog(
            "Unexpected error occurred. Status: ${response.statusCode}");
      }
    } catch (error) {
      _showErrorDialog("An error occurred: $error");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                                fontSize: 50,
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
                              prefixIcon:
                              Icon(Icons.email, color: Color(0xFF1A1448)),
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                color: Color(0xFF1A1448),
                                fontSize: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF1A1448), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF01B4D2), width: 1.5),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF1A1448), width: 1.5),
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
                            obscureText: !_isPasswordVisible,
                            // Toggle password visibility
                            style: const TextStyle(
                              color: Color(0xFF1A1448),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock,
                                  color: Color(0xFF1A1448)),
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
                                borderSide: BorderSide(
                                    color: Color(0xFF1A1448), width: 1.5),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF01B4D2), width: 1.5),
                              ),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF1A1448), width: 1.5),
                              ),
                            ),
                            validator: (text) {
                              if (text?.isNotEmpty == true &&
                                  text!.length > 6) {
                                return null;
                              } else {
                                return 'Invalid Password!';
                              }
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  // Add forgot password logic here
                                },
                                label: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: Color(0xFF1A1448),
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF1A1448),
                                    decorationThickness: 1.5,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                ),
                                icon: const Icon(Icons.lock_outline,
                                    color: Color(0xFF1A1448), size: 18),
                              ),
                            ],
                          ),
                          const Gap(7),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Color(0xFF1A1448),
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) =>
                                      const RegisterPage()));
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "Register",
                                  style: TextStyle(
                                    color: Color(0xFF01B4D2),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
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