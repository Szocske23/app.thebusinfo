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

  List<List<double>> decodePolyline6(String encoded) {
    List<List<double>> coordinates = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      // Decode latitude
      while (true) {
        if (index >= encoded.length) {
          print('Invalid polyline format: Latitude decoding failed');
          return [];
        }
        int b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
        if (b < 0x20) break;
      }
      int deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;

      // Decode longitude
      while (true) {
        if (index >= encoded.length) {
          print('Invalid polyline format: Longitude decoding failed');
          return [];
        }
        int b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
        if (b < 0x20) break;
      }
      int deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      // Add coordinates to the list (Flipping to [latitude, longitude])
      coordinates.add([lng / 1e6, lat / 1e6]); // Flip: Latitude first
    }

    return coordinates;
  }

  Future<void> _addRouteLines() async {
    try {
      if (routes.isNotEmpty) {
        // Extract the encoded polyline from the first route
        final encodedPolyline = routes[0]['geojson'][0];
        final routeName = routes[0]['name'];
        final routeDescription = routes[0]['description'];

        // Decode the polyline using decodePolyline6
        List<List<double>> decodedPoints = decodePolyline6(encodedPolyline);
        print(decodedPoints);
        if (decodedPoints.isNotEmpty) {
          // Convert decoded points to the format required by Mapbox
          List<List<double>> routeCoordinates = decodedPoints;

          // Prepare GeoJSON for the route lines
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
                  "name": routeName,
                  "description": routeDescription,
                },
              },
            ],
          };
          print(routesGeoJson);

          // Add GeoJSON source for the route lines
          
            // Add GeoJSON source for the route lines
            await mapboxMap?.style.addSource(GeoJsonSource(
              id: 'route-line-source',
              data: json.encode(routesGeoJson),
            ));

            // Add a layer for the route lines
            await mapboxMap?.style.addLayer(LineLayer(
              id: 'route-line-layer',
              sourceId: 'route-line-source',
              
              lineColor: const Color(0xFFE2861D).value,
              lineWidth: 8,
              lineColorExpression: [2, 2],
              lineEmissiveStrength: 1,
              lineOpacity: 1,
              
            ));

          

          print('Route line added successfully');
        } else {
          print('No coordinates decoded from polyline');
        }
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
      _addRouteLines();
      addStopMarker();
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
      appBar: AppBar(
        title: Text('Stația $stopName', style: const TextStyle(color: Colors.white)),

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
                        height: 400,
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
                                topLeft: Radius.circular(35),
                                topRight: Radius.circular(35),
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
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Container(
                                height: 292,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                    bottomLeft: Radius.circular(25),
                                    bottomRight: Radius.circular(25),
                                  ),
                                  gradient: RadialGradient(
                              colors: [
                                Colors.black,
                                Colors.transparent,
                              ],
                              focal: Alignment.topRight,
                              radius: 12,
                              stops: [-20, 8],
                            ),
                                ),
                                child:  const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                  "There are no rides scheduled",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18,fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 20),
                                Icon( FontAwesomeIcons.calendarXmark, color: Colors.white54, size: 80,),
                                  ],
                                )
                                
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
                                          context,
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
    final dateTime = DateTime.parse(timeAtStop); // Parse as UTC
    final location = tz.getLocation('Europe/Bucharest'); // Get Bucharest timezone
    final localDateTime = tz.TZDateTime.from(dateTime, location); // Convert to local time
    return "${localDateTime.hour}:${localDateTime.minute.toString().padLeft(2, '0')}";
  } catch (e) {
    return "Invalid time";
  }
}

Widget _buildServiceCard(String serviceName, String eta, int serviceId, BuildContext context) {
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
                // Handle button press for the main card (if needed)
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
        // Secondary container (make it clickable)
        GestureDetector(
          onTap: () {
            // Navigate to ServiceDetails page with the serviceId
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceDetails(serviceId: serviceId, ),
              ),
            );
          },
          child: Container(
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
        ),
      ],
    ),
  );
}