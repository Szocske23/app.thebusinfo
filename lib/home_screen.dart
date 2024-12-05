import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'routes_screen.dart';

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
  List<Map<String, dynamic>> stops = [];
  Timer? debounceTimer;
  PointAnnotation? locationIndicator; // Custom location marker

  static const String stopsApiUrl = 'https://api.thebus.info/v1/stops';
  static const String stopImageUrl = 'https://s3.qube24.com/cdn/bus_stop.png';


  bool isCameraUpdated = false;
  @override
  void dispose() {
    debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    await _initializeLocationTracking();
    await _fetchStops();
    await _addStopAnnotations();
  }

  Future<void> _fetchStops() async {
    try {
      final response = await http.get(Uri.parse(stopsApiUrl));
      if (response.statusCode == 200) {
        List<dynamic> responseData = json.decode(response.body);
        setState(() {
          stops = responseData.map((stop) {
            return {
              "id": stop["id"],
              "name": stop["name"],
              "latitude": double.parse(stop["latitude"]),
              "longitude": double.parse(stop["longitude"]),
              "route_id": stop["route_id"],
            };
          }).toList();
        });
      } else {
        _showError('Failed to fetch stops: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching stops: $e');
    }
  }

  List<Map<String, dynamic>> _getClosestStops(LocationData currentLocation) {
    const double earthRadius = 6371; // Radius of the Earth in kilometers

    double calculateDistance(lat1, lon1, lat2, lon2) {
      double dLat = (lat2 - lat1) * (3.141592653589793 / 180.0);
      double dLon = (lon2 - lon1) * (3.141592653589793 / 180.0);

      double a = sin(dLat / 2) * sin(dLat / 2) +
          cos(lat1 * (3.141592653589793 / 180.0)) *
              cos(lat2 * (3.141592653589793 / 180.0)) *
              sin(dLon / 2) *
              sin(dLon / 2);
      double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      return earthRadius * c;
    }

    if (_currentLocation == null) return [];

    // Create a list of stops with the calculated distance
    List<Map<String, dynamic>> stopsWithDistance = stops
        .map((stop) => {
              ...stop,
              "distance": calculateDistance(
                currentLocation.latitude!,
                currentLocation.longitude!,
                stop['latitude'],
                stop['longitude'],
              ),
            })
        .where((stop) => stop["distance"] <= 5) // Filter stops within 5km
        .toList();

    // Sort the stops by distance
    stopsWithDistance.sort((a, b) => a["distance"].compareTo(b["distance"]));

    // Take the closest 3 stops
    return stopsWithDistance.take(3).toList();
  }

  Future<void> _addStopAnnotations() async {
    try {
      final response = await http.get(Uri.parse(stopImageUrl));
      if (response.statusCode == 200) {
        final Uint8List imageData = response.bodyBytes;
        await Future.wait(stops.map((stop) async {
          final pointAnnotationOptions = PointAnnotationOptions(
            geometry: Point(
                coordinates: Position(stop['longitude'], stop['latitude'])),
            image: imageData,
            iconSize: 0.3,
            textField: stop['name'],
            textOffset: [0.0, -2.0],
            textColor: Colors.white.value,
            textHaloBlur: 10,
            textHaloColor: Colors.black.value,
          );
          await pointAnnotationManager?.create(pointAnnotationOptions);
        }));
      } else {
        _showError('Failed to load stop image.');
      }
    } catch (e) {
      _showError('Error loading stop annotations: $e');
    }
  }

  Future<void> _initializeLocationTracking() async {
    if (!await location.serviceEnabled()) {
      if (!await location.requestService()) return;
    }

    if (await location.hasPermission() == PermissionStatus.denied) {
      if (await location.requestPermission() != PermissionStatus.granted)
        return;
    }

    location.onLocationChanged.listen((LocationData currentLocation) {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(seconds: 0), () {
        _currentLocation = currentLocation;
        _getClosestStops(currentLocation);
        if (!isCameraUpdated) {
           _updateCamera(currentLocation);
           isCameraUpdated = true; // Set the flag to true after updating the camera
    }
      });
    });
  }

  Future<void> _updateCamera(LocationData locationData) async {
    if (locationData.latitude != null && locationData.longitude != null) {
      mapboxMap.location.updateSettings(LocationComponentSettings(
          puckBearingEnabled: true,
          showAccuracyRing: true,
          puckBearing: PuckBearing.HEADING,
          locationPuck: LocationPuck(
              locationPuck3D: LocationPuck3D(
            modelCastShadows: true,
            modelScale: [20, 17, 20],
            modelReceiveShadows: true,
            modelEmissiveStrength: 4,
            modelUri:
                "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Embedded/Duck.gltf",
          ))));
      mapboxMap.flyTo(
        CameraOptions(
          center: Point(
            coordinates:
                Position(locationData.longitude!, locationData.latitude!),
          ),
          zoom: 16.3,
          pitch: 30,
        ),
        MapAnimationOptions(duration: 500),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
            styleUri: "mapbox://styles/szocske23/cm4brvrj900pb01r1eq8z9spy",
            textureView: true,
            onMapCreated: _onMapCreated,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(46),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _currentLocation == null
                    ? Center(
                        child: Text(
                          'Fetching your location...',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : Column(
                        children: [
                          Text(
                            'Closest Stops:',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 0),
                          Expanded(
                            child: ListView.builder(
                              itemCount:
                                  _getClosestStops(_currentLocation!).length,
                              itemBuilder: (context, index) {
                                final stop =
                                    _getClosestStops(_currentLocation!)[index];
                                return ListTile(
                                  title: Text(
                                    stop['name'],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    '${stop["distance"].toStringAsFixed(2)} km away',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.directions,
                                        color: Colors.white),
                                    onPressed: () {
                                      // Navigate to the stop or show directions
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
