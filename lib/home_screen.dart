import 'dart:async';
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

  @override
  void dispose() {
    debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();

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

  Future<void> _addStopAnnotations() async {
    try {
      final response = await http.get(Uri.parse(stopImageUrl));
      if (response.statusCode == 200) {
        final Uint8List imageData = response.bodyBytes;
        await Future.wait(stops.map((stop) async {
          final pointAnnotationOptions = PointAnnotationOptions(
            geometry: Point(coordinates: Position(stop['longitude'], stop['latitude'])),
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
      if (await location.requestPermission() != PermissionStatus.granted) return;
    }

    location.onLocationChanged.listen((LocationData currentLocation) {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(seconds: 1), () {
        _currentLocation = currentLocation;
        _updateCamera(currentLocation);
      });
    });
  }

  Future<void> _updateCamera(LocationData locationData) async {
    if (locationData.latitude != null && locationData.longitude != null) {
      mapboxMap.location.updateSettings(LocationComponentSettings(
    locationPuck: LocationPuck(


        locationPuck3D: LocationPuck3D(
          modelCastShadows: true,
          modelScale: [20,17,20],
          modelReceiveShadows: true,
          modelEmissiveStrength: 4,
            modelUri:
                "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Embedded/Duck.gltf",)
                )));
      mapboxMap.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(locationData.longitude!, locationData.latitude!)),
          zoom: 16.3,
          pitch: 30,
        ),
      );
    }
  }



  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                height: 320,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.map, color: Colors.white, size: 24),
                      onPressed: () {
                        // Map button action
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.route, color: Colors.white, size: 24),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RoutesScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.ticket, color: Colors.white, size: 24),
                      onPressed: () {
                        // Ticket button action
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.user, color: Colors.white, size: 24),
                      onPressed: () {
                        // Profile button action
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