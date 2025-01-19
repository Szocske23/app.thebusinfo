import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
// Import LatLng

class StopDetailsPage extends StatefulWidget {
  final int stopId;

  const StopDetailsPage({super.key, required this.stopId});

  @override
  _StopDetailsPageState createState() => _StopDetailsPageState();
}

class _StopDetailsPageState extends State<StopDetailsPage> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  List routes = [];
  bool isLoading = true;
  late double latitude;
  late double longitude;
  String stopName = "";
  List services = [];

  // Fetch stop details from the API
  Future<void> fetchStopDetails() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.thebus.info/v1/stops/detailed?stop_id=${widget.stopId}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          latitude = double.parse(data['stop_coordinates']['latitude']);
          longitude = double.parse(data['stop_coordinates']['longitude']);
          stopName = data['stop_name'];
          routes = data['routes']; // Store the routes data
          services = data['services']; // Store the services data

          isLoading = false;
        });
        print('Stop Details: $data'); // Log response for debugging
      } else {
        throw Exception(
            'Failed to load stop details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching stop details: $e'); // Log error for debugging
      throw Exception('Failed to fetch stop details');
    }
  }

  void addStopMarker() async {
    PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
      geometry: Point(coordinates: Position(longitude, latitude)),
      iconImage: "bus-stop",
      iconSize: 0.1,
      iconAnchor: IconAnchor.BOTTOM,
    );

    // Add the annotation to the map
    pointAnnotationManager?.create(pointAnnotationOptions);
  }

  Future<void> _addRouteLines() async {
    

    try {
      // Use the already available 'routes' data instead of fetching it again
      if (routes.isNotEmpty) {
        // Extract the geojson coordinates from the first route
        final geoJson =
            routes[0]['geojson']; // Assuming you have at least one route
        final coordinates =
            geoJson[0]['coordinates']; // Extracting the coordinates array

        // Convert coordinates to LatLng format for Mapbox
        final routeCoordinates = coordinates.map((coord) {
          return [
            coord[0],
            coord[1]
          ]; // Convert [longitude, latitude] to [latitude, longitude]
        }).toList();

        // Prepare the GeoJSON for the route lines
        final routesGeoJson = {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "LineString",
                "coordinates": routeCoordinates,
              },
              "properties": {
                "name": routes[0]['name'], // Route name (or other property)
                "description": routes[0]
                    ['description'], // Route description (if needed)
              },
            },
          ],
        };

        print(routesGeoJson);

        // Add GeoJSON source for the route lines
        await mapboxMap?.style.addSource(GeoJsonSource(
          id: 'route-line-source', // Source ID
          data: json.encode(routesGeoJson),
        ));

        // Add a layer for route lines
        await mapboxMap?.style
            .addLayer(LineLayer(
          id: 'route-line-layer',
          sourceId: 'route-line-source',
          lineColor: 
              const Color(0xFFE2861D).value, // Green in light mode
          lineWidth: 8,
          lineColorExpression: [2,2],
          lineEmissiveStrength: 1,
          lineOpacity: 1,
           
        ))
            .catchError((error) {
          print("Error adding layer: $error");
        });
      } else {
        print('No routes found in the response');
      }
    } catch (e) {
      _showError('Error adding route lines: $e');
    }
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    // Add the stop marker after map creation
    if (!isLoading) {
      addStopMarker();
      _addRouteLines();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    fetchStopDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loader while loading
          : Stack(
              children: [
                MapWidget(
                  styleUri:
                      "mapbox://styles/szocske23/cm62gk5mp003401s71wfb57jg",
                  onMapCreated: (MapboxMap controller) {
                    mapboxMap = controller;
                    _onMapCreated(controller);
                  },
                  cameraOptions: CameraOptions(
                    center: Point(
                      coordinates: Position(longitude, latitude),
                    ),
                    zoom: 16,
                    pitch: 40,
                    padding:
                        MbxEdgeInsets(top: 0, left: 0, bottom: 420, right: 0),
                  ),
                ),
                // Stop name

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(45),
                        topRight: Radius.circular(45)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                      child: Container(
                        height: 550,
                        decoration: const BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(45),
                                topRight: Radius.circular(45))),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 505,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "Stația $stopName",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 30,
                  left: 10,
                  right: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 60,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(25),
                                topRight: Radius.circular(25),
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8)),
                            gradient: RadialGradient(
                              colors: [
                                Colors.black,
                                Colors.transparent,
                              ],
                              focal: Alignment.topRight,
                              radius: 30,
                              stops: [-20, 8],
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Services",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                    width: 100,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "ETA",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "info",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              "buy",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    )),
                              ],
                            ),
                          )),
                      services.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: Center(
                                child: Text(
                                  "No services available",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(25),
                                bottomRight: Radius.circular(25),
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              child: SizedBox(
                                height: 400, // Constrain the height
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      ...services.map((service) {
                                        return _buildServiceCard(
                                          service['service_name'] ??
                                              'Unknown Service',
                                          _formatTimeAtStop(
                                              service['time_at_stop']),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

String _formatTimeAtStop(String? timeAtStop) {
  if (timeAtStop == null) return "N/A";
  try {
    final dateTime = DateTime.parse(timeAtStop);
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  } catch (e) {
    return "Invalid time";
  }
}

Widget _buildServiceCard(String serviceName, String eta) {
  return Padding(
    padding: const EdgeInsets.only(top: 4.0),
    child: Row(
      children: [
        // Main service card container
        Expanded(
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const RadialGradient(
                colors: [
                  Colors.black,
                  Colors.transparent,
                ],
                focal: Alignment.topRight,
                radius: 30, // Adjust radius as needed
              ),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 20.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Handle button press
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  Text(
                    eta,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4), // Spacing between the two containers
        // Secondary container
        Container(
          width: 60,
          height: 60, // Adjust height as needed
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const RadialGradient(
              colors: [
                Colors.black,
                Colors.transparent,
              ],
              focal: Alignment.topLeft,
              radius: 30, // Adjust radius as needed
            ),
          ),
          child: const Center(
            child: FaIcon(
              FontAwesomeIcons.cartShopping,
              size: 16,
              color: Color(0xFFE2861D),
            ),
          ),
        ),
      ],
    ),
  );
}
