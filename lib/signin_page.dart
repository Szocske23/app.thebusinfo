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
      backgroundColor: Colors.transparent,
      body:Container(
      // Add gradient background here
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Color.fromARGB(182, 222, 119, 1), 
            Color(0x10000000),
            Color(0x10000000),
          ],
          focal: FractionalOffset.bottomLeft,
          radius: 3.8,
          stops: [0.0, 0.4, 0.8],
          tileMode: TileMode.clamp,
          focalRadius: 0.2
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Image.asset(
              'assets/logo_trsp.png',
              width: 500,
            ),
            const SizedBox(height: 40),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              autocorrect: false,
              autofillHints: const [AutofillHints.email], 
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                floatingLabelStyle: TextStyle(color: Color(0xFFE2861D)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE2861D)),
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
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
                              _errorMessage =
                                  'Email and password are required.';
                            });
                          } else {
                            _signIn(email, password);
                          }
                        },
              decoration: const InputDecoration(
                labelText: 'Password',
                floatingLabelStyle: TextStyle(color: Color(0xFFE2861D)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE2861D)),
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, // Full width of the parent container
              height: 60, // Button height
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color:  Colors.black,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
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
      ),
    );
  }
}
