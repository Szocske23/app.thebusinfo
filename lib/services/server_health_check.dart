import 'dart:convert';
import 'package:http/http.dart' as http;

class ServerHealthCheck {
  static Future<bool> checkHealth() async {
    const String healthCheckUrl = 'https://api.thebus.info';
    try {
      final response = await http.get(Uri.parse(healthCheckUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'ok'; // Updated condition
      }
    } catch (e) {
      print('Health check error: $e');
    }
    return false;
  }
}