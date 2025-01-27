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
      appBar: AppBar(
        title: Text('Stația $stopName',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                    zoom: 16.6,
                    pitch: 40,
                    padding:
                        MbxEdgeInsets(top: 0, left: 0, bottom: 360, right: 0),
                  ),
                ),
                // Stop name

                Positioned(
                  bottom: 30,
                  left: 10,
                  right: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 90,
                          decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(25),
                                  topRight: Radius.circular(25),
                                  bottomLeft: Radius.circular(25),
                                  bottomRight: Radius.circular(25)),
                              color: Colors.black),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Departures",
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
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Container(
                                height: 90,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(25),
                                    topRight: Radius.circular(25),
                                    bottomLeft: Radius.circular(25),
                                    bottomRight: Radius.circular(25),
                                  ),
                                  color: Colors.black,
                                ),
                                child: const Center(
                                    child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.calendarXmark,
                                      color: Colors.white54,
                                      size: 35,
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      "There are no rides scheduled",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                )),
                              ),
                            )
                          :  SizedBox(
                                height: 300, // Constrain the height
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      ...services.map((service) {
                                        return _buildServiceCard(
                                          service['service_name'] ??
                                              'Unknown Service',
                                          _formatTimeAtStop(
                                              service['time_at_stop']),
                                          service['service_id'],
                                          selectedStopId,
                                          context,
                                        );
                                      }).toList(),
                                    ],
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
    int selectedStopId, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: 10.0),
    child: Row(
      children: [
        // Main service card container
        Expanded(
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.black,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 20.0),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            eta,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                          const Icon(
                            FontAwesomeIcons.cartShopping,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      )),
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
