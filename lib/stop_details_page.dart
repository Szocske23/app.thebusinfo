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
                                      service['service_color'] ?? '0000FF',
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

Color getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) {
        return Color(int.parse("0xFF$hexColor"));
      }
      return Colors.blue;
    } catch (e) {
      return Colors.blue;
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
    int selectedStopId, String serviceRoute,String colorId, BuildContext context) {
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
                // Instead of navigating, show bottom sheet with service details
                _showServiceDetailsBottomSheet(
                    context, serviceId, selectedStopId);
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
                              color: getColorFromHex(colorId),
                            ),
                            child: Text(
                              serviceRoute,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            FontAwesomeIcons.caretRight,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
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

// Add this new function to show a bottom sheet with service details
void _showServiceDetailsBottomSheet(
    BuildContext context, int serviceId, int selectedStopId) {
  showModalBottomSheet(
    context: context,
    enableDrag: true,
    scrollControlDisabledMaxHeightRatio: 0.85,
    backgroundColor: const Color(0xFF0A131F),
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(45)),
    ),
    builder: (context) {
      return ServiceDetailsBottomSheet(serviceId: serviceId);
    },
  );
}

// Create a StatefulWidget for the bottom sheet content
class ServiceDetailsBottomSheet extends StatefulWidget {
  final int serviceId;

  const ServiceDetailsBottomSheet({Key? key, required this.serviceId})
      : super(key: key);

  @override
  State<ServiceDetailsBottomSheet> createState() =>
      _ServiceDetailsBottomSheetState();
}

class _ServiceDetailsBottomSheetState extends State<ServiceDetailsBottomSheet> {
  bool isLoading = true;
  String serviceName = '';
  String serviceDescription = '';
  String routeId = '';
  String routeName = '';
  String idColor = '';
  String startTime = '';
  Map<String, dynamic> busInfo = {};
  Map<String, dynamic> driverInfo = {};
  List<dynamic> stops = [];
  dynamic polyLine;

  @override
  void initState() {
    super.initState();
    fetchServiceDetails();
  }

  Future<void> fetchServiceDetails() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.thebus.info/v1/services/detailed?service_id=${widget.serviceId}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          serviceName = data['service']['name'] ?? '';
          serviceDescription = data['service']['description'] ?? '';
          routeId = data['service']['route_id']?.toString() ?? '';
          routeName = data['service']['route_name'] ?? '';
          idColor = data['service']['id_color'] ?? '0000FF';
          startTime = data['service']['start_time'] ?? '';
          busInfo = data['service']['bus'] ?? {};
          driverInfo = data['service']['driver'] ?? {};
          stops = data['stops'] ?? [];
          polyLine = data['service']['geojson'];
          isLoading = false;
        });
        print('Service Details: $data'); // Log response for debugging
      } else {
        throw Exception(
            'Failed to load service details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching service details: $e'); // Log error for debugging
    }
  }

  // Format datetime string to a more readable format
  String formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  // Get color from hex string
  Color getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) {
        return Color(int.parse("0xFF$hexColor"));
      }
      return Colors.blue;
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.only(left: 20, right: 20),
            children: [
              // Service header
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: getColorFromHex(idColor),
                    ),
                    child: Text(
                      routeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    FontAwesomeIcons.caretRight,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      serviceName,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                    ),
                  ),
                  Row(
                children: [
                  const Icon(FontAwesomeIcons.planeDeparture,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    'Dep: ${formatDateTime(startTime)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white
                    ),
                  ),
                ],
                  ),
                ],
              ),
              // Bus info
              if (busInfo.isNotEmpty) ...[
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(FontAwesomeIcons.busSimple, size: 14, color: Colors.blue),
                    const SizedBox(width: 10),
                    Text(
                      '${busInfo['brand']} - ${busInfo['plate']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70
                      ),
                    ),
                    const Spacer(),
                    const Icon(FontAwesomeIcons.person,size: 14, color: Colors.white70),
                    const SizedBox(width: 5,),
                    Text(
                      '${busInfo['seat_count']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 10,),
                    const Icon(FontAwesomeIcons.wheelchair,size: 14, color: Colors.white70),
                    const SizedBox(width: 5,),
                    const Text(
                      '2',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              

             const SizedBox(height: 25),

             // Stops list with connecting line
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: stops.length,
              itemBuilder: (context, index) {
                final isFirstItem = index == 0;
                final isLastItem = index == stops.length - 1;
                
                return IntrinsicHeight(
                  
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline line and dot
                      SizedBox(
                        width: 30,
                        child: Column(
                          children: [
                            
                            // Top connector line (hide for first item)
                            if (!isFirstItem)
                              Container(
                                width: 2,
                                height: 0,
                                color: getColorFromHex(idColor),
                              ),
                              
                            // Dot

                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: getColorFromHex(idColor),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white38,
                                  width: 2,
                                ),
                              ),
                            ),
                            
                            // Bottom connector line (hide for last item)
                            if (!isLastItem)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  height: 25,
                                  color: getColorFromHex(idColor),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Stop information
                      Expanded(
                        child: _buildStopItem(stops[index]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
}


  Widget _buildStopItem(dynamic stop) {
    final stopName = stop['stop_name'] ?? 'Unknown Stop';
    final stopCity = stop['stops_city'] ?? '';
    final timeAtStop = formatDateTime(stop['time_at_stop'] ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, top: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  stopName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white
                  ),
                ),
                if (stopCity.isNotEmpty)
                  Text(
                    stopCity,
                    style: const TextStyle(
                      fontSize: 12,

                      fontWeight: FontWeight.w400,
                      color: Colors.white60,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeAtStop,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
            ],
          ),
        ],
      ),
    );
  }
}
