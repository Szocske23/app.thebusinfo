import 'dart:io'; // Import to check platform
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RoutePlannerPage extends StatefulWidget {
  final double? userLat;
  final double? userLon;
  final String? destinationName;
  final double? destinationLat;
  final double? destinationLon;

  RoutePlannerPage({
    this.userLat,
    this.userLon,
    this.destinationName,
    this.destinationLat,
    this.destinationLon,
  });

  @override
  _RoutePlannerPageState createState() => _RoutePlannerPageState();
}

class _RoutePlannerPageState extends State<RoutePlannerPage> {
  // Add any variables or methods related to route planning here
  late DateTime selectedDate;
  final PageController _controller =
      PageController(viewportFraction: 0.20, initialPage: 2);

  List<dynamic>? routes;
  bool isLoading = false; // Track loading state
  bool noRoutes = false; // Track if no routes are available

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _checkAndFetchRoute();
  }

  void _checkAndFetchRoute() {
    if (widget.userLat != null &&
        widget.userLon != null &&
        widget.destinationLat != null &&
        widget.destinationLon != null) {
      _fetchRoute();
    }
  }

  Future<void> _fetchRoute() async {
    setState(() {
      isLoading = true; // Show progress indicator
    });

    final String date = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Make the API request
    final Uri url = Uri.parse(
      'https://api.thebus.info/v1/find-route?start_lat=${widget.userLat}&start_lon=${widget.userLon}&end_lat=${widget.destinationLat}&end_lon=${widget.destinationLon}&date=$date',
    );

    try {
      final response = await http.get(url);

      setState(() {
        isLoading = false; // Hide progress indicator once done
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          routes = data['routes']; // Store routes data
          noRoutes = false; // Reset noRoutes flag
          print(routes);
        });
      } else if (response.statusCode == 404) {
        // Handle 404 response (No service for that day)
        setState(() {
          routes = []; // No routes available
          noRoutes = true;
        });
        print("No service available for the selected date.");
      } else {
        // Handle other error codes
        throw Exception("Failed to load routes: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Hide progress indicator on error
      });
      print("Error fetching routes: $e");
    }
  }

  Duration calculateDuration(String departureTime, String arrivalTime) {
    DateTime departure = DateFormat("HH:mm:ss").parse(departureTime);
    DateTime arrival = DateFormat("HH:mm:ss").parse(arrivalTime);
    return arrival.difference(departure);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A131F),
      body: Stack(
        children: [
          //   Positioned.fill(
          //   child: Image.asset(
          //     'assets/bg_gradient.png', // Replace with your image path
          //     fit: BoxFit.cover, // Ensures the image covers the screen
          //   ),
          // ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                color: Colors.white,
              ),
            ),
          if (noRoutes)
            const Center(
              child: Text(
                "Nu avem rute disponibile pentru această dată.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          if (routes != null && isLoading == false)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.transparent,
                height: 580,
                child: ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: routes!.length,
                  itemBuilder: (context, index) {
                    final route = routes![index];

                    return route['transfers'] == 0
                        ? GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Color(0xFF0A131F),
                                showDragHandle: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(45)),
                                ),
                                builder: (context) =>
                                    _buildRouteDetailsSheet(context, route),
                              );
                            },
                            child: Container(
                              height: 80,
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromARGB(14, 197, 197, 255),
                                    spreadRadius: 2,
                                    blurRadius: 20,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        route['departure_time'],
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        DateFormat("dd MMM")
                                            .format(
                                                DateTime.parse(route['date']))
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                      child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            route["route"],
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(
                                        color: Colors.blue,
                                        thickness: 2,
                                      ),
                                      Text(
                                        (() {
                                          final arrivalTime =
                                              DateFormat("HH:mm")
                                                  .parse(route['arrival_time']);
                                          final departureTime =
                                              DateFormat("HH:mm").parse(
                                                  route['departure_time']);
                                          final duration = arrivalTime
                                              .difference(departureTime);

                                          return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
                                        })(),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )),
                                  const SizedBox(width: 14),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        route['arrival_time'],
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        DateFormat("dd MMM")
                                            .format(
                                                DateTime.parse(route['date']))
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 15),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        route['price'],
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Text(
                                        'RON',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: const Color(0xFF0A131F),
                                showDragHandle: true,
                                isScrollControlled: false,
                                scrollControlDisabledMaxHeightRatio: 0.8,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(45)),
                                ),
                                builder: (context) =>
                                    _buildRouteDetailsSheet(context, route),
                              );
                            },
                            child: Container(
                              height: 140,
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromARGB(14, 197, 197, 255),
                                    spreadRadius: 2,
                                    blurRadius: 20,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 80,
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 10),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              route['first_leg']
                                                  ['departure_time'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              DateFormat("dd MMM")
                                                  .format(DateTime.parse(
                                                      route['first_leg']
                                                          ['date']))
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  route['first_leg']['route'],
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(
                                              color: Colors.blue,
                                              thickness: 2,
                                            ),
                                            Text(
                                              (() {
                                                final arrivalTime =
                                                    DateFormat("HH:mm").parse(
                                                        route['first_leg']
                                                            ['arrival_time']);
                                                final departureTime =
                                                    DateFormat("HH:mm").parse(
                                                        route['first_leg']
                                                            ['departure_time']);
                                                final duration = arrivalTime
                                                    .difference(departureTime);

                                                return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
                                              })(),
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        )),
                                        const SizedBox(width: 10),
                                        if (route['walk_distance'] == 0)
                                          SizedBox(
                                              width: 50,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.all(3),
                                                        child: Icon(
                                                            FontAwesomeIcons
                                                                .stopwatch,
                                                            color:
                                                                Colors.white70,
                                                            size: 14),
                                                      )
                                                    ],
                                                  ),
                                                  const Divider(
                                                    color: Colors.grey,
                                                    thickness: 2,
                                                  ),
                                                  Text(
                                                    (() {
                                                      final arrivalTime = DateFormat(
                                                              "HH:mm")
                                                          .parse(route[
                                                                  'second_leg'][
                                                              'departure_time']);
                                                      final departureTime =
                                                          DateFormat("HH:mm")
                                                              .parse(route[
                                                                      'first_leg']
                                                                  [
                                                                  'arrival_time']);
                                                      final duration =
                                                          arrivalTime.difference(
                                                              departureTime);

                                                      return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
                                                    })(),
                                                    style: const TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              )),
                                        if (route['walk_distance'] > 0)
                                          SizedBox(
                                              width: 50,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                          FontAwesomeIcons
                                                              .personWalkingLuggage,
                                                          color: Colors.white70,
                                                          size: 20),
                                                    ],
                                                  ),
                                                  const Divider(
                                                    color: Colors.grey,
                                                    thickness: 2,
                                                  ),
                                                  Text(
                                                    (() {
                                                      final arrivalTime = DateFormat(
                                                              "HH:mm")
                                                          .parse(route[
                                                                  'second_leg'][
                                                              'departure_time']);
                                                      final departureTime =
                                                          DateFormat("HH:mm")
                                                              .parse(route[
                                                                      'first_leg']
                                                                  [
                                                                  'arrival_time']);
                                                      final duration =
                                                          arrivalTime.difference(
                                                              departureTime);

                                                      return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
                                                    })(),
                                                    style: const TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              )),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  route['second_leg']['route'],
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(
                                              color: Colors.blue,
                                              thickness: 2,
                                            ),
                                            Text(
                                              (() {
                                                final arrivalTime =
                                                    DateFormat("HH:mm").parse(
                                                        route['second_leg']
                                                            ['arrival_time']);
                                                final departureTime =
                                                    DateFormat("HH:mm").parse(
                                                        route['second_leg']
                                                            ['departure_time']);
                                                final duration = arrivalTime
                                                    .difference(departureTime);

                                                return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
                                              })(),
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        )),
                                        const SizedBox(width: 10),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              route['second_leg']
                                                  ['arrival_time'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              DateFormat("dd MMM")
                                                  .format(DateTime.parse(
                                                      route['second_leg']
                                                          ['date']))
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 20),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'Pret',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              '${(double.parse(route['first_leg']['price']) + double.parse(route['second_leg']['price']))}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    color: Colors.white24,
                                    thickness: 1,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          child: Column(
                                        children: [
                                          if (route['transfer_type'] ==
                                              'same_stop')
                                            const Text(
                                              'Schimbare la aceeași stație',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 14,
                                              ),
                                            ),
                                          if (route['transfer_type'] ==
                                              'same_stop')
                                            Text(
                                              route['transfer_stop'],
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 14,
                                              ),
                                            ),
                                          if (route['transfer_type'] == 'walk')
                                            Text(
                                              'Mers pe jos ${(route['walk_distance'] * 1000).toInt()}m',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 14,
                                              ),
                                            ),
                                          if (route['transfer_type'] == 'walk')
                                            Text(
                                              'intre statile ${route['first_leg']['end_stop']['name']} si ${route['second_leg']['start_stop']['name']}',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 14,
                                              ),
                                            ),
                                        ],
                                      ))
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ); // or any other widget for routes with transfers
                  },
                ),
              ),
            ),

          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 90,
              child: PageView.builder(
                itemCount: 10, // Next 10 days
                controller: _controller,
                itemBuilder: (context, index) {
                  DateTime date = DateTime.now().add(Duration(days: index));

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDate = date;
                        routes = []; // No routes available
                      });
                      _fetchRoute();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(
                            color: selectedDate.year == date.year &&
                                    selectedDate.month == date.month &&
                                    selectedDate.day == date.day
                                ? Colors.white
                                : Colors
                                    .transparent, // White border for selected date
                            width: 2, // Border width
                          ),
                        ),
                        color: Colors.black,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('dd').format(date),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                DateFormat('MMM').format(date),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
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
                      borderRadius: BorderRadius.all(Radius.circular(25)),
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
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    height: 60,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                      color: Colors.black,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            // Ensures proper text overflow handling
                            child: Text(
                              widget.destinationName ?? "Destinatie",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                overflow:
                                    TextOverflow.fade, // Enables fade effect
                              ),
                              softWrap: false, // Prevents text from wrapping
                              overflow: TextOverflow.fade,
                            ),
                          ),
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

Widget _buildRouteDetailsSheet(
    BuildContext context, Map<String, dynamic> route) {
  return Padding(
      padding: const EdgeInsets.only(right: 0),
      child: route['transfers'] == 0
          ? Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 80,
                      child: Icon(
                        FontAwesomeIcons.locationCrosshairs,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ),
                    Expanded(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "${route['start_stop']['name']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )),
                    SizedBox(
                      width: 80,
                      child: Text(
                        "${route['departure_time']}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: VerticalDivider(
                          color: Colors.blue, // Line color
                          thickness: 2, // Line thickness
                        ),
                      ),
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "${route['route']}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(FontAwesomeIcons.caretRight,
                                  color: Colors.white),
                              Text(
                                "${route['service_name']}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              "${route['price']}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 80,
                            child: Text(
                              "Ron",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 80,
                      child: Icon(
                        FontAwesomeIcons.locationDot,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ),
                    Expanded(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "${route['end_stop']['name']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )),
                    SizedBox(
                      width: 80,
                      child: Text(
                        "${route['arrival_time']}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                    color: Colors.white24,
                    thickness: 2,
                  ),
                ),
                 const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Aligns text to top
                    children: [
                       SizedBox(width: 14),
                      Icon(FontAwesomeIcons.circleInfo,
                          color: Colors.white54, size: 18),
                      SizedBox(width: 14), // Adds spacing between icon and text
                      Expanded(
                        // Ensures text wraps properly
                        child: Text(
                          'Rezarvarile se fac cu minim 24 ore inainte si isi pierd valabilitatea cu 15 minute inainte de plecare. Reducerile sunt valabile doar pentru biletele cumparate online. Conducatorul auto si transportatorul nu raspund de bagaje si continutul lor.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
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
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                          color: Colors.black,
                        ),
                        child: const Center(
                          child: Icon(
                            FontAwesomeIcons.xmark,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        height: 60,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                          color: Colors.black,
                        ),
                        child:  Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                // Ensures proper text overflow handling
                                child: Text(
                                  'Cumpara la ${route['price']} Ron',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow
                                        .fade, // Enables fade effect
                                  ),
                                  softWrap:
                                      false, // Prevents text from wrapping
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 80,
                      child: Icon(
                        FontAwesomeIcons.locationCrosshairs,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ),
                    Expanded(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "${route['first_leg']['start_stop']['name']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )),
                    SizedBox(
                      width: 80,
                      child: Text(
                        "${route['first_leg']['departure_time']}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: VerticalDivider(
                          color: Colors.blue, // Line color
                          thickness: 2, // Line thickness
                        ),
                      ),
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "${route['first_leg']['route']}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(FontAwesomeIcons.caretRight,
                                  color: Colors.white),
                              Text(
                                "${route['first_leg']['service_name']}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              "${route['first_leg']['price']}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 80,
                            child: Text(
                              "Ron",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 80,
                        child: route['transfer_type'] == 'walk'
                            ? const Icon(
                                FontAwesomeIcons.signHanging,
                                color: Colors.blue,
                                size: 16,
                              )
                            : const Icon(
                                FontAwesomeIcons.stopwatch,
                                color: Colors.white70,
                                size: 20,
                              )),
                    Expanded(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${route['first_leg']['end_stop']['name']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (route['transfer_type'] == 'same_stop')
                          Text(
                            (() {
                              final arrivalTime = DateFormat("HH:mm")
                                  .parse(route['second_leg']['departure_time']);
                              final departureTime = DateFormat("HH:mm")
                                  .parse(route['first_leg']['arrival_time']);
                              final duration =
                                  arrivalTime.difference(departureTime);

                              return "Transfer time: ${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
                            })(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    )),
                    route['transfer_type'] == 'walk'
                        ? SizedBox(
                            width: 80,
                            child: Text(
                              "${route['first_leg']['arrival_time']}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  "${route['first_leg']['arrival_time']}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${route['second_leg']['departure_time']}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )),
                            ],
                          )
                  ],
                ),
                if (route['transfer_type'] == 'walk')
                  const SizedBox(height: 10),
                if (route['transfer_type'] == 'walk')
                  Expanded(
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 80,
                          child: VerticalDivider(
                            color: Colors.white60, // Line color
                            thickness: 2, // Line thickness
                          ),
                        ),
                        Expanded(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Icon(
                                    FontAwesomeIcons.personWalkingLuggage,
                                    color: Colors.white),
                                const SizedBox(width: 10),
                                Text(
                                  "${(route['walk_distance'] * 1000).toInt()}m",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )),
                        SizedBox(
                          width: 80,
                          child: Text(
                            (() {
                              final arrivalTime = DateFormat("HH:mm")
                                  .parse(route['second_leg']['departure_time']);
                              final departureTime = DateFormat("HH:mm")
                                  .parse(route['first_leg']['arrival_time']);
                              final duration =
                                  arrivalTime.difference(departureTime);

                              return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
                            })(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                if (route['transfer_type'] == 'walk')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Icon(
                          FontAwesomeIcons.signHanging,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                      Expanded(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "${route['second_leg']['start_stop']['name']}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )),
                      SizedBox(
                        width: 80,
                        child: Text(
                          "${route['second_leg']['departure_time']}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: VerticalDivider(
                          color: Colors.blue, // Line color
                          thickness: 2, // Line thickness
                        ),
                      ),
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "${route['second_leg']['route']}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(FontAwesomeIcons.caretRight,
                                  color: Colors.white),
                              Text(
                                "${route['second_leg']['service_name']}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow
                                    .fade, // adds ellipsis if the text overflows
                              ),
                            ],
                          ),
                        ],
                      )),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              "${route['second_leg']['price']}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 80,
                            child: Text(
                              "Ron",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 80,
                      child: Icon(
                        FontAwesomeIcons.locationDot,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ),
                    Expanded(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "${route['second_leg']['end_stop']['name']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )),
                    SizedBox(
                      width: 80,
                      child: Text(
                        "${route['second_leg']['arrival_time']}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                    color: Colors.white24,
                    thickness: 2,
                  ),
                ),
                 const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Aligns text to top
                    children: [
                       SizedBox(width: 14),
                      Icon(FontAwesomeIcons.circleInfo,
                          color: Colors.white54, size: 18),
                      SizedBox(width: 14), // Adds spacing between icon and text
                      Expanded(
                        // Ensures text wraps properly
                        child: Text(
                          'Rezarvarile se fac cu minim 24 ore inainte si isi pierd valabilitatea cu 15 minute inainte de plecare. Reducerile sunt valabile doar pentru biletele cumparate online. Conducatorul auto si transportatorul nu raspund de bagaje si continutul lor.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
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
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                          color: Colors.black,
                        ),
                        child: const Center(
                          child: Icon(
                            FontAwesomeIcons.xmark,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        height: 60,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                          color: Colors.black,
                        ),
                        child:  Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                // Ensures proper text overflow handling
                                child: Text(
                                  'Cumpara la ${(double.parse(route['first_leg']['price']) + double.parse(route['second_leg']['price']))} Ron',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow
                                        .fade, // Enables fade effect
                                  ),
                                  softWrap:
                                      false, // Prevents text from wrapping
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
              ],
            ));
}
