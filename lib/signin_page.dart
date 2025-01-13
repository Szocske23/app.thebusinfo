import 'dart:convert';
import 'package:app_thebusinfo/home_screen.dart';

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
          await _storage.write(key: 'access-token', value: tokens['access-token']);
          await _storage.write(key: 'client', value: tokens['client']);
          await _storage.write(key: 'uid', value: tokens['uid']);
          await _storage.write(key: 'authorization', value: tokens['authorization']);

          // Navigate to Tickets page
         
          MaterialPageRoute(builder: (context) => const HomeScreen());
        } else {
          setState(() {
            _errorMessage = 'Missing tokens in the response';
          });
        }
      } else {
        final responseBody = json.decode(response.body);
        setState(() {
          _errorMessage = responseBody['errors']?.join(', ') ?? 'Sign-in failed';
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
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading
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
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}