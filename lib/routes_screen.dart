import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({Key? key}) : super(key: key);

  @override
  _RoutesScreenState createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  late Future<List<Route>> _routes;

  @override
  void initState() {
    super.initState();
    _routes = fetchRoutes();
  }

  Future<List<Route>> fetchRoutes() async {
    final response = await http.get(Uri.parse('https://api.thebus.info/v1/routes'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((route) => Route.fromJson(route)).toList();
    } else {
      throw Exception('Failed to load routes');
    }
  }

  Future<List<Service>> fetchServices(int routeId) async {
    final response = await http.get(Uri.parse('https://api.thebus.info/v1/services?route_id=$routeId'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((service) => Service.fromJson(service)).toList();
    } else {
      throw Exception('Failed to load services');
    }
  }

  // Add the fetchStops method to fetch stops for a specific route
  Future<List<Stop>> fetchStops(int routeId) async {
    final response = await http.get(Uri.parse('https://api.thebus.info/v1/stops?route_id=$routeId'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((stop) => Stop.fromJson(stop)).toList();
    } else {
      throw Exception('Failed to load stops');
    }
  }

  void _showStopsModal(int routeId) async {
    List<Stop> stops = await fetchStops(routeId);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(10.0),
          height: 400, // Adjust height as needed
          child: ListView.builder(
            itemCount: stops.length,
            itemBuilder: (context, index) {
              String imageType = "middle";
              if (index == 0) {
                imageType = "first";
              } else if (index == stops.length - 1) {
                imageType = "last";
              }

              return ListTile(
                leading: Image.asset('assets/${imageType}_stop_image.png', width: 50, height: 50),
                title: Text(stops[index].name),
                subtitle: Text('Distance: ${stops[index].distance} km'),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Routes'),
      ),
      body: FutureBuilder<List<Route>>(
        future: _routes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No routes available'));
          }

          final routes = snapshot.data!;

          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(routes[index].name),
                      subtitle: Text('Base Fee: ${routes[index].baseFee} | Distance Fee: ${routes[index].distanceFee}'),
                      onTap: () {
                        _showStopsModal(routes[index].id); // Show stops modal on tap
                      },
                    ),

                    // Fetch and display services within the same card
                    FutureBuilder<List<Service>>(
                      future: fetchServices(routes[index].id),
                      builder: (context, serviceSnapshot) {
                        if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: CircularProgressIndicator(),
                          );
                        } else if (serviceSnapshot.hasError) {
                          return Center(child: Text('Error: ${serviceSnapshot.error}'));
                        } else if (!serviceSnapshot.hasData || serviceSnapshot.data!.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: const Text('No services available for this route'),
                          );
                        }

                        final services = serviceSnapshot.data!;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              // Display services within the same card
                              ...services.map((service) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(service.name),
                                    subtitle: Text(service.description),
                                    onTap: () {
                                      _showServiceDetailsModal(service.id); // Show service details modal
                                    },
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showServiceDetailsModal(int serviceId) {
    // Show service details when a service is tapped (you can implement this)
  }
}

class Route {
  final int id;
  final String name;
  final String baseFee;
  final String distanceFee;
  final String description;

  Route({
    required this.id,
    required this.name,
    required this.baseFee,
    required this.distanceFee,
    required this.description,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'],
      name: json['name'],
      baseFee: json['base_fee'],
      distanceFee: json['distance_fee'],
      description: json['description'],
    );
  }
}

class Stop {
  final String name;
  final String distance;

  Stop({
    required this.name,
    required this.distance,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      name: json['name'] ?? 'Unnamed Stop', // Default value if 'name' is null
      distance: json['distance_from_start']?.toString() ?? '0', // Default to '0' if 'distance' is null
    );
  }
}

class Service {
  final int id;
  final String name;
  final String description;
  final String startTime;
  final int busId;
  final int routeId;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.startTime,
    required this.busId,
    required this.routeId,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      startTime: json['start_time'],
      busId: json['bus_id'],
      routeId: json['route_id'],
    );
  }
}