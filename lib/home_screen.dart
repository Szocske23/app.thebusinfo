import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:location/location.dart';
import 'routes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MapboxMap? mapboxMap;
  final Location location = Location();
  LocationData? _currentLocation;

  // Callback for when the map is created
  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    _getLocation(); // Fetch the location after the map is ready
  }

  // Fetch the current location
  Future<void> _getLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Check if location service is enabled
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        print("Location service is not enabled.");
        return;
      }
    }

    // Check location permission
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        print("Location permission not granted.");
        return;
      }
    }

    // Get the current location
    _currentLocation = await location.getLocation();
    if (_currentLocation != null && mapboxMap != null) {
      print("Updating map camera...");
      print(
          "Location: Latitude = ${_currentLocation!.latitude}, Longitude = ${_currentLocation!.longitude}");

      mapboxMap!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(
              _currentLocation!.longitude!,
              _currentLocation!.latitude!,
            ),
          ),
          zoom: 15.0,
        ),
      );
    } else {
      print("MapboxMap is null or location is null.");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getLocation();
    });
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
              zoom: 17.0,
              pitch: 40,
            ),
            styleUri: MapboxStyles.STANDARD,
            textureView: true,
            onMapCreated: _onMapCreated,
          ),
          // Custom Floating Bar
          Positioned(
            bottom: 6,
            left: 6,
            right: 6,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 65,
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
                      icon: const FaIcon(
                        FontAwesomeIcons.solidMap,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () {
                        // Action for Home button
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.busSimple,
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
                      icon: const FaIcon(
                        FontAwesomeIcons.ticket,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () {
                        // Action for Ticket button
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.solidUser,
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