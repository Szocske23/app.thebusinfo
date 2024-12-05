import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:location/location.dart';
import 'routes_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MapboxMap mapboxMap;
  final Location location = Location();
  LocationData? _currentLocation;
  PointAnnotationManager? pointAnnotationManager;
  List<Map<String, dynamic>> stops = []; // List to hold stops data

  // Callback for when the map is created
  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();

    // Initialize location tracking
    await _initializeLocationTracking();

    // Fetch stops from the API
    await _fetchStops();

    // Add image annotations for each stop
    await _addStopAnnotations();
  }

  // Fetch the stops data from the API
  Future<void> _fetchStops() async {
  try {
    final response = await http.get(Uri.parse('https://api.thebus.info/v1/stops'));

    if (response.statusCode == 200) {
      // Parse the JSON response body
      List<dynamic> responseData = json.decode(response.body);

      setState(() {
        stops = responseData.map((stop) => {
          "id": stop["id"],
          "name": stop["name"],
          "latitude": double.parse(stop["latitude"]),
          "longitude": double.parse(stop["longitude"]),
          "route_id": stop["route_id"],
        }).toList();
      });
    } else {
      print('Failed to fetch stops: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching stops: $e');
  }
}

  // Load the custom image for each stop from URL and add annotations
  Future<void> _addStopAnnotations() async {
    for (var stop in stops) {
      final response = await http.get(Uri.parse('https://s3.qube24.com/cdn/bus_stop.png'));

      if (response.statusCode == 200) {
        final Uint8List imageData = response.bodyBytes;

        // Create a PointAnnotationOptions for each stop
        PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
          geometry: Point(coordinates: Position(stop['longitude'], stop['latitude'])),
          image: imageData,
          iconSize: 0.09,
        );

        // Add the annotation for the stop to the map
        pointAnnotationManager?.create(pointAnnotationOptions);
      } else {
        print('Failed to load image for stop: ${stop['name']}');
      }
    }
  }

  // Initialize location tracking and set up a custom 3D puck
  Future<void> _initializeLocationTracking() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }
    if (!serviceEnabled) return;

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }
    if (permissionGranted != PermissionStatus.granted) return;

    // Start listening for location updates
    location.onLocationChanged.listen((LocationData currentLocation) {
      _currentLocation = currentLocation;
      _updateCamera(currentLocation);
      debugPrint("Current location: ${currentLocation.latitude}, ${currentLocation.longitude}");
    });
  }

  // Update the camera position based on current location
  Future<void> _updateCamera(LocationData locationData) async {
    final latitude = locationData.latitude;
    final longitude = locationData.longitude;

    if (latitude != null && longitude != null) {
      debugPrint("Updating camera to: $latitude, $longitude");
      mapboxMap.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(longitude, latitude)),
          zoom: 16.3,
          pitch: 30,
          padding: MbxEdgeInsets(top: 0, left: 0, bottom: 50, right: 0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map widget as background
          MapWidget(
            key: const ValueKey("mapWidget"),
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  -122.0312186, // Default longitude
                  37.33233141, // Default latitude
                ),
              ),
              zoom: 16.3,
              pitch: 30,
            ),
            styleUri: MapboxStyles.STANDARD,
            textureView: true,
            onMapCreated: _onMapCreated,
          ),
          // Custom Floating Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white, // Semi-transparent background
                  borderRadius: BorderRadius.circular(38),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.bus,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () {
                        // Action for Map button
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.bus,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () {
                        // Navigate to Routes screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RoutesScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.bus,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () {
                        // Action for Ticket button
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.bus,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () {
                        // Action for Profile button
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}