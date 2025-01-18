import 'dart:convert';
import 'package:app_thebusinfo/home_screen.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.thebus.info/auth/sign_in'),
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final headers = response.headers;
        final tokens = {
          'access-token': headers['access-token'],
          'client': headers['client'],
          'uid': headers['uid'],
          'authorization': headers['authorization'],
        };

        if (tokens.values.every((value) => value != null)) {
          await _storage.write(
              key: 'access-token', value: tokens['access-token']);
          await _storage.write(key: 'client', value: tokens['client']);
          await _storage.write(key: 'uid', value: tokens['uid']);
          await _storage.write(
              key: 'authorization', value: tokens['authorization']);

          // Navigate to HomeScreen
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          setState(() {
            _errorMessage = 'Missing tokens in the response';
          });
        }
      } else {
        final responseBody = json.decode(response.body);
        setState(() {
          _errorMessage =
              responseBody['errors']?.join(', ') ?? 'Sign-in failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Sign In',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Container(
              height: 120,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8)),
                gradient: RadialGradient(
                  colors: [
                    Color(0x408E8E8E),
                    Colors.transparent,
                  ],
                  focal: Alignment.bottomCenter,
                  radius: 30,
                  stops: [-4.0, 1.0], // Corrected stops (must be within [0, 1])
                ),
              ),
              child: Image.asset(
                'assets/logo_trsp.png',
                width: 500,
              ),
            ),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 60,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8)),
                  gradient: RadialGradient(
                    colors: [
                      Color(0x408E8E8E),
                      Color(0x40c51b29),
                    ],
                    focal: Alignment.bottomCenter,
                    radius: 30,
                    stops: [
                      -4.0,
                      1.0
                    ], // Corrected stops (must be within [0, 1])
                  ),
                ),
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Container(
              height: 60,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8)),
                gradient: RadialGradient(
                  colors: [
                    Color(0x408E8E8E),
                    Colors.transparent,
                  ],
                  focal: Alignment.bottomCenter,
                  radius: 30,
              
                  stops: [0.0, 1.0], // Corrected stops (must be within [0, 1])
                ),
              ),
              child: TextField(
                
                controller: _emailController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  
                  labelText: 'Email',
                  floatingLabelStyle: TextStyle(color: Color(0xFFE2861D)),
                  labelStyle: TextStyle(color: Colors.white60),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent)),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                ),
                keyboardType: TextInputType.emailAddress,
                keyboardAppearance: Brightness.dark,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 60,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8)),
                gradient: RadialGradient(
                  colors: [
                    Color(0x408E8E8E),
                    Colors.transparent,
                  ],
                  focal: Alignment.bottomCenter,
                  radius: 30,
                  stops: [0.0, 1.0], // Corrected stops (must be within [0, 1])
                ),
              ),
              child: TextField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                autocorrect: false,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onEditingComplete: _isLoading
                    ? null
                    : () {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();

                        if (email.isEmpty || password.isEmpty) {
                          setState(() {
                            _errorMessage = 'Email and password are required.';
                          });
                        } else {
                          _signIn(email, password);
                        }
                      },
                decoration: const InputDecoration(
                  labelText: 'Password',
                  floatingLabelStyle: TextStyle(color: Color(0xFFE2861D)),
                  labelStyle: TextStyle(color: Colors.white60),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent)),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                ),
                obscureText: true,
                keyboardAppearance: Brightness.dark,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity, // Full width of the parent container
              height: 60, // Button height
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25)),
                  gradient: RadialGradient(
                    colors: [
                      Color(0x408E8E8E),
                      Colors.transparent,
                    ],
                    focal: Alignment.bottomCenter,
                    radius: 30,
                    stops: [
                      0.0,
                      1.0
                    ], // Corrected stops (must be within [0, 1])
                  ),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25)),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();

                          if (email.isEmpty || password.isEmpty) {
                            setState(() {
                              _errorMessage =
                                  'Email and password are required.';
                            });
                          } else {
                            _signIn(email, password);
                          }
                        },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Navigate to the Sign Up page
              },
              child: const Text(
                'Don\'t have an account? Sign Up',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
