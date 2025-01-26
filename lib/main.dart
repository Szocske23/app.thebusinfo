import 'package:flutter/material.dart';
import '/home_screen.dart';
import 'no_connection_screen.dart';
import 'services/server_health_check.dart';
import 'package:timezone/data/latest.dart' as tzData;


void main() {
  // Initialize the timezone database
  tzData.initializeTimeZones();
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
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Full-screen background image
        Positioned.fill(
          child: Image.asset(
            'assets/landing_screen.jpg', // Replace with your actual background image asset path
            fit: BoxFit.cover, // Ensures the image fits the screen properly
          ),
        ),
        // Circular progress indicator positioned at the top center
        const Positioned(
          top: 200,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFE2861D),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}
