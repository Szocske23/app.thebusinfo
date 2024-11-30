import 'package:flutter/material.dart';
import '/home_screen.dart';
import 'no_connection_screen.dart';
import 'services/server_health_check.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The BusInfo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeSplash();
  }

  Future<void> _initializeSplash() async {
    const splashDuration = Duration(seconds: 2); // Minimum splash duration
    final splashTimer = Future.delayed(splashDuration);

    try {
      // Perform health check
      final isHealthy = await ServerHealthCheck.checkHealth();
      await splashTimer; // Ensure splash screen duration is respected

      // Navigate based on health check result
      if (isHealthy) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NoConnectionScreen()),
        );
      }
    } catch (error) {
      // Handle any unexpected errors by navigating to the NoConnectionScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NoConnectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your app logo here
            Image.asset(
              'assets/logo.png', // Replace with your actual logo asset path
              width: 150,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}