import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _storage = const FlutterSecureStorage();
  String _version = "Loading...";
  String _buildNumber = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchAppInfo();
  }

  Future<void> _fetchAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      // Retrieve tokens from secure storage
      final accessToken = await _storage.read(key: 'access-token');
      final uid = await _storage.read(key: 'uid');
      final client = await _storage.read(key: 'client');
      final authorization = await _storage.read(key: 'authorization');

      if (accessToken == null || uid == null || client == null) {
        _showSnackBar(context, 'Missing authentication tokens.');
        return;
      }

      // Make the sign-out API call
      final response = await http.delete(
        Uri.parse('https://api.thebus.info/auth/sign_out'),
        headers: {
          'Authorization': 'Bearer $authorization',
          'access-token': accessToken,
          'client': client,
          'uid': uid,
        },
      );

      if (response.statusCode == 200) {
        // Navigate to login or welcome page on successful sign-out
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        _showSnackBar(context, 'Failed to sign out. Please try again.');
      }
    } catch (e) {
      _showSnackBar(context, 'An error occurred: $e');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setari', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildButton(FontAwesomeIcons.solidUser, 'Profil', () {}),
            _buildButton(FontAwesomeIcons.solidBell, 'Notificare', () {}),
            _buildButton(FontAwesomeIcons.shield, 'Privacy', () {}),
            _buildButton(FontAwesomeIcons.globe, 'Language', () {}),
            _buildButton(FontAwesomeIcons.solidCircleQuestion, 'Help', () {}),
            _buildButton(FontAwesomeIcons.circleInfo, 'About', () {}),
            _buildButton(FontAwesomeIcons.retweet, 'Updates', () {}),
            _buildButton(FontAwesomeIcons.rightFromBracket, 'Sign Out', () {
              _signOut(context);
            }),
            Center(
              child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "Version $_version (Build $_buildNumber)",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "© 2025 Prosoft.plus",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            )
            
          ],
        ),
      ),
      backgroundColor: Colors.black,
      
    );
  }

  Widget _buildButton(IconData icon, String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child:Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const RadialGradient(
                    colors: [
                      Color(0x09E2861D) ,// End color
                      Color(0x99E2861D),
                      
                    ],
                    radius:40,
                    focal: Alignment.bottomLeft
                  ),
                ),
                child:
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Button background color
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 25,
              child: FaIcon(icon, size: 25, color: const Color(0xFFe2861d)),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
