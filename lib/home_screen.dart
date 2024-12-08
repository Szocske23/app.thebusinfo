import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MapboxMap mapboxMap;
  final Location location = Location();
  // ignore: unused_field
  LocationData? _currentLocation;
  PointAnnotationManager? pointAnnotationManager;
  List<Map<String, dynamic>> stops = [];
  List<Map<String, dynamic>> closestStops = [];
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

  Future<void> _getClosestStopsFromAPI(LocationData currentLocation) async {
    if (currentLocation.latitude == null || currentLocation.longitude == null) {
      _showError('Invalid location data.');
      return;
    }

    // Correctly append query parameters to the URL
    final url = Uri.parse(
        'https://api.thebus.info/v1/stops/closest_stops?latitude=${currentLocation.latitude}&longitude=${currentLocation.longitude}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> responseData = json.decode(response.body);
        setState(() {
          closestStops = responseData.map((stop) {
            return {
              "id": stop["id"],
              "name": stop["name"],
              "latitude": double.parse(stop["latitude"]),
              "longitude": double.parse(stop["longitude"]),
              "distance": stop["distance"], // Distance provided by the API
              "services": stop["services"] ?? []
            };
          }).toList();
        });
      } else {
        _showError('Failed to fetch closest stops: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching closest stops: $e');
    }
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
      if (await location.requestPermission() != PermissionStatus.granted) {
        return;
      }
    }

    location.onLocationChanged.listen((LocationData currentLocation) {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(seconds: 0), () async {
        _currentLocation = currentLocation;
        await _getClosestStopsFromAPI(currentLocation);
        if (!isCameraUpdated) {
          _updateCamera(currentLocation);
          isCameraUpdated =
              true; // Set the flag to true after updating the camera
        }
      });
    });
  }

  Future<void> _updateCamera(LocationData locationData) async {
    if (locationData.latitude != null && locationData.longitude != null) {
      mapboxMap.location.updateSettings(LocationComponentSettings(
          puckBearingEnabled: true,
          showAccuracyRing: true,
          accuracyRingBorderColor: Colors.yellow.value,
          accuracyRingColor: const Color.fromARGB(100, 255, 235, 59).value,
          puckBearing: PuckBearing.HEADING,
          locationPuck: LocationPuck(
              locationPuck3D: LocationPuck3D(
            modelCastShadows: true,
            modelScale: [18, 18, 18],
            modelRotation: [0, 0, -108],
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
            zoom: 16,
            pitch: 34,
            padding: MbxEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)),
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
                zoom: 16,
                pitch: 34,
                padding: MbxEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)),
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
                height: 340,
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
                child: stops == null
                    ? const Center(
                        child: Text(
                          'Fetching your location...',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 30, right: 18, bottom: 0, top: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Stops Near',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(221, 255, 255, 255),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 21, 21, 21),
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(26),
                                        bottomRight: Radius.circular(10),
                                        bottomLeft: Radius.circular(10)),
                                  ),
                                  child: const Text(
                                    'All routes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Column(
                            children: closestStops.asMap().entries.map((entry) {
                              final index = entry.key; // Get index
                              final stop = entry.value; // Get stop
                              final isLast = index ==
                                  closestStops.length -
                                      1; // Check if it's the last card
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 2,
                                  left: 15,
                                  right: 15,
                                ),
                                child: _buildStopCard(stop, isLast),
                              );
                            }).toList(),
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

Widget _buildStopCard(Map<String, dynamic> stop, bool isLast) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: isLast
          ? BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10),bottomLeft: Radius.circular(26),bottomRight: Radius.circular(26)) // Larger radius for last card
          : BorderRadius.circular(10), // Default smaller radius for others
    ),
    elevation: 4,
    color: Color.fromARGB(255, 21, 21, 21),
    child: Padding(
      padding: const EdgeInsets.only(left: 6, right: 6, bottom: 6, top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 4),
                child: Text(
                  '${stop["name"]}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(221, 255, 255, 255),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(right: 2, bottom: 2),
                child: Text(
                  '${(stop["distance"] ?? 0.0).toStringAsFixed(2)} km',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (stop["services"] != null && stop["services"].isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFE2861D),
                    borderRadius: isLast
          ? BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                        bottomLeft: Radius.circular(20)) // Larger radius for last card
          : const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                        bottomLeft: Radius.circular(6)) // Default smaller radius for others
    
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.busSimple,
                    size: 10,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: stop["services"].take(3).map<Widget>((service) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.5,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                              bottomLeft: Radius.circular(4)),
                        ),
                        child: Text(
                          service,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            )
          else
            Row(
              children: const [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey,
                ),
                SizedBox(width: 8),
                Text(
                  'No services available',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}
