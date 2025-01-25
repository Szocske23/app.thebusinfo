import 'package:flutter/material.dart';

class ServiceDetails extends StatelessWidget {
  final int serviceId;

  const ServiceDetails({Key? key, required this.serviceId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Details'),
      ),
      body: Center(
        child: Text('Service ID: $serviceId'),
      ),
    );
  }
}