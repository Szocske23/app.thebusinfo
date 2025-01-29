import 'dart:convert';
import 'dart:ui';
import 'package:app_thebusinfo/service_details_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

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
  int selectedStopId = 0;
  String stopName = "";
  List services = [];

  Map<String, List<Map<String, dynamic>>> _groupServicesByRoute(
      List<dynamic> services) {
    final groupedServices = <String, List<Map<String, dynamic>>>{};

    for (final service in services.cast<Map<String, dynamic>>()) {
      final routeName = service['route_name'] ?? 'Unknown Route';
      if (!groupedServices.containsKey(routeName)) {
        groupedServices[routeName] = [];
      }
      groupedServices[routeName]!.add(service);
    }

    return groupedServices;
  }

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
          selectedStopId = data['stop_id'];
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

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    // Add the stop marker after map creation
    if (!isLoading) {
      addStopMarker();
    }
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
                      "mapbox://styles/szocske23/cm4brvrj900pb01r1eq8z9spy",
                  onMapCreated: (MapboxMap controller) {
                    mapboxMap = controller;
                    _onMapCreated(controller);
                  },
                  cameraOptions: CameraOptions(
                    center: Point(
                      coordinates: Position(longitude, latitude),
                    ),
                    zoom: 17,
                    pitch: 28,
                    padding:
                        MbxEdgeInsets(top: 0, left: 0, bottom: 360, right: 0),
                  ),
                ),
                // Stop name

                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group services by 'route_name'
                      ..._groupServicesByRoute(services).entries.map((entry) {
                        final routeServices =
                            entry.value; // Services for this route

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Horizontal scrollable services for this route
                            SizedBox(
                              height: 90,
                              child: PageView.builder(
                                itemCount: routeServices.length,
                                controller:
                                    PageController(viewportFraction: 0.9),
                                itemBuilder: (context, index) {
                                  final service = routeServices[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: _buildServiceCard(
                                      service['service_name'] ??
                                          'Unknown Service',
                                      _formatTimeAtStop(
                                          service['time_at_stop']),
                                      service['service_id'],
                                      selectedStopId,
                                      service['route_name'],
                                      context,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(
                                height: 10), // Add spacing between rows
                          ],
                        );
                      }).toList(),

                      // Departures container at the bottom
                      // Add spacing between sections
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Navigate back to the previous screen
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 10),
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25)),
                                color: Colors.black,
                              ),
                              child: const Center(
                                child: Icon(
                                  FontAwesomeIcons.chevronLeft,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              height: 60,
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25)),
                                color: Colors.black,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Stația $stopName",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
    final dateTime = DateTime.parse(timeAtStop); // Parse as UTC
    final location =
        tz.getLocation('Europe/Bucharest'); // Get Bucharest timezone
    final localDateTime =
        tz.TZDateTime.from(dateTime, location); // Convert to local time
    return "${localDateTime.hour}:${localDateTime.minute.toString().padLeft(2, '0')}";
  } catch (e) {
    return "Invalid time";
  }
}

Widget _buildServiceCard(String serviceName, String eta, int serviceId,
    int selectedStopId, String serviceRoute, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0),
    child: Row(
      children: [
        // Main service card container
        Expanded(
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.black,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () {
                // Handle button press for the main card (if needed)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetails(
                        serviceId: serviceId, stopId: selectedStopId),
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.blue,
                            ),
                            child: Text(
                              serviceRoute,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            FontAwesomeIcons.play,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            serviceName,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      Text(
                        eta,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.circleInfo,
                        size: 16,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Felszállás az elsö ajtónál',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Secondary container (make it clickable)
      ],
    ),
  );
}


