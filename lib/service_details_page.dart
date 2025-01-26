import 'package:flutter/material.dart';

class ServiceDetails extends StatelessWidget {
  final int serviceId;

  const ServiceDetails({Key? key, required this.serviceId ,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Name', style: TextStyle(color: Colors.white)),

        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text('Service ID: $serviceId'),
      ),
    );
  }
}